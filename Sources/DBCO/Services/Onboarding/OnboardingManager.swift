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
    var symptoms: [String]?
    var roommates: [Onboarding.Roommate]?
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
    
    var needsOnboarding: Bool {
        return Self.onboardingData.needsOnboarding
    }
    
    var needsPairingOption: Bool {
        return !Services.pairingManager.isPaired
    }
    
    private(set) var contagiousPeriod: Onboarding.ContagiousPeriodState
    
    var roommates: [Onboarding.Roommate]? {
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
    
    func registerSymptoms(_ symptoms: [String], dateOfOnset: Date) {
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
    
    func registerRoommates(_ roommates: [Onboarding.Roommate]) {
        Self.onboardingData.roommates = roommates
    }
    
    func registerContacts(_ contacts: [Onboarding.Contact]) {
        Self.onboardingData.contacts = contacts
    }
    
    func finishOnboarding(createTasks: Bool) {
        func filter(_ roommates: [Onboarding.Roommate]) -> [Onboarding.Roommate] {
            var filteredRoommates = [Onboarding.Roommate]()
            roommates.forEach { roommate in
                if let duplicateIndex = filteredRoommates.firstIndex(where: { $0.name == roommate.name }) {
                    filteredRoommates[duplicateIndex].contactIdentifier = filteredRoommates[duplicateIndex].contactIdentifier ?? roommate.contactIdentifier
                } else {
                    filteredRoommates.append(roommate)
                }
            }
            
            return filteredRoommates
        }
        
        func filter(_ contacts: [Onboarding.Contact], withRoommates roommates: [Onboarding.Roommate]) -> [Onboarding.Contact] {
            var filteredContacts = [Onboarding.Contact]()
            contacts
                .filter { contact in !roommates.contains { $0.name == contact.name } }
                .forEach { contact in
                    if let duplicateIndex = filteredContacts.firstIndex(where: { $0.name == contact.name }) {
                        filteredContacts[duplicateIndex].date = max(contact.date, filteredContacts[duplicateIndex].date)
                        filteredContacts[duplicateIndex].contactIdentifier = filteredContacts[duplicateIndex].contactIdentifier ?? contact.contactIdentifier
                    } else {
                        filteredContacts.append(contact)
                    }
                }
            
            return filteredContacts
        }
        
        if !Services.caseManager.hasCaseData {
            if let dateOfSymptomOnset = Self.onboardingData.dateOfSymptomOnset {
                try! Services.caseManager.startLocalCase(dateOfSymptomOnset: dateOfSymptomOnset) // swiftlint:disable:this force_try
            } else if let testDate = Self.onboardingData.testDate {
                try! Services.caseManager.startLocalCase(dateOfSymptomOnset: testDate) // swiftlint:disable:this force_try
            }
        }
        
        if createTasks {
            let roommates = filter(Self.onboardingData.roommates ?? [])
            let contacts = filter(Self.onboardingData.contacts ?? [], withRoommates: roommates)
            
            roommates.forEach { Services.caseManager.addRoommateTask(name: $0.name, contactIdentifier: $0.contactIdentifier) }
            contacts.forEach { Services.caseManager.addContactTask(name: $0.name, contactIdentifier: $0.contactIdentifier, dateOfLastExposure: $0.date) }
        }
        
        Self.$onboardingData.clearData()
        
        Self.onboardingData.needsOnboarding = false
    }
    
    func reset() {
        Self.$onboardingData.clearData()
    }
    
}
