/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

enum CaseManagingError: Error {
    case noCaseData
    case alreadyHaseCase
    case questionnaireNotFound
    case couldNotLoadTasks(NetworkError)
    case couldNotLoadQuestionnaires(NetworkError)
    case windowExpired
}

/// Loads tasks and questionnaires.
/// Facilitates storing and uploading results to the backend.
/// Publishes updates to the internal store via [CaseManagerListener](x-source-tag://CaseManagerListener)
///
/// # See also:
/// [Task](x-source-tag://Task),
/// [AppData](x-source-tag://AppData),
/// [CaseManager](x-source-tag://CaseManager),
/// [Questionnaire](x-source-tag://Questionnaire)
///
/// - Tag: CaseManaging
protocol CaseManaging {
    
    init()
    
    var dataModificationDate: Date? { get }
    
    var hasCaseData: Bool { get }
    
    /// Indicates that alls the tasks are uploaded to the backend in their current state
    var isSynced: Bool { get }
    
    /// Indicates that an upload occured at least once
    var hasSynced: Bool { get }
    
    /// Indicates that tasks can no longer be uploaded to the backedn
    var isWindowExpired: Bool { get }
    
    var dateOfSymptomOnset: Date? { get }
    var dateOfTest: Date? { get }
    var startOfContagiousPeriod: Date? { get }
    var symptomsKnown: Bool { get }
    
    var reference: String? { get }
    
    var symptoms: [String] { get }
    
    var tasks: [Task] { get }
    
    /// Returns the [Questionnaire](x-source-tag://Questionnaire) associated with a task type.
    /// Throws an `notPaired` error when called befored paired.
    /// Throws an `questionnaireNotFound` error when there's no suitable questionnaire  for the supplied task
    func questionnaire(for taskType: Task.TaskType) throws -> Questionnaire
    
    func loadCaseData(userInitiated: Bool, completion: @escaping (_ success: Bool, _ error: CaseManagingError?) -> Void)
    
    func startLocalCaseIfNeeded(dateOfSymptomOnset: Date)
    func startLocalCaseIfNeeded(dateOfTest: Date)
    
    /// Clears all stored data. Using any method or property except for `hasCaseData` on CaseManager before pairing and loading the data again is an invalid operation.
    /// Throws an `notPaired` error when called befored paired.
    func removeCaseData() throws
    
    /// Adds a listener
    /// - parameter listener: The object conforming to [CaseManagerListener](x-source-tag://CaseManagerListener) that will receive updates. Will be stored with a weak reference
    func addListener(_ listener: CaseManagerListener)
    
    /// Saves updates to a task if a task with the same uuid is already managed, or stores a new task.
    /// Throws an `notPaired` error when called befored paired.
    func save(_ task: Task) throws
    
    func addContactTask(name: String, category: Task.Contact.Category, contactIdentifier: String?, dateOfLastExposure: Date?)
    
    func setSymptoms(symptoms: [String])
    
    /// Uploads all the tasks to the backend.
    /// Throws an `notPaired` error when called befored paired.
    ///
    /// - parameter completionHandler: The closure to be called after the upload was finished.
    func sync(completionHandler: ((_ success: Bool) -> Void)?) throws
}

/// - Tag: CaseManagerListener
protocol CaseManagerListener: AnyObject {
    /// Called after updates are made to the managed tasks
    func caseManagerDidUpdateTasks(_ caseManager: CaseManaging)
    
    /// Called after tasks were uploaded to the backend
    func caseManagerDidUpdateSyncState(_ caseManager: CaseManaging)
    
    /// Called when the window for uploading data has expired
    func caseManagerWindowExpired(_ caseManager: CaseManaging)
}
