/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import XCTest
import Sodium
@testable import GGD_Contact

class PairingManagerTests: XCTestCase {
    
    let pairingManager = PairingManager(networkManager: MockNetworkManager(configuration: .unitTest))
    private let healthAuthority = MockHealthAuthority()
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        pairingManager.unpair()
    }
    
    func testClearedPairingManager() {
        XCTAssertFalse(pairingManager.isPaired)
    }
    
    func testPairing() {
        XCTAssertFalse(pairingManager.isPaired)
        
        let expectation = XCTestExpectation(description: "Pairing completes")
        
        pairingManager.pair(pairingCode: "1111-1111-1111") { _, _ in expectation.fulfill() }
        
        _ = XCTWaiter.wait(for: [expectation], timeout: 5.0)
        
        XCTAssertTrue(pairingManager.isPaired)
        XCTAssertEqual(try pairingManager.caseToken(), MockHealthAuthority.caseToken)
    }
    
    func testPairingAndUnpairing() {
        XCTAssertFalse(pairingManager.isPaired)
        
        let expectation = XCTestExpectation(description: "Pairing completes")
        
        pairingManager.pair(pairingCode: "1111-1111-1111") { _, _ in expectation.fulfill() }
        
        _ = XCTWaiter.wait(for: [expectation], timeout: 5.0)
        
        XCTAssertTrue(pairingManager.isPaired)
        XCTAssertEqual(try pairingManager.caseToken(), MockHealthAuthority.caseToken)
        
        pairingManager.unpair()
        
        XCTAssertFalse(pairingManager.isPaired)
        XCTAssertThrowsError(try pairingManager.caseToken())
    }
    
    func testRepeatedPairingAndUnpairing() {
        XCTAssertFalse(pairingManager.isPaired)
        
        for _ in 0..<3 {
            let expectation = XCTestExpectation(description: "Pairing completes")
            
            pairingManager.pair(pairingCode: "1111-1111-1111") { _, _ in expectation.fulfill() }
            
            _ = XCTWaiter.wait(for: [expectation], timeout: 5.0)
            
            XCTAssertTrue(pairingManager.isPaired)
            XCTAssertEqual(try pairingManager.caseToken(), MockHealthAuthority.caseToken)
            
            pairingManager.unpair()
            
            XCTAssertFalse(pairingManager.isPaired)
            XCTAssertThrowsError(try pairingManager.caseToken())
        }
    }
    
    func testSealingData() {
        let expectation = XCTestExpectation(description: "Pairing completes")
        pairingManager.pair(pairingCode: "1111-1111-1111") { _, _ in expectation.fulfill() }
    
        _ = XCTWaiter.wait(for: [expectation], timeout: 5.0)
        XCTAssertTrue(pairingManager.isPaired)
        
        struct SimpleStructure: Equatable, Codable {
            var test1: Int
            var test2: String
        }
        
        let value = SimpleStructure(test1: 3738, test2: "Hello World")
        
        let data = try? pairingManager.seal(value)
        XCTAssertNotNil(data)
        
        let openedValue: SimpleStructure? = try? MockHealthAuthority.open(cipherText: data!.ciperText, nonce: data!.nonce)
        XCTAssertNotNil(openedValue)
        
        XCTAssertEqual(value, openedValue)
    }
    
    func testOpeningData() {
        let expectation = XCTestExpectation(description: "Pairing completes")
        pairingManager.pair(pairingCode: "1111-1111-1111") { _, _ in expectation.fulfill() }
    
        _ = XCTWaiter.wait(for: [expectation], timeout: 5.0)
        XCTAssertTrue(pairingManager.isPaired)
        
        struct SimpleStructure: Equatable, Codable {
            var test1: Int
            var test2: String
        }
        
        let value = SimpleStructure(test1: 3738, test2: "Hello World")
        
        let data = try? MockHealthAuthority.seal(value)
        XCTAssertNotNil(data)
        
        let openedValue: SimpleStructure? = try? pairingManager.open(cipherText: data!.ciperText, nonce: data!.nonce)
        XCTAssertNotNil(openedValue)
        
        XCTAssertEqual(value, openedValue)
    }
}

