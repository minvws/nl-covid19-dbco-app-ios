/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

struct NetworkConfiguration {
    struct EndpointConfiguration {
        let scheme: String
        let host: String
        let port: Int?
        let path: [String]
        let tokenParams: [String: String]
    }

    let name: String
    let api: EndpointConfiguration

    static let development = NetworkConfiguration(
        name: "Development",
        api: .init(
            scheme: "https",
            host: "public.testing.dbco.egeniq.com",
            port: nil,
            path: ["v1"],
            tokenParams: [:]
        )
    )

    static let test = NetworkConfiguration(
        name: "Test",
        api: .init(
            scheme: "https",
            host: "public.testing.dbco.egeniq.com",
            port: nil,
            path: ["v1"],
            tokenParams: [:]
        )
    )

    static let acceptance = NetworkConfiguration(
        name: "ACC",
        api: .init(
            scheme: "https",
            host: "public.testing.dbco.egeniq.com",
            port: nil,
            path: ["v1"],
            tokenParams: [:]
        )
    )

    static let production = NetworkConfiguration(
        name: "Production",
        api: .init(
            scheme: "https",
            host: "public.testing.dbco.egeniq.com",
            port: nil,
            path: ["v1"],
            tokenParams: [:]
        )
    )
    
    var appConfigurationUrl: URL? {
        return self.combine(path: Endpoint.appConfiguration)
    }
    
    func caseUrl(identifier: String) -> URL? {
        return self.combine(path: Endpoint.case(identifier: identifier))
    }
    
    var questionnairesUrl: URL? {
        return self.combine(path: Endpoint.questionnaires)
    }

    private func combine(path: Path, params: [String: String] = [:]) -> URL? {
        let endpointConfig = api
        var urlComponents = URLComponents()
        urlComponents.scheme = endpointConfig.scheme
        urlComponents.host = endpointConfig.host
        urlComponents.port = endpointConfig.port
        urlComponents.path = "/" + (endpointConfig.path + path.components).joined(separator: "/")

        if !params.isEmpty {
            urlComponents.percentEncodedQueryItems = params.compactMap { parameter in
                guard let name = parameter.key.addingPercentEncoding(withAllowedCharacters: urlQueryEncodedCharacterSet),
                    let value = parameter.value.addingPercentEncoding(withAllowedCharacters: urlQueryEncodedCharacterSet) else {
                    return nil
                }

                return URLQueryItem(name: name, value: value)
            }
        }

        return urlComponents.url
    }

    private var urlQueryEncodedCharacterSet: CharacterSet = {
        // WARNING: Do not remove this code, this will break signature validation on the backend.
        // specify characters which are allowed to be unespaced in the queryString, note the `inverted`
        let characterSet = CharacterSet(charactersIn: "!*'();:@&=+$,/?%#[] ").inverted
        return characterSet
    }()
}

