/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import Sodium

enum PairingManagingError: Error {
    case alreadyPaired
    case notPaired
    case encryptionError
    case couldNotPair(NetworkError)
}

/// - Tag: PairingManaging
protocol PairingManaging {
    init()
    
    var isPaired: Bool { get }
    
    /// Returns the token used to construct the URL for sending and fetching case data
    /// Throws an `notPaired` error when called befored paired.
    func caseToken() throws -> String
    
    func pair(pairingCode: String, completion: @escaping (_ success: Bool, _ error: PairingManagingError?) -> Void)
    
    /// Clears all stored data. Using any method or property except for `isPaired` on PairingManager before pairing again is an invalid operation.
    func unpair()
    
    func seal<T: Encodable>(_ value: T) throws -> (ciperText: String, nonce: String)
    func open<T: Decodable>(cipherText: String, nonce: String) throws -> T
}

class PairingManager: PairingManaging, Logging {
    let loggingCategory = "PairingManager"
    
    private struct Constants {
        static let encodedHAPublicKey = "I8uOsrNAccb4/4xJUHOKKWZ4ZDW5JygzEMZMB5xwHAM="
    }
    
    private let sodium = Sodium()
    
    struct Pairing: Codable {
        var publicKey: Bytes
        var secretKey: Bytes
        var rx: Bytes
        var tx: Bytes
        
        static var empty: Pairing {
            return Pairing(publicKey: Bytes(),
                           secretKey: Bytes(),
                           rx: Bytes(),
                           tx: Bytes())
        }
    }
    
    @Keychain(name: "pairing", service: "PairingManager", clearOnReinstall: true)
    private var pairing: Pairing = .empty
    
    required init() {}
    
    var isPaired: Bool {
        return $pairing.exists
    }
    
    func caseToken() throws -> String {
        guard $pairing.exists else { throw PairingManagingError.notPaired }
        
        let concatenated = pairing.rx + pairing.tx
        
        $pairing.clearCache()
        
        let hash = sodium.genericHash.hash(message: concatenated)!
        
        return hash.map { String(format: "%02x", $0) }.joined()
    }
    
    func pair(pairingCode: String, completion: @escaping (_ success: Bool, _ error: PairingManagingError?) -> Void) {
        guard !$pairing.exists else { return completion(false, .alreadyPaired) }
        
        guard let haPublicKeyData = Data(base64Encoded: Constants.encodedHAPublicKey) else {
            fatalError("Invalid stored health authority public key")
        }
        
        let haPublicKey = Bytes(haPublicKeyData)
        
        guard let clientKeyPair = sodium.keyExchange.keyPair() else {
            logError("Could not generate client key pair")
            return completion(false, PairingManagingError.encryptionError)
        }
        
        guard let sealedClientPublicKey = sodium.box.seal(message: clientKeyPair.publicKey, recipientPublicKey: haPublicKey) else {
            logError("Could not seal client public key for health authority")
            return completion(false, PairingManagingError.encryptionError)
        }
        
        Services.networkManager.pair(code: pairingCode, sealedClientPublicKey: Data(sealedClientPublicKey)) {
            switch $0 {
            case .success(let pairingResponse):
                let sealedCaseHAPublicKey = Bytes(pairingResponse.sealedHealthAuthorityPublicKey)
                
                guard let caseHAPublicKey = self.sodium.box.open(anonymousCipherText: sealedCaseHAPublicKey,
                                                                 recipientPublicKey: clientKeyPair.publicKey,
                                                                 recipientSecretKey: clientKeyPair.secretKey) else {
                    self.logError("Could not open sealed health authority public key for case")
                    return completion(false, .couldNotPair(.invalidResponse))
                }
            
                guard let sessionKeyPair = self.sodium.keyExchange.sessionKeyPair(publicKey: clientKeyPair.publicKey, secretKey: clientKeyPair.secretKey, otherPublicKey: caseHAPublicKey, side: .CLIENT) else {
                    self.logError("Could not create session key pair")
                    return completion(false, .couldNotPair(.invalidResponse))
                }
                
                self.pairing = Pairing(publicKey: clientKeyPair.publicKey,
                                       secretKey: clientKeyPair.secretKey,
                                       rx: sessionKeyPair.rx,
                                       tx: sessionKeyPair.tx)
                self.$pairing.clearCache()
                
                completion(true, nil)
            case .failure(let error):
                completion(false, .couldNotPair(error))
            }
        }
    }
    
    func unpair() {
        $pairing.clearData()
    }
    
    func seal<T: Encodable>(_ value: T) throws -> (ciperText: String, nonce: String) {
        // TODO
        throw PairingManagingError.notPaired
    }
    
    func open<T: Decodable>(cipherText: String, nonce: String) throws -> T {
        // TODO
        throw PairingManagingError.notPaired
    }
}
