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
        static let keychainService = "PairingManager"
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
    
    @Keychain(name: "pairing", service: Constants.keychainService, clearOnReinstall: true)
    private var pairing: Pairing = .empty
    // swiftlint:disable:previous let_var_whitespace
    
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
        
        let haPublicKeyInformation = Services.networkManager.configuration.haPublicKey
        
        guard let haPublicKeyData = Data(base64Encoded: haPublicKeyInformation.encodedPublicKey) else {
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
        guard isPaired else { throw PairingManagingError.notPaired }
        
        logDebug("Sealing \(value)")
        let encodedValue = try jsonEncoder.encode(value)
        logDebug("Resulting JSON: \(String(data: encodedValue, encoding: .utf8) ?? "")")
        guard let (cipherText, nonce) = sodium.secretBox.seal(message: Bytes(encodedValue), secretKey: pairing.tx) else {
            logError("Could not seal \(value)")
            throw PairingManagingError.encryptionError
        }
        
        let encodedCipherText = Data(cipherText).base64EncodedString()
        let encodedNonce = Data(nonce).base64EncodedString()
        logDebug("Sealed! cipherText: \(encodedCipherText), nonce: \(encodedNonce)")
        
        return (encodedCipherText, encodedNonce)
    }
    
    func open<T: Decodable>(cipherText: String, nonce: String) throws -> T {
        guard isPaired else { throw PairingManagingError.notPaired }
        
        logDebug("Opening cipherText: \(cipherText), nonce: \(nonce)")
        
        guard let decodedCipherText = Data(base64Encoded: cipherText),
              let decodedNonce = Data(base64Encoded: nonce) else {
            throw PairingManagingError.encryptionError
        }
        
        guard let decodedBytes = sodium.secretBox.open(authenticatedCipherText: Bytes(decodedCipherText),
                                                       secretKey: pairing.rx,
                                                       nonce: Bytes(decodedNonce)) else {
            logError("Could not open value for \(T.self)")
            throw PairingManagingError.encryptionError
        }
        
        logDebug("Resulting JSON: \(String(data: Data(decodedBytes), encoding: .utf8) ?? "")")
        
        do {
            let value = try jsonDecoder.decode(T.self, from: Data(decodedBytes))
            logDebug("Opened value: \(value)")
            
            return value
        } catch let error {
            self.logError("Error Deserializing \(T.self): \(error)")
            throw error
        }
    }
    
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
        encoder.target = .api
        return encoder
    }()
    
    private lazy var jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        decoder.source = .api
        return decoder
    }()
}
