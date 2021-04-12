/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

private struct OnboardingData: Codable {
    var needsOnboarding: Bool
    var dateOfSymptomOnset: Date?
    var testDate: Date?
    var symptoms: [Symptom]?
    var roommates: [Onboarding.Contact]?
    var contacts: [Onboarding.Contact]?
}

private extension OnboardingData {
    static var empty: OnboardingData {
        return OnboardingData(needsOnboarding: true,
                              dateOfSymptomOnset: nil,
                              testDate: nil,
                              symptoms: nil,
                              roommates: nil,
                              contacts: nil)
    }
}

/// - Tag: OnboardingManager
class OnboardingManager: OnboardingManaging, Logging {
    var loggingCategory: String = "OnboardingManager"
    
    private struct Constants {
        static let keychainService = "OnboardingManager"
    }
    
    @Keychain(name: "onboardingData", service: Constants.keychainService, clearOnReinstall: true)
    private static var onboardingData: OnboardingData = .empty // swiftlint:disable:this let_var_whitespace
    
    var dataModificationDate: Date? {
        return Self.$onboardingData.modificationDate
    }
    
    var needsOnboarding: Bool {
        return Self.onboardingData.needsOnboarding
    }
    
    var needsPairingOption: Bool {
        return !Services.pairingManager.isPaired
    }
    
    private(set) var contagiousPeriod: Onboarding.ContagiousPeriodState
    
    var roommates: [Onboarding.Contact]? {
        return Self.onboardingData.roommates
    }
    
    var contacts: [Onboarding.Contact]? {
        return Self.onboardingData.contacts
    }
    
    required init() {
        if let symptoms = Self.onboardingData.symptoms, let onsetDate = Self.onboardingData.dateOfSymptomOnset {
            contagiousPeriod = .finishedWithSymptoms(symptoms, onset: onsetDate)
        } else if let testDate = Self.onboardingData.testDate {
            contagiousPeriod = .finishedWithTestDate(testDate)
        } else {
            contagiousPeriod = .undetermined
        }
    }
    
    func registerSymptoms(_ symptoms: [Symptom], dateOfOnset: Date) {
        Self.onboardingData.symptoms = symptoms
        Self.onboardingData.dateOfSymptomOnset = dateOfOnset
        Self.onboardingData.testDate = nil
        
        contagiousPeriod = .finishedWithSymptoms(symptoms, onset: dateOfOnset)
    }
    
    func registerTestDate(_ date: Date) {
        Self.onboardingData.testDate = date
        Self.onboardingData.symptoms = nil
        Self.onboardingData.dateOfSymptomOnset = nil
        
        contagiousPeriod = .finishedWithTestDate(date)
    }
    
    func registerRoommates(_ roommates: [Onboarding.Contact]) {
        Self.onboardingData.roommates = roommates
    }
    
    func registerContacts(_ contacts: [Onboarding.Contact]) {
        Self.onboardingData.contacts = contacts
    }
    
    func finishOnboarding() {
        let symptoms = Self.onboardingData.symptoms?.map(\.value) ?? []
        
        if let dateOfSymptomOnset = Self.onboardingData.dateOfSymptomOnset {
            Services.caseManager.startLocalCaseIfNeeded(dateOfSymptomOnset: dateOfSymptomOnset)
            Services.caseManager.setSymptoms(symptoms: symptoms)
        } else if let testDate = Self.onboardingData.testDate {
            Services.caseManager.startLocalCaseIfNeeded(dateOfTest: testDate)
        }
        
        mergeContacts(roommates: Self.onboardingData.roommates,
                      contacts: Self.onboardingData.contacts).forEach {
                        
            Services.caseManager.addContactTask(name: $0.name,
                                                category: $0.isRoommate ? .category1 : .other,
                                                contactIdentifier: $0.contactIdentifier,
                                                dateOfLastExposure: $0.date)
        }
        
        contagiousPeriod = .undetermined
        
        Self.$onboardingData.clearData()
        Self.onboardingData.needsOnboarding = false
    }
    
    private func mergeContacts(roommates: [Onboarding.Contact]?, contacts: [Onboarding.Contact]?) -> [Onboarding.Contact] {
        var filteredContacts = [Onboarding.Contact]()
        let allContacts = (roommates ?? []) + (contacts ?? [])
        
        allContacts
            .forEach { contact in
                if let duplicateIndex = filteredContacts.firstIndex(where: { $0.name == contact.name }) {
                    switch (contact.date, filteredContacts[duplicateIndex].date) {
                    case (.some(let date), .some(let otherDate)):
                        filteredContacts[duplicateIndex].date = max(date, otherDate)
                    case (.some(let date), .none), (.none, .some(let date)):
                        filteredContacts[duplicateIndex].date = date
                    case (.none, .none):
                        filteredContacts[duplicateIndex].date = nil
                    }
                    
                    filteredContacts[duplicateIndex].contactIdentifier = filteredContacts[duplicateIndex].contactIdentifier ?? contact.contactIdentifier
                    filteredContacts[duplicateIndex].isRoommate = filteredContacts[duplicateIndex].isRoommate || contact.isRoommate
                } else {
                    filteredContacts.append(contact)
                }
            }
        
        return filteredContacts
    }
    
    func reset() {
        Self.$onboardingData.clearData()
        contagiousPeriod = .undetermined
    }
    
}