private class MockHealthAuthority {
    private static let sodium = Sodium()
    private static let keyPair = sodium.keyExchange.keyPair()!
    private static let sealing = Sealing(sodium: sodium)
    private static var caseKeyPair: KeyExchange.KeyPair?
    private static var caseSessionKeyPair: KeyExchange.SessionKeyPair?
    
    static var caseToken: String? {
        guard let sessionKeyPair = caseSessionKeyPair else { return nil }
        
        let concatenated = sessionKeyPair.tx + sessionKeyPair.rx
        let hash = sodium.genericHash.hash(message: concatenated)!
        
        return hash.map { String(format: "%02x", $0) }.joined()
    }
    
    static var haPublicKey: String {
        return Data(keyPair.publicKey).base64EncodedString()
    }
    
    static func sealedHealthAuthorityPublicKey(for sealedClientPublicKey: Data) -> Data {
        let clientPublicKey = sodium.box.open(anonymousCipherText: Bytes(sealedClientPublicKey),
                                              recipientPublicKey: keyPair.publicKey,
                                              recipientSecretKey: keyPair.secretKey)!
        
        let caseKeyPair = sodium.keyExchange.keyPair()!
        let sessionKeyPair = sodium.keyExchange.sessionKeyPair(publicKey: caseKeyPair.publicKey, secretKey: caseKeyPair.secretKey, otherPublicKey: clientPublicKey, side: .SERVER)
        
        self.caseKeyPair = caseKeyPair
        self.caseSessionKeyPair = sessionKeyPair
        
        let data = sodium.box.seal(message: caseKeyPair.publicKey, recipientPublicKey: clientPublicKey)!
        
        return Data(data)
    }
    
    static func seal<T: Encodable>(_ value: T) throws -> (ciperText: String, nonce: String) {
        guard let sessionKeyPair = caseSessionKeyPair else { throw PairingManagingError.notPaired }
        
        return try sealing.seal(value, transmitKey: sessionKeyPair.tx)
    }
    
    static func open<T: Decodable>(cipherText: String, nonce: String) throws -> T {
        guard let sessionKeyPair = caseSessionKeyPair else { throw PairingManagingError.notPaired }
        
        return try sealing.open(cipherText: cipherText, nonce: nonce, receiveKey: sessionKeyPair.rx)
    }
}

private extension NetworkConfiguration {
    static let unitTest = NetworkConfiguration(
        name: "UnitTest",
        api: NetworkConfiguration.development.api,
        haPublicKey: .init(
            encodedPublicKey: MockHealthAuthority.haPublicKey,
            keyVersion: "20212505"))
}

private class MockNetworkManager: NetworkManaging {
    var configuration: NetworkConfiguration
    
    required init(configuration: NetworkConfiguration) {
        self.configuration = configuration
    }
    
    func getAppConfiguration(completion: @escaping (Result<AppConfiguration, NetworkError>) -> Void) -> URLSessionTask? {
        return nil
    }
    
    func pair(code: String, sealedClientPublicKey: Data, completion: @escaping (Result<PairResponse, NetworkError>) -> Void) -> URLSessionTask? {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .random(in: 0...1)) {
            let sealedHAPublicKey = MockHealthAuthority.sealedHealthAuthorityPublicKey(for: sealedClientPublicKey)
            completion(.success(PairResponse(sealedHealthAuthorityPublicKey: sealedHAPublicKey)))
        }
        
        return nil
    }
    
    func getCase(identifier: String, completion: @escaping (Result<Case, NetworkError>) -> Void) -> URLSessionTask? {
        return nil
    }
    
    func putCase(identifier: String, value: Case, completion: @escaping (Result<Void, NetworkError>) -> Void) -> URLSessionTask? {
        return nil
    }
    
    func getQuestionnaires(completion: @escaping (Result<[Questionnaire], NetworkError>) -> Void) -> URLSessionTask? {
        return nil
    }
    
    func postPairingRequest(completion: @escaping (Result<ReversePairingInfo, NetworkError>) -> Void) -> URLSessionTask? {
        return nil
    }
    
    func getPairingRequestStatus(token: String, completion: @escaping (Result<ReversePairingStatusInfo, NetworkError>) -> Void) -> URLSessionTask? {
        return nil
    }
}
