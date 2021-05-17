/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import Sodium

/// # See
/// [PairingManaging](x-source-tag://PairingManaging)
/// - Tag: PairingManager
class PairingManager: PairingManaging, Logging {
    let loggingCategory = "PairingManager"
    
    private struct Constants {
        static let keychainService = "PairingManager"
    }
    
    private struct ListenerWrapper {
        weak var listener: PairingManagerListener?
    }
    
    private var listeners = [ListenerWrapper]()
    
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
    
    required init() {
        _ = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?.resumePollingIfNeeded()
        }
        
        if let info = self.reversePairingInfo {
            resumePolling(with: info)
        }
    }
    
    var isPaired: Bool {
        return $pairing.exists
    }
    
    var isPollingForPairing: Bool {
        return isBusyReversePairing
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
                let (succes, error) = self.handlePairResponse(pairingResponse, clientKeyPair: clientKeyPair)
                completion(succes, error)
            case .failure(let error):
                completion(false, .couldNotPair(error))
            }
        }
    }
    
    private func handlePairResponse(_ response: PairResponse, clientKeyPair: KeyExchange.KeyPair) -> (Bool, PairingManagingError?) {
        let sealedCaseHAPublicKey = Bytes(response.sealedHealthAuthorityPublicKey)
        
        guard let caseHAPublicKey = sodium.box.open(anonymousCipherText: sealedCaseHAPublicKey,
                                                    recipientPublicKey: clientKeyPair.publicKey,
                                                    recipientSecretKey: clientKeyPair.secretKey) else {
            logError("Could not open sealed health authority public key for case")
            return (false, .couldNotPair(.invalidResponse))
        }
    
        guard let sessionKeyPair = sodium.keyExchange.sessionKeyPair(publicKey: clientKeyPair.publicKey, secretKey: clientKeyPair.secretKey, otherPublicKey: caseHAPublicKey, side: .CLIENT) else {
            logError("Could not create session key pair")
            return (false, .couldNotPair(.invalidResponse))
        }
        
        pairing = Pairing(publicKey: clientKeyPair.publicKey,
                          secretKey: clientKeyPair.secretKey,
                          rx: sessionKeyPair.rx,
                          tx: sessionKeyPair.tx)
        $pairing.clearCache()
        
        return (true, nil)
    }
    
    func unpair() {
        $pairing.clearData()
    }
    
    func startPollingForPairing() {
        guard !$pairing.exists else {
            return logError("Polling requested when already paired")
        }

        guard !isBusyReversePairing else {
            reversePairingInfo.map { info in
                listeners.forEach { $0.listener?.pairingManager(self, didReceiveReversePairingCode: info.code) }
            }
            
            return
        }
        
        listeners.forEach { $0.listener?.pairingManagerDidStartPollingForPairing(self) }
        startPollingRequest()
    }
    
    func stopPollingForPairing() {
        isBusyReversePairing = false
        reversePairingInfo = nil
        
        pollingTask?.cancel()
        pollingTimer?.invalidate()
        pollingResumeBlock = nil
        
        listeners.forEach { $0.listener?.pairingManagerDidCancelPollingForPairing(self) }
        
        endBackgroundTaskIfNeeded()
    }
    
    func addListener(_ listener: PairingManagerListener) {
        listeners.append(ListenerWrapper(listener: listener))
        
        reversePairingInfo.map {
            listener.pairingManager(self, didReceiveReversePairingCode: $0.code)
        }
        
        lastPollingError.map {
            listener.pairingManager(self, didFailWith: $0)
        }
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
    
    // MARK: - Polling
    private var isBusyReversePairing: Bool = false
    
    @UserDefaults(key: "reversePairingInfo", defaultValue: nil)
    private var reversePairingInfo: ReversePairingInfo? // swiftlint:disable:this let_var_whitespace
    
    private(set) var lastPollingError: PairingManagingError?
    
    var lastPairingCode: String? {
        return reversePairingInfo?.code
    }
    
    var canResumePolling: Bool {
        return (reversePairingInfo?.expiresAt.timeIntervalSinceNow ?? 0) > 0
    }
    
    private var backgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid
    private var pollingTask: URLSessionTask?
    private var pollingTimer: Timer?
    private var pollingResumeBlock: (() -> Void)?
    
    private func startBackgroundTask() {
        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "pairing") {
            self.logDebug("Polling background task did expire")
            self.suspendPollingForPairing()
        }
    }
    
    private func endBackgroundTaskIfNeeded() {
        if backgroundTaskIdentifier != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
            backgroundTaskIdentifier = .invalid
        }
    }
    
    private func suspendPollingForPairing() {
        pollingTask?.cancel()
        pollingTimer?.invalidate()
        
        endBackgroundTaskIfNeeded()
        
        if let info = reversePairingInfo {
            pollingResumeBlock = { self.resumePolling(with: info) }
        }
    }
    
    private func resumePollingIfNeeded() {
        pollingResumeBlock?()
    }
    
    private func processPolling(_ info: ReversePairingStatusInfo, token: String, errorCount: Int) {
        guard case .pending = info.status else { return finishPolling(with: info.pairingCode) }
        
        poll(with: info, token: token, errorCount: errorCount)
    }
    
    private func poll(with info: ReversePairingStatusInfo, token: String, errorCount: Int) {
        let delay = Double(info.refreshDelay)
        
        guard info.expiresAt.timeIntervalSinceNow > delay else {
            logDebug("Polling token has expired")
            return failPolling(with: .pairingCodeExpired)
        }
        
        pollingTimer?.invalidate()
        logDebug("Scheduling pairing status request")
        
        if UIApplication.shared.backgroundTimeRemaining != .greatestFiniteMagnitude {
            logDebug("Background time remaining: \(UIApplication.shared.backgroundTimeRemaining)")
        }
        
        pollingTimer = Timer(fire: Date(timeIntervalSinceNow: delay), interval: 0, repeats: false) { _ in
            self.pollingTask = Services.networkManager.getPairingRequestStatus(token: token) { result in
                switch result {
                case .success(let reversePairingInfo):
                    self.processPolling(reversePairingInfo, token: token, errorCount: 0)
                case .failure(let error):
                    if errorCount > 3 {
                        self.logDebug("Received too many errors while polling")
                        self.failPolling(with: .couldNotPair(error))
                    } else {
                        self.processPolling(info, token: token, errorCount: errorCount + 1)
                    }
                }
            }
        }
        RunLoop.current.add(pollingTimer!, forMode: .common)
    }
    
    private func startPollingRequest() {
        startBackgroundTask()
        isBusyReversePairing = true
        lastPollingError = nil
        
        logDebug("Getting code and polling token")
        if let pairingInfo = reversePairingInfo, pairingInfo.expiresAt.timeIntervalSinceNow > 0 {
            logDebug("Still has valid pairing token. Resuming polling.")
            
            listeners.forEach { $0.listener?.pairingManager(self, didReceiveReversePairingCode: pairingInfo.code) }
            processPolling(pairingInfo.statusInfo,
                        token: pairingInfo.token,
                        errorCount: 0)
        } else {
            logDebug("Making new polling token request")
            Services.networkManager.postPairingRequest { result in
                switch result {
                case .success(let reversePairingInfo):
                    self.reversePairingInfo = reversePairingInfo
                    self.listeners.forEach { $0.listener?.pairingManager(self, didReceiveReversePairingCode: reversePairingInfo.code) }
                    self.processPolling(reversePairingInfo.statusInfo,
                                token: reversePairingInfo.token,
                                errorCount: 0)
                case .failure(let error):
                    self.failPolling(with: .couldNotPair(error))
                }
            }
        }
    }
    
    private func resumePolling(with info: ReversePairingInfo) {
        startBackgroundTask()
        isBusyReversePairing = true
        
        logDebug("Resuming polling")
        self.processPolling(info.statusInfo,
                    token: info.token,
                    errorCount: 0)
    }
    
    private func failPolling(with error: PairingManagingError) {
        isBusyReversePairing = false
        pollingResumeBlock = nil
        lastPollingError = error
        
        switch error {
        case .pairingCancelled:
            listeners.forEach { $0.listener?.pairingManagerDidCancelPollingForPairing(self) }
        default:
            listeners.forEach { $0.listener?.pairingManager(self, didFailWith: error) }
        }
        
        endBackgroundTaskIfNeeded()
    }
    
    private func finishPolling(with pairingCode: String?) {
        guard let pairingCode = pairingCode else {
            logError("Invalid pairing code")
            failPolling(with: .couldNotPair(.invalidResponse))
            return
        }
        
        pollingResumeBlock = nil
        lastPollingError = nil
        reversePairingInfo = nil // Should pairing fail at this point, the info won't be valid anymore
        
        pair(pairingCode: pairingCode) { success, error in
            self.isBusyReversePairing = false
            
            if success {
                self.listeners.forEach { $0.listener?.pairingManagerDidFinishPairing(self) }
            } else {
                self.listeners.forEach { $0.listener?.pairingManager(self, didFailWith: error ?? .notPaired) }
            }
            
            self.endBackgroundTaskIfNeeded()
        }
    }
}
