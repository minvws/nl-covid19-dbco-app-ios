/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

class LocalMockNetworkManager: NetworkManager {
    override var loggingCategory: String { "MockNetwork" }

    override func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        guard let method = request.httpMethod?.lowercased(), let url = request.url else {
            completionHandler(nil, nil, nil)
            return
        }
        
        guard let localUrl = Bundle.main.url(forResource: "Mocks" + url.path,
                                             withExtension: method.lowercased() + ".json") else {
            let response = HTTPURLResponse(url: url,
                                           statusCode: 404,
                                           httpVersion: nil,
                                           headerFields: nil)
            
            completionHandler(nil, response, NetworkError.resourceNotFound)
            return
        }
    
        let time: DispatchTime = .now() + .random(in: 0.1...0.5)
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: time) {
            do {
                let data = try Data(contentsOf: localUrl)
                let response = HTTPURLResponse(url: url,
                                               statusCode: 200,
                                               httpVersion: nil,
                                               headerFields: nil)

                completionHandler(data, response, nil)
            } catch {
                let response = HTTPURLResponse(url: url,
                                               statusCode: 500,
                                               httpVersion: nil,
                                               headerFields: nil)

                completionHandler(nil, response, NetworkError.invalidResponse)
            }
        }
    }
}
