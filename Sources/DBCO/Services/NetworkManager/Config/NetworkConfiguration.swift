/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

struct NetworkConfiguration {
    struct HAPublicKeyInformation {
        let encodedPublicKey: String
        let keyVersion: String
    }
    
    struct EndpointConfiguration {
        let scheme: String
        let host: String
        let port: Int?
        let path: [String]
        let sslSignature: Certificate.Signature? // SSL pinning certificate, nil = no pinning
        let tokenParams: [String: String]
    }

    let name: String
    let api: EndpointConfiguration
    let haPublicKey: HAPublicKeyInformation
    
    func sslSignature(forHost host: String) -> Certificate.Signature? {
        if api.host == host { return api.sslSignature }

        return nil
    }

    static let development = NetworkConfiguration(
        name: "Development",
        api: .init(
            scheme: "https",
            host: "public.testing.dbco.egeniq.com",
            port: nil,
            path: ["v1"],
            sslSignature: nil,
            tokenParams: [:]
        ),
        haPublicKey: .init(
            encodedPublicKey: "uuPJSp5VXqQElwGsywf9ESEm26Ie1BOlnxlr8V+7/Fg=",
            keyVersion: "20201210")
    )

    static let test = NetworkConfiguration(
        name: "Test",
        api: .init(
            scheme: "https",
            host: "api-test.bco-portaal.nl",
            port: nil,
            path: ["v1"],
            sslSignature: nil,
            tokenParams: [:]
        ),
        haPublicKey: .init(
            encodedPublicKey: "bWLH9tCUERcZbnCo5J0ibf5pa5mN6Il4gPqeTIQcG18=",
            keyVersion: "20210107")
    )

    static let acceptance = NetworkConfiguration(
        name: "ACC",
        api: .init(
            scheme: "https",
            host: "api-acc.bco-portaal.nl",
            port: nil,
            path: ["v1"],
            sslSignature: Certificate.SSL.apiSignature,
            tokenParams: [:]
        ),
        haPublicKey: .init(
            encodedPublicKey: "X850Q6EDZT7N5IQEXVHphSerjDjHxuwEtDH0KnNrHRg=",
            keyVersion: "20201230")
    )

    static let production = NetworkConfiguration(
        name: "Production",
        api: .init(
            scheme: "https",
            host: "api.bco-portaal.nl",
            port: nil,
            path: ["v1"],
            sslSignature: Certificate.SSL.apiSignature,
            tokenParams: [:]
        ),
        haPublicKey: .init(
            encodedPublicKey: "+Ey3G55XEefYbU5eCOzZl9oG1SVshUzh3DMYSS12Rkg=",
            keyVersion: "20201217")
    )
    
    var appConfigurationUrl: URL? {
        return self.combine(path: Endpoint.appConfiguration)
    }
    
    var pairingsUrl: URL? {
        return self.combine(path: Endpoint.pairings)
    }
    
    func caseUrl(identifier: String) -> URL? {
        return self.combine(path: Endpoint.case(identifier: identifier))
    }
    
    var questionnairesUrl: URL? {
        return self.combine(path: Endpoint.questionnaires)
    }
    
    func pairingRequestsUrl(token: String?) -> URL? {
        return self.combine(path: Endpoint.pairingRequests(token: token))
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
