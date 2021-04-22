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
        case finishedWithSymptoms([Symptom], onset: Date)
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
    
    struct Contact: Codable {
        var date: Date?
        var name: String
        var contactIdentifier: String?
        var isRoommate: Bool
        
        init(date: Date?, name: String, contactIdentifier: String?, isRoommate: Bool) {
            self.date = date
            self.name = name
            self.contactIdentifier = contactIdentifier
            self.isRoommate = isRoommate
        }
    }
}

/// Manages data needed during onboarding and facilitates basic state restoration for the onboarding screens.
///
/// - Tag: OnboardingManaging
protocol OnboardingManaging {
    
    init()
    
    var dataModificationDate: Date? { get }
    
    var needsOnboarding: Bool { get }
    var needsPairingOption: Bool { get }
    
    var contagiousPeriod: Onboarding.ContagiousPeriodState { get }
    var roommates: [Onboarding.Contact]? { get }
    var contacts: [Onboarding.Contact]? { get }
    
    func registerSymptoms(_ symptoms: [Symptom], dateOfOnset: Date)
    func registerTestDate(_ date: Date)
    
    func registerRoommates(_ roommates: [Onboarding.Contact])
    func registerContacts(_ contacts: [Onboarding.Contact])
    
    /// Finish the onboarding and handover the data to the [CaseManager](x-source-tag://CaseManaging).
    /// Contacts and roommates will be merged and any duplicates will be removed.
    /// After finishing, data will be reset and the `needsOnboardingFlag` will be set to `false`
    func finishOnboarding()
    
    func reset()
    
}
