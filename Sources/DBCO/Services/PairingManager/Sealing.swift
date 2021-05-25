/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import Sodium

class Sealing: Logging {
    private let sodium: Sodium
    
    init(sodium: Sodium) {
        self.sodium = sodium
    }
    
    func seal<T: Encodable>(_ value: T, transmitKey: Bytes) throws -> (ciperText: String, nonce: String) {
        logDebug("Sealing \(value)")
        let encodedValue = try jsonEncoder.encode(value)
        logDebug("Resulting JSON: \(String(data: encodedValue, encoding: .utf8) ?? "")")
        guard let (cipherText, nonce) = sodium.secretBox.seal(message: Bytes(encodedValue), secretKey: transmitKey) else {
            logError("Could not seal \(value)")
            throw PairingManagingError.encryptionError
        }
        
        let encodedCipherText = Data(cipherText).base64EncodedString()
        let encodedNonce = Data(nonce).base64EncodedString()
        logDebug("Sealed! cipherText: \(encodedCipherText), nonce: \(encodedNonce)")
        
        return (encodedCipherText, encodedNonce)
    }

    func open<T: Decodable>(cipherText: String, nonce: String, receiveKey: Bytes) throws -> T {
        logDebug("Opening cipherText: \(cipherText), nonce: \(nonce)")
        
        guard let decodedCipherText = Data(base64Encoded: cipherText),
              let decodedNonce = Data(base64Encoded: nonce) else {
            throw PairingManagingError.encryptionError
        }
        
        guard let decodedBytes = sodium.secretBox.open(authenticatedCipherText: Bytes(decodedCipherText),
                                                       secretKey: receiveKey,
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
