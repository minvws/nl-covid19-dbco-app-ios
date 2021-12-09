/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import XCTest
@testable import GGD_Contact

class TaskOverviewViewModelTests: XCTestCase {
    
    func testEmptyOverview() {
        let pairingManager = MockPairingManager(networkManager: MockNetworkManager(configuration: .test))
        let caseManager = MockCaseManager()
        
        let input = TaskOverviewViewModel.Input(pairing: pairingManager, case: caseManager)
        let viewModel = TaskOverviewViewModel(input)
        
        var isPromptVisible = false
        
        viewModel.setupTableView(UITableView.createDefaultGrouped(),
                                 tableHeaderBuilder: nil,
                                 sectionHeaderBuilder: nil,
                                 tableFooterBuilder: nil,
                                 selectedTaskHandler: { _, _ in })
        viewModel.setHidePrompt { _ in isPromptVisible = false }
        viewModel.setShowPrompt { _ in isPromptVisible = true }
        
        XCTAssertTrue(viewModel.isPairingViewHidden)
        XCTAssertTrue(viewModel.isPairingErrorViewHidden)
        XCTAssertTrue(viewModel.isWindowExpiredMessageHidden)
        XCTAssertTrue(viewModel.isResetButtonHidden)
        
        XCTAssertFalse(viewModel.isDoneButtonHidden)
        XCTAssertFalse(viewModel.isAddContactButtonHidden)
        XCTAssertFalse(isPromptVisible)
    }
    
    func testUnsyncedTaskOverview() {
        let pairingManager = MockPairingManager(networkManager: MockNetworkManager(configuration: .test))
        let caseManager = MockCaseManager()
        caseManager.isSynced = false
        
        let input = TaskOverviewViewModel.Input(pairing: pairingManager, case: caseManager)
        let viewModel = TaskOverviewViewModel(input)
        
        var isPromptVisible = false
        
        viewModel.setupTableView(UITableView.createDefaultGrouped(),
                                 tableHeaderBuilder: nil,
                                 sectionHeaderBuilder: nil,
                                 tableFooterBuilder: nil,
                                 selectedTaskHandler: { _, _ in })
        viewModel.setHidePrompt { _ in isPromptVisible = false }
        viewModel.setShowPrompt { _ in isPromptVisible = true }
        
        XCTAssertTrue(viewModel.isPairingViewHidden)
        XCTAssertTrue(viewModel.isPairingErrorViewHidden)
        XCTAssertTrue(viewModel.isWindowExpiredMessageHidden)
        XCTAssertTrue(viewModel.isResetButtonHidden)
        XCTAssertTrue(isPromptVisible)
        
        XCTAssertFalse(viewModel.isDoneButtonHidden)
        XCTAssertFalse(viewModel.isAddContactButtonHidden)
    }
    
    func testExpiredTaskOverviewSynced() {
        let pairingManager = MockPairingManager(networkManager: MockNetworkManager(configuration: .test))
        let caseManager = MockCaseManager()
        caseManager.isSynced = true
        caseManager.isWindowExpired = true
        
        let input = TaskOverviewViewModel.Input(pairing: pairingManager, case: caseManager)
        let viewModel = TaskOverviewViewModel(input)
        
        var isPromptVisible = false
        
        viewModel.setupTableView(UITableView.createDefaultGrouped(),
                                 tableHeaderBuilder: nil,
                                 sectionHeaderBuilder: nil,
                                 tableFooterBuilder: nil,
                                 selectedTaskHandler: { _, _ in })
        viewModel.setHidePrompt { _ in isPromptVisible = false }
        viewModel.setShowPrompt { _ in isPromptVisible = true }
        
        XCTAssertTrue(viewModel.isPairingViewHidden)
        XCTAssertTrue(viewModel.isPairingErrorViewHidden)
        XCTAssertTrue(viewModel.isAddContactButtonHidden)
        XCTAssertTrue(viewModel.isAddContactButtonHidden)
        XCTAssertTrue(isPromptVisible)
        
        XCTAssertFalse(viewModel.isResetButtonHidden)
        XCTAssertTrue(viewModel.isDoneButtonHidden)
        XCTAssertFalse(viewModel.isWindowExpiredMessageHidden)
    }
    
