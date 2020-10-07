/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import UIKit

public final class Localization {

    /// Get the Localized string for the current bundle.
    /// If the key has not been localized this will fallback to the Base project strings
    public static func string(for key: String, comment: String = "", _ arguments: [CVarArg] = []) -> String {
        let value = NSLocalizedString(key, bundle: Bundle(for: Localization.self), comment: comment)
        guard value == key else {
            return (arguments.count > 0) ? String(format: value, arguments: arguments) : value
        }
        guard
            let path = Bundle(for: Localization.self).path(forResource: "Base", ofType: "lproj"),
            let bundle = Bundle(path: path) else {
            return (arguments.count > 0) ? String(format: value, arguments: arguments) : value
        }
        let localizedString = NSLocalizedString(key, bundle: bundle, comment: "")
        return (arguments.count > 0) ? String(format: localizedString, arguments: arguments) : localizedString
    }

    public static func attributedString(for key: String, comment: String = "", _ arguments: [CVarArg] = []) -> NSMutableAttributedString {
        return NSMutableAttributedString(string: string(for: key, arguments))
    }

    public static func attributedStrings(for key: String, comment: String = "", _ arguments: [CVarArg] = []) -> [NSMutableAttributedString] {
        let value = string(for: key, arguments)
        let paragraph = "\n\n"
        let strings = value.components(separatedBy: paragraph)

        return strings.enumerated().map { (index, element) -> NSMutableAttributedString in
            let value = index < strings.count - 1 ? element + "\n" : element
            return NSMutableAttributedString(string: value)
        }
    }

    public static var isRTL: Bool { return UIApplication.shared.userInterfaceLayoutDirection == UIUserInterfaceLayoutDirection.rightToLeft }
}

extension String {
    // MARK: - App Version
    static func appVersionTitle(_ version: String, _ build: String) -> String { return Localization.string(for: "appVersionTitle", [version, build]) }
    
    /* MARK: - General */
    static var save: String { return Localization.string(for: "save") }
    static var cancel: String { return Localization.string(for: "cancel") }
    static var next: String { return Localization.string(for: "next") }
    static var start: String { return Localization.string(for: "start") }
    
    /* MARK: - Onboarding */
    static var onboardingStep1Title: String { return Localization.string(for: "onboarding.step1.title") }
    static var onboardingStep1Message: String { return Localization.string(for: "onboarding.step1.message") }
    static var onboardingStep2Title: String { return Localization.string(for: "onboarding.step2.title") }
    static var onboardingStep3Title: String { return Localization.string(for: "onboarding.step3.title") }
    static var onboardingStep3Message: String { return Localization.string(for: "onboarding.step3.message") }
    
    /* MARK: - Task Overview */
    static var taskOverviewTitle: String { return Localization.string(for: "taskOverviewTitle") }
    static var taskOverviewHeaderText: String { return Localization.string(for: "taskOverviewHeaderText") }
    static var taskOverviewDoneButtonTitle: String { return Localization.string(for: "taskOverviewDoneButtonTitle") }
    static var taskOverviewAddContactButtonTitle: String { return Localization.string(for: "taskOverviewAddContactButtonTitle") }
    static var taskContactCaptionCompleted: String { return Localization.string(for: "task.contact.caption.completed") }
    static var taskContactCaptionIncomplete: String { return Localization.string(for: "task.contact.caption.incomplete") }
    
    // MARK: - Request Contacts Permission
    static var requestPermissionContactsTitle: String { return Localization.string(for: "requestPermssion.contacts.title") }
    static var requestPermissionContactsBody: String { return Localization.string(for: "requestPermssion.contacts.body") }
    static var requestPermissionContactsBodyDenied: String { return Localization.string(for: "requestPermssion.contacts.body.denied") }
    static var requestPermissionContactsAllowButtonTitle: String { return Localization.string(for: "requestPermssion.contacts.allowButtonTitle") }
    static var requestPermissionContactsContinueButtonTitle: String { return Localization.string(for: "requestPermssion.contacts.continueButtonTitle") }
    static var requestPermissionContactsSettingsButtonTitle: String { return Localization.string(for: "requestPermssion.contacts.settingsButtonTitle") }
    
    // MARK: - Contact Selection
    static var selectContactTitle: String { return Localization.string(for: "selectContactTitle") }
    static var selectContactSearch: String { return Localization.string(for: "selectContactSearch") }
    static var selectContactAddManually: String { return Localization.string(for: "selectContactAddManually") }
    static var selectContactSuggestions: String { return Localization.string(for: "selectContactSuggestions") }
    static var selectContactOtherContacts: String { return Localization.string(for: "selectContactOtherContacts") }
    static var selectContactFromContactsFallback: String { return Localization.string(for: "selectContactFromContactsFallback") }
    static var selectContactAddManuallyFallback: String { return Localization.string(for: "selectContactAddManuallyFallback") }
    
    // MARK: - Editing Contacts
    static var contactFallbackTitle: String { return Localization.string(for: "contactFallbackTitle") }
    static var contactInformationFirstName: String { return Localization.string(for: "contactInformationFirstName") }
    static var contactInformationLastName: String { return Localization.string(for: "contactInformationLastName") }
    static var contactInformationPhoneNumber: String { return Localization.string(for: "contactInformationPhoneNumber") }
    static var contactInformationEmailAddress: String { return Localization.string(for: "contactInformationEmailAddress") }
    static var contactInformationRelationType: String { return Localization.string(for: "contactInformationRelationType") }
    static var contactInformationBirthDate: String { return Localization.string(for: "contactInformationBirthDate") }
    static var contactInformationBSN: String { return Localization.string(for: "contactInformationBSN") }
    static var contactInformationProfession: String { return Localization.string(for: "contactInformationProfession") }
    static var contactInformationCompanyName: String { return Localization.string(for: "contactInformationCompanyName") }
    static var contactInformationNotes: String { return Localization.string(for: "contactInformationNotes") }
    
    // MARK: - Help
    
    static var helpTitle: String { return Localization.string(for: "helpTitle") }
    static var helpSubtitle: String { return Localization.string(for: "helpSubtitle") }
    static var helpAlsoRead: String { return Localization.string(for: "helpAlsoRead") }

    static var helpFaqReasonTitle: String { return Localization.string(for: "help.faq.reason.title") }
    static var helpFaqReasonDescription: String { return Localization.string(for: "help.faq.reason.description") }
    static var helpFaqLocationTitle: String { return Localization.string(for: "help.faq.location.title") }
    static var helpFaqLocationDescription: String { return Localization.string(for: "help.faq.location.description") }
    static var helpFaqAnonymousTitle: String { return Localization.string(for: "help.faq.anonymous.title") }
    static var helpFaqAnonymousDescription1: String { return Localization.string(for: "help.faq.anonymous.description_1") }
    static var helpFaqAnonymousDescription2: String { return Localization.string(for: "help.faq.anonymous.description_2") }
    static var helpFaqNotificationTitle: String { return Localization.string(for: "help.faq.notification.title") }
    static var helpFaqNotificationDescription: String { return Localization.string(for: "help.faq.notification.description") }
    static var helpFaqBluetoothTitle: String { return Localization.string(for: "help.faq.bluetooth.title") }
    static var helpFaqBluetoothDescription: String { return Localization.string(for: "help.faq.bluetooth.description") }
    static var helpFaqPowerUsageTitle: String { return Localization.string(for: "help.faq.power_usage.title") }
    static var helpFaqPowerUsageDescription: String { return Localization.string(for: "help.faq.power_usage.description") }
    
}
