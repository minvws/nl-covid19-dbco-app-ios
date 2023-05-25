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
        let sslSignatures: [Certificate.Signature]? // Valid SSL pinning certificates, nil = no pinning
        let tokenParams: [String: String]
    }

    let name: String
    let api: EndpointConfiguration
    let haPublicKey: HAPublicKeyInformation
    
    func sslSignatures(forHost host: String) -> [Certificate.Signature]? {
        if api.host == host { return api.sslSignatures }

        return nil
    }

    static let test = NetworkConfiguration(
        name: "Test",
        api: .init(
            scheme: "https",
            host: "api-test.bco-portaal.nl",
            port: nil,
            path: ["v3"],
            sslSignatures: nil,
            tokenParams: [:]
        ),
        haPublicKey: .init(
            encodedPublicKey: "bWLH9tCUERcZbnCo5J0ibf5pa5mN6Il4gPqeTIQcG18=",
            keyVersion: "20210107")
    )

    static let acceptance = NetworkConfiguration(
        name: "Acceptance",
        api: .init(
            scheme: "https",
            host: "api-acc.bco-portaal.nl",
            port: nil,
            path: ["v3"],
            sslSignatures: ["TSSRQUz+lWdG7Ezvps9vcuKKEylDL52KkHrEy12twVo=", "j+T7Cvk6TQ1n2wvrsj43xxvzJdy83SQOoE2vWLR+GEA="],
            tokenParams: [:]
        ),
        haPublicKey: .init(
            encodedPublicKey: "X850Q6EDZT7N5IQEXVHphSerjDjHxuwEtDH0KnNrHRg=",
            keyVersion: "20201230")
    )
    
    static let staging = NetworkConfiguration(
        name: "Staging",
        api: .init(
            scheme: "https",
            host: "api-staging.bco-portaal.nl",
            port: nil,
            path: ["v3"],
            sslSignatures: ["TSSRQUz+lWdG7Ezvps9vcuKKEylDL52KkHrEy12twVo=", "j+T7Cvk6TQ1n2wvrsj43xxvzJdy83SQOoE2vWLR+GEA="],
            tokenParams: [:]
        ),
        haPublicKey: .init(
            encodedPublicKey: "6a1z2yfXhdfNvuMNBl4vkAhfA2dbw8SGX0Sdg5jFok4=",
            keyVersion: "20210707")
    )

    static let production = NetworkConfiguration(
        name: "Production",
        api: .init(
            scheme: "https",
            host: "api.bco-portaal.nl",
            port: nil,
            path: ["v3"],
            sslSignatures: ["TSSRQUz+lWdG7Ezvps9vcuKKEylDL52KkHrEy12twVo=", "j+T7Cvk6TQ1n2wvrsj43xxvzJdy83SQOoE2vWLR+GEA="],
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
                guard let name = parameter.key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                    let value = parameter.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                    return nil
                }

                return URLQueryItem(name: name, value: value)
            }
        }

        return urlComponents.url
    }
}