    func testExpiredTasksOverviewUnsynced() {
        let pairingManager = MockPairingManager(networkManager: MockNetworkManager(configuration: .test))
        let caseManager = MockCaseManager()
        caseManager.isSynced = false
        caseManager.isWindowExpired = true
        
        let input = TaskOverviewViewModel.Input(pairing: pairingManager, case: caseManager)
        let viewModel = TaskOverviewViewModel(input)
        
        var isPromptVisible = false
        
        viewModel.setupTableView(UITableView.createDefaultGrouped(),
                                 tableHeaderBuilder: nil,
                                 sectionHeaderBuilder: nil,
                                 tableFooterBuilder: nil,
                                 selectedTaskHandler: { _, _ in })
        viewModel.setHidePrompt { _ in isPromptVisible = false }
        viewModel.setShowPrompt { _ in isPromptVisible = true }
        
        XCTAssertTrue(viewModel.isPairingViewHidden)
        XCTAssertTrue(viewModel.isPairingErrorViewHidden)
        XCTAssertTrue(viewModel.isAddContactButtonHidden)
        XCTAssertTrue(viewModel.isAddContactButtonHidden)
        XCTAssertTrue(isPromptVisible)
        
        XCTAssertFalse(viewModel.isResetButtonHidden)
        XCTAssertTrue(viewModel.isDoneButtonHidden)
        XCTAssertFalse(viewModel.isWindowExpiredMessageHidden)
    }
    
    func testTaskOverviewBecameExpired() {
        let pairingManager = MockPairingManager(networkManager: MockNetworkManager(configuration: .test))
        let caseManager = MockCaseManager()
        caseManager.isWindowExpired = false
        
        let input = TaskOverviewViewModel.Input(pairing: pairingManager, case: caseManager)
        let viewModel = TaskOverviewViewModel(input)
        
        var isPromptVisible = false
        
        viewModel.setupTableView(UITableView.createDefaultGrouped(),
                                 tableHeaderBuilder: nil,
                                 sectionHeaderBuilder: nil,
                                 tableFooterBuilder: nil,
                                 selectedTaskHandler: { _, _ in })
        viewModel.setHidePrompt { _ in isPromptVisible = false }
        viewModel.setShowPrompt { _ in isPromptVisible = true }
        
        XCTAssertTrue(viewModel.isPairingViewHidden)
        XCTAssertTrue(viewModel.isPairingErrorViewHidden)
        XCTAssertTrue(viewModel.isWindowExpiredMessageHidden)
        XCTAssertTrue(viewModel.isResetButtonHidden)
        
        XCTAssertFalse(viewModel.isDoneButtonHidden)
        XCTAssertFalse(viewModel.isAddContactButtonHidden)
        XCTAssertFalse(isPromptVisible)
        
        caseManager.isWindowExpired = true
        
        XCTAssertTrue(viewModel.isPairingViewHidden)
        XCTAssertTrue(viewModel.isPairingErrorViewHidden)
        XCTAssertTrue(viewModel.isAddContactButtonHidden)
        
        XCTAssertTrue(viewModel.isDoneButtonHidden)
        XCTAssertTrue(viewModel.isAddContactButtonHidden)
        XCTAssertTrue(isPromptVisible)
        
        XCTAssertFalse(viewModel.isWindowExpiredMessageHidden)
        XCTAssertFalse(viewModel.isResetButtonHidden)
    }
    
    func testAddContactButtonStateForUninformedContacts() {
        let pairingManager = MockPairingManager(networkManager: MockNetworkManager(configuration: .test))
        let caseManager = MockCaseManager()
        caseManager.tasks = [createUninformedTask(label: "Anna Haro")]
        caseManager.hasSynced = false
        
        let input = TaskOverviewViewModel.Input(pairing: pairingManager, case: caseManager)
        let viewModel = TaskOverviewViewModel(input)
        
        viewModel.setupTableView(UITableView.createDefaultGrouped(),
                                 tableHeaderBuilder: nil,
                                 sectionHeaderBuilder: nil,
                                 tableFooterBuilder: nil,
                                 selectedTaskHandler: { _, _ in })
        
        XCTAssertFalse(viewModel.isAddContactButtonHidden)
    }
    
