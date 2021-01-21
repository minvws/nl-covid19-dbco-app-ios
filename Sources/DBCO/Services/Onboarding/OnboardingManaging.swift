/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import Contacts

struct Onboarding {
    enum ContagiousPeriodState {
        case undetermined
        case finishedWithSymptoms([String], onset: Date)
        case finishedWithTestDate(Date)
        
        var symptomOnsetDate: Date? {
            switch self {
            case .finishedWithSymptoms(_, let date):
                return date
            default:
                return nil
            }
        }
        
        var testDate: Date? {
            switch self {
            case .finishedWithTestDate(let date):
                return date
            default:
                return nil
            }
        }
    }
    
    struct Roommate: Codable {
        var name: String
        var contactIdentifier: String?
        
        init(name: String, contactIdentifier: String?) {
            self.name = name
            self.contactIdentifier = contactIdentifier
        }
    }
    
    struct Contact: Codable {
        var date: Date
        var name: String
        var contactIdentifier: String?
        
        init(date: Date, name: String, contactIdentifier: String?) {
            self.date = date
            self.name = name
            self.contactIdentifier = contactIdentifier
        }
    }
}

/// - Tag: OnboardingManaging
protocol OnboardingManaging {
    
    init()
    
    var needsOnboarding: Bool { get }
    var needsPairingOption: Bool { get }
    
    var contagiousPeriod: Onboarding.ContagiousPeriodState { get }
    var roommates: [Onboarding.Roommate]? { get }
    var contacts: [Onboarding.Contact]? { get }
    
    func registerSymptoms(_ symptoms: [String], dateOfOnset: Date)
    func registerTestDate(_ date: Date)
    
    func registerRoommates(_ roommates: [Onboarding.Roommate])
    func registerContacts(_ contacts: [Onboarding.Contact])
    
    func finishOnboarding()
    
}
