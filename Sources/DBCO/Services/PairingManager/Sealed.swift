/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

/// Used for encrypting and decrypting data after pairing
///
/// # See
/// [PairingManaging](x-source-tag://PairingManaging)
///
/// - Tag: Sealed
struct Sealed<T: Codable>: Codable {
    let value: T
    
    enum CodingKeys: String, CodingKey {
        case ciphertext
        case nonce
    }
    
    init(_ value: T) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let cipherText = try container.decode(String.self, forKey: .ciphertext)
        let nonce = try container.decode(String.self, forKey: .nonce)
        
        value = try Services.pairingManager.open(cipherText: cipherText, nonce: nonce)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        let sealed = try Services.pairingManager.seal(value)
        
        try container.encode(sealed.ciperText, forKey: .ciphertext)
        try container.encode(sealed.nonce, forKey: .nonce)
    }
}