    func testAddContactButtonStateForInformedContacts() {
        let pairingManager = MockPairingManager(networkManager: MockNetworkManager(configuration: .test))
        let caseManager = MockCaseManager()
        caseManager.tasks = [createInformedTask(label: "Anna Haro")]
        caseManager.hasSynced = false
        
        let input = TaskOverviewViewModel.Input(pairing: pairingManager, case: caseManager)
        let viewModel = TaskOverviewViewModel(input)
        
        viewModel.setupTableView(UITableView.createDefaultGrouped(),
                                 tableHeaderBuilder: nil,
                                 sectionHeaderBuilder: nil,
                                 tableFooterBuilder: nil,
                                 selectedTaskHandler: { _, _ in })
        
        XCTAssertFalse(viewModel.isAddContactButtonHidden)
    }
    
    func testAddContactButtonStateForInformedAndUninformedContacts() {
        let pairingManager = MockPairingManager(networkManager: MockNetworkManager(configuration: .test))
        let caseManager = MockCaseManager()
        caseManager.tasks = [createInformedTask(label: "Anna Haro"), createUninformedTask(label: "Daniel Higgins")]
        caseManager.hasSynced = false
        
        let input = TaskOverviewViewModel.Input(pairing: pairingManager, case: caseManager)
        let viewModel = TaskOverviewViewModel(input)
        
        viewModel.setupTableView(UITableView.createDefaultGrouped(),
                                 tableHeaderBuilder: nil,
                                 sectionHeaderBuilder: nil,
                                 tableFooterBuilder: nil,
                                 selectedTaskHandler: { _, _ in })
        
        XCTAssertFalse(viewModel.isAddContactButtonHidden)
    }
    
    func testAddContactButtonStateForUnsyncedContacts() {
        let pairingManager = MockPairingManager(networkManager: MockNetworkManager(configuration: .test))
        let caseManager = MockCaseManager()
        caseManager.tasks = [createUnsyncedTask(label: "Anna Haro")]
        caseManager.hasSynced = true
        
        let input = TaskOverviewViewModel.Input(pairing: pairingManager, case: caseManager)
        let viewModel = TaskOverviewViewModel(input)
        
        viewModel.setupTableView(UITableView.createDefaultGrouped(),
                                 tableHeaderBuilder: nil,
                                 sectionHeaderBuilder: nil,
                                 tableFooterBuilder: nil,
                                 selectedTaskHandler: { _, _ in })
        
        XCTAssertFalse(viewModel.isAddContactButtonHidden)
    }
    
    func testAddContactButtonStateForSyncedContacts() {
        let pairingManager = MockPairingManager(networkManager: MockNetworkManager(configuration: .test))
        let caseManager = MockCaseManager()
        caseManager.tasks = [createSyncedTask(label: "Anna Haro")]
        caseManager.hasSynced = true
        
        let input = TaskOverviewViewModel.Input(pairing: pairingManager, case: caseManager)
        let viewModel = TaskOverviewViewModel(input)
        
        viewModel.setupTableView(UITableView.createDefaultGrouped(),
                                 tableHeaderBuilder: nil,
                                 sectionHeaderBuilder: nil,
                                 tableFooterBuilder: nil,
                                 selectedTaskHandler: { _, _ in })
        
        XCTAssertFalse(viewModel.isAddContactButtonHidden)
    }
    
