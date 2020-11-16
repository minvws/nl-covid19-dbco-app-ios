/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

class NetworkManager: NetworkManaging, Logging {
    private(set) var loggingCategory: String = "Network"
    
    required init(configuration: NetworkConfiguration) {
        self.configuration = configuration
        self.sessionDelegate = NetworkManagerURLSessionDelegate(configuration: configuration)
        self.session = URLSession(configuration: .ephemeral,
                                  delegate: sessionDelegate,
                                  delegateQueue: nil)
    }
    
    func getAppConfiguration(completion: @escaping (Result<AppConfiguration, NetworkError>) -> ()) {
        let urlRequest = constructRequest(url: configuration.appConfigurationUrl,
                                          method: .GET)

        decodedJSONData(request: urlRequest, completion: completion)
    }
    
    func pair(code: String, sealedClientPublicKey: Data, completion: @escaping (Result<PairResponse, NetworkError>) -> ()) {
        struct PairBody: Encodable {
            let pairingCode: String
            let sealedClientPublicKey: Data
        }
        
        let urlRequest = constructRequest(url: configuration.pairingsUrl,
                                          method: .POST,
                                          body: PairBody(pairingCode: code,
                                                         sealedClientPublicKey: sealedClientPublicKey))
        
        decodedJSONData(request: urlRequest, completion: completion)
    }
    
    func getCase(identifier: String, completion: @escaping (Result<Case, NetworkError>) -> ()) {
        let urlRequest = constructRequest(url: configuration.caseUrl(identifier: identifier),
                                          method: .GET)
        
        struct CaseResponse: Decodable {
            let sealedCase: Sealed<Case>
        }
        
        func open(result: Result<CaseResponse, NetworkError>) {
            completion(result.map { $0.sealedCase.value })
        }

        decodedJSONData(request: urlRequest, completion: open)
    }
    
    func getQuestionnaires(completion: @escaping (Result<[Questionnaire], NetworkError>) -> ()) {
        let urlRequest = constructRequest(url: configuration.questionnairesUrl,
                                          method: .GET)
        
        func open(result: Result<ArrayEnvelope<Questionnaire>, NetworkError>) {
            completion(result.map { $0.items })
        }
        
        decodedJSONData(request: urlRequest, completion: open)
    }
    
    // MARK: - Construct Request

    private func constructRequest(url: URL?,
                                  method: HTTPMethod = .GET,
                                  body: Encodable? = nil,
                                  headers: [HTTPHeaderKey: String] = [:]) -> Result<URLRequest, NetworkError> {
        guard let url = url else {
            return .failure(.invalidRequest)
        }

        var request = URLRequest(url: url,
                                 cachePolicy: .useProtocolCachePolicy,
                                 timeoutInterval: 10)
        request.httpMethod = method.rawValue

        let defaultHeaders = [
            HTTPHeaderKey.contentType: HTTPContentType.json.rawValue
        ]

        defaultHeaders.forEach { header, value in
            request.addValue(value, forHTTPHeaderField: header.rawValue)
        }

        headers.forEach { header, value in
            request.addValue(value, forHTTPHeaderField: header.rawValue)
        }

        if let body = body.flatMap({ try? self.jsonEncoder.encode(AnyEncodable($0)) }) {
            request.httpBody = body
        }

        logDebug("--REQUEST--")
        if let url = request.url { print(url.debugDescription) }
        if let allHTTPHeaderFields = request.allHTTPHeaderFields {print(allHTTPHeaderFields.debugDescription) }
        if let httpBody = request.httpBody { print(String(data: httpBody, encoding: .utf8)!) }
        logDebug("--END REQUEST--")

        return .success(request)
    }

    // MARK: - Download Data
    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        session
            .dataTask(with: request, completionHandler: completionHandler)
            .resume()
    }
    
    private func data(request: Result<URLRequest, NetworkError>, completion: @escaping (Result<(URLResponse, Data), NetworkError>) -> ()) {
        switch request {
        case let .success(request):
            data(request: request, completion: completion)
        case let .failure(error):
            completion(.failure(error))
        }
    }

    private func data(request: URLRequest, completion: @escaping (Result<(URLResponse, Data), NetworkError>) -> ()) {
        dataTask(with: request) { data, response, error in
            self.handleNetworkResponse(data,
                                       response: response,
                                       error: error,
                                       completion: completion)
        }
    }
    
    private func decodedJSONData<Object: Decodable>(request: Result<URLRequest, NetworkError>, completion: @escaping (Result<Object, NetworkError>) -> ()) {
        data(request: request) { result in
            let decodedResult: Result<Object, NetworkError> = self.jsonResponseHandler(result: result)
            
            DispatchQueue.main.async {
                completion(decodedResult)
            }
        }
    }

    // MARK: - Utilities

    /// Checks for failures and inspects status code
    private func handleNetworkResponse<Object>(_ object: Object?,
                                               response: URLResponse?,
                                               error: Error?,
                                               completion: @escaping (Result<(URLResponse, Object), NetworkError>) -> ()) {
        if error != nil {
            completion(.failure(.invalidResponse))
            return
        }

        logDebug("--RESPONSE--")
        if let response = response as? HTTPURLResponse {
            logDebug("Finished response to URL \(response.url?.absoluteString ?? "") with status \(response.statusCode)")

            let headers = response.allHeaderFields.map { header, value in
                return String("\(header): \(value)")
            }.joined(separator: "\n")

            logDebug("Response headers: \n\(headers)")
        } else if let error = error {
            logDebug("Error with response: \(error)")
        }

        logDebug("--END RESPONSE--")

        guard let response = response,
            let object = object else {
            completion(.failure(.invalidResponse))
            return
        }

        if let error = self.inspect(response: response) {
            completion(.failure(error))
            return
        }

        completion(.success((response, object)))
    }

    /// Utility function to decode JSON
    private func decodeJson<Object: Decodable>(data: Data) -> Result<Object, NetworkResponseHandleError> {
        do {
            let object = try self.jsonDecoder.decode(Object.self, from: data)
            self.logDebug("Response Object: \(object)")
            return .success(object)
        } catch {
            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                self.logDebug("Raw JSON: \(json)")
            }
            self.logError("Error Deserializing \(Object.self): \(error)")
            return .failure(.cannotDeserialize)
        }
    }

    /// Response handler which decodes JSON
    private func jsonResponseHandler<Object: Decodable>(result: Result<(URLResponse, Data), NetworkError>) -> Result<Object, NetworkError> {
        switch result {
        case let .success(result):
            return decodeJson(data: result.1)
                .mapError { $0.asNetworkError }
        case let .failure(error):
            return .failure(error)
        }
    }

    /// Checks for valid HTTPResponse and status codes
    private func inspect(response: URLResponse) -> NetworkError? {
        guard let response = response as? HTTPURLResponse else {
            return .invalidResponse
        }

        switch response.statusCode {
        case 200 ... 299:
            return nil
        case 304:
            return .responseCached
        case 300 ... 399:
            return .redirection
        case 400 ... 499:
            return .resourceNotFound
        case 500 ... 599:
            return .serverError
        default:
            return .invalidResponse
        }
    }
    
    // MARK: - Private

    private let configuration: NetworkConfiguration
    private let session: URLSession
    private let sessionDelegate: URLSessionDelegate? // hold on to delegate to prevent deallocation
    
    private lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = .current
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        return dateFormatter
    }()
    
    private lazy var jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(dateFormatter)
        return encoder
    }()
    
    private lazy var jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        return decoder
    }()
}

