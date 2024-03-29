/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import Security

final class NetworkManagerURLSessionDelegate: NSObject, URLSessionDelegate, Logging {
    let loggingCategory = "NetworkManagerURLSessionDelegate"
    
    /// Initialise session delegate with certificate used for SSL pinning
    init(configuration: NetworkConfiguration) {
        self.configuration = configuration
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

        guard let localSignatures = configuration.sslSignatures(forHost: challenge.protectionSpace.host),
            challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
            let serverTrust = challenge.protectionSpace.serverTrust else {
            // no pinning
            completionHandler(.performDefaultHandling, nil)
            return
        }

        let policies = [SecPolicyCreateSSL(true, challenge.protectionSpace.host as CFString)]
        SecTrustSetPolicies(serverTrust, policies as CFTypeRef)

        let certificateCount = SecTrustGetCertificateCount(serverTrust)

        guard
            SecTrustEvaluateWithError(serverTrust, nil),
            certificateCount > 0,
            let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, certificateCount - 1), // get topmost certificate in chain
            let signature = Certificate(certificate: serverCertificate).signature else {
    
            logError("Invalid server trust")
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        guard localSignatures.contains(signature) else {
            logError("Certificate signatures don't match")
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // all good
        completionHandler(.useCredential, URLCredential(trust: serverTrust))
    }

    // MARK: - Private

    private let configuration: NetworkConfiguration
}