    func testAddContactButtonStateForSyncedAndUnsyncedContacts() {
        let pairingManager = MockPairingManager(networkManager: MockNetworkManager(configuration: .test))
        let caseManager = MockCaseManager()
        caseManager.tasks = [createSyncedTask(label: "Anna Haro"), createUnsyncedTask(label: "Daniel Higgins")]
        caseManager.hasSynced = true
        
        let input = TaskOverviewViewModel.Input(pairing: pairingManager, case: caseManager)
        let viewModel = TaskOverviewViewModel(input)
        
        viewModel.setupTableView(UITableView.createDefaultGrouped(),
                                 tableHeaderBuilder: nil,
                                 sectionHeaderBuilder: nil,
                                 tableFooterBuilder: nil,
                                 selectedTaskHandler: { _, _ in })
        
        XCTAssertFalse(viewModel.isAddContactButtonHidden)
    }

}

private func createInformedTask(label: String) -> Task {
    var task = Task(type: .contact, label: label, source: .app)
    task.contact = .init(category: .category1, communication: .index, informedByIndexAt: ISO8601DateFormatter().string(from: Date()), dateOfLastExposure: nil, canShareIndexNameWithContact: nil)
    return task
}

private func createUninformedTask(label: String) -> Task {
    var task = Task(type: .contact, label: label, source: .app)
    task.contact = .init(category: .category1, communication: .index, informedByIndexAt: nil, dateOfLastExposure: nil, canShareIndexNameWithContact: nil)
    return task
}

private func createSyncedTask(label: String) -> Task {
    var task = createInformedTask(label: label)
    task.isSyncedWithPortal = true
    return task
}

private func createUnsyncedTask(label: String) -> Task {
    var task = createInformedTask(label: label)
    task.isSyncedWithPortal = false
    return task
}

private class MockCaseManager: CaseManaging {
    var dataModificationDate: Date?
    var hasCaseData: Bool = true
    var isSynced: Bool = true
    var hasSynced: Bool = false
    var isWindowExpired: Bool = false {
        didSet {
            if isWindowExpired {
                listeners.forEach { $0.caseManagerWindowExpired(self) }
            }
        }
    }
    var dateOfSymptomOnset: Date?
    var dateOfTest: Date?
    var startOfContagiousPeriod: Date?
    var symptomsKnown: Bool = true
    var reference: String?
    var symptoms: [String] = []
    var tasks: [Task] = []
    
    private var listeners = [CaseManagerListener]()
    
    required init() {}
    
    func questionnaire(for taskType: Task.TaskType) throws -> Questionnaire {
        return Questionnaire(uuid: .init(), taskType: .contact, questions: [])
    }
    
    func loadCaseData(userInitiated: Bool, completion: @escaping (Bool, CaseManagingError?) -> Void) {}
    func startLocalCaseIfNeeded(dateOfSymptomOnset: Date) {}
    func startLocalCaseIfNeeded(dateOfTest: Date) {}
    func removeCaseData() throws {}
    func addListener(_ listener: CaseManagerListener) {
        listeners.append(listener)
        
        if isWindowExpired {
            listener.caseManagerWindowExpired(self)
        }
    }
    func save(_ task: Task) throws {}
    func addContactTask(name: String, category: Task.Contact.Category, contactIdentifier: String?, dateOfLastExposure: Date?) {}
    func setSymptoms(symptoms: [String]) {}
    func sync(completionHandler: ((Bool) -> Void)?) throws {}
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

private class MockPairingManager: PairingManaging {
    
    var isPaired: Bool = true
    var isPollingForPairing: Bool = false
    
    var canResumePolling: Bool = false
    var lastPairingCode: String?
    var lastPollingError: PairingManagingError?
    
    required init(networkManager: NetworkManaging) {}
    
    func caseToken() throws -> String {
        return ""
    }
    
    func pair(pairingCode: String, completion: @escaping (Bool, PairingManagingError?) -> Void) {}
    func unpair() {}
    func startPollingForPairing() {}
    func stopPollingForPairing() {}
    func addListener(_ listener: PairingManagerListener) {}
    
    func seal<T>(_ value: T) throws -> (ciperText: String, nonce: String) where T: Encodable {
        throw PairingManagingError.encryptionError
    }
    
    func open<T>(cipherText: String, nonce: String) throws -> T where T: Decodable {
        throw PairingManagingError.encryptionError
    }

}
