/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

enum PairingManagingError: Error {
    case alreadyPaired
    case notPaired
    case encryptionError
    case couldNotPair(NetworkError)
    case pairingCodeExpired
    case pairingCancelled
}

protocol PairingManagerListener: AnyObject {
    func pairingManagerDidStartPollingForPairing(_ pairingManager: PairingManaging)
    func pairingManager(_ pairingManager: PairingManaging, didFailWith error: PairingManagingError)
    func pairingManagerDidCancelPollingForPairing(_ pairingManager: PairingManaging)
    func pairingManager(_ pairingManager: PairingManaging, didReceiveReversePairingCode code: String)
    func pairingManagerDidFinishPairing(_ pairingManager: PairingManaging)
}

/// Handles pairing (exchanging keys via libSodium) with the api.
///
/// # See also
/// [Sealed](x-source-tag://Sealed): Used for encrypting and decrypting data after pairing
///
/// - Tag: PairingManaging
protocol PairingManaging {
    init()
    
    var isPaired: Bool { get }
    var isPollingForPairing: Bool { get }
    
    /// Returns the token used to construct the URL for sending and fetching case data
    /// Throws an `notPaired` error when called befored paired.
    func caseToken() throws -> String
    
    func pair(pairingCode: String, completion: @escaping (_ success: Bool, _ error: PairingManagingError?) -> Void)
    
    /// Clears all stored data. Using any method or property except for `isPaired` on PairingManager before pairing again is an invalid operation.
    func unpair()
    
    func startPollingForPairing()
    func stopPollingForPairing()
    
    var canResumePolling: Bool { get }
    var lastPairingCode: String? { get }
    var lastPollingError: PairingManagingError? { get }
    
    /// Adds a listener
    /// - parameter listener: The object conforming to [PairingManagerListener](x-source-tag://PairingManagerListener) that will receive updates. Will be stored with a weak reference
    func addListener(_ listener: PairingManagerListener)
    
    func seal<T: Encodable>(_ value: T) throws -> (ciperText: String, nonce: String)
    func open<T: Decodable>(cipherText: String, nonce: String) throws -> T
}
