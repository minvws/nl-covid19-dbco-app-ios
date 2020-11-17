/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

enum NetworkResponseHandleError: Error {
    case cannotUnzip
    case invalidSignature
    case cannotDeserialize
}

enum NetworkError: Error {
    case invalidRequest
    case serverNotReachable
    case invalidResponse
    case responseCached
    case serverError
    case resourceNotFound
    case encodingError
    case redirection
}

extension NetworkResponseHandleError {
    var asNetworkError: NetworkError {
        switch self {
        case .cannotDeserialize:
            return .invalidResponse
        case .cannotUnzip:
            return .invalidResponse
        case .invalidSignature:
            return .invalidResponse
        }
    }
}

enum HTTPHeaderKey: String {
    case contentType = "Content-Type"
    case acceptedContentType = "Accept"
}

enum HTTPContentType: String {
    case all = "*/*"
    case json = "application/json"
}

/// - Tag: NetworkManaging
protocol NetworkManaging {
    init(configuration: NetworkConfiguration)
    
    func getAppConfiguration(completion: @escaping (Result<AppConfiguration, NetworkError>) -> ())
    func pair(code: String, sealedClientPublicKey: Data, completion: @escaping (Result<PairResponse, NetworkError>) -> ())
    func getCase(identifier: String, completion: @escaping (Result<Case, NetworkError>) -> ())
    func putCase(identifier: String, value: Case, completion: @escaping (Result<Void, NetworkError>) -> ())
    func getQuestionnaires(completion: @escaping (Result<[Questionnaire], NetworkError>) -> ())
}
