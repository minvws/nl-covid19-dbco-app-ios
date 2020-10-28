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
    static var edit: String { return Localization.string(for: "edit") }
    static var selectDate: String { return Localization.string(for: "selectDate") }
    static var done: String { return Localization.string(for: "done") }
    
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
    
    static var taskOverviewIndexContactsHeaderTitle: String { return Localization.string(for: "taskOverviewIndexContactsHeader.title") }
    static var taskOverviewIndexContactsHeaderSubtitle: String { return Localization.string(for: "taskOverviewIndexContactsHeader.subtitle") }
    static var taskOverviewStaffContactsHeaderTitle: String { return Localization.string(for: "taskOverviewStaffContactsHeader.title") }
    static var taskOverviewStaffContactsHeaderSubtitle: String { return Localization.string(for: "taskOverviewStaffContactsHeader.subtitle") }
    
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
    static var contactTypeSectionTitle: String { return Localization.string(for: "contactTypeSection.title") }
    static var contactTypeSectionMessage: String { return Localization.string(for: "contactTypeSection.message") }
    static var contactDetailsSectionTitle: String { return Localization.string(for: "contactDetailsSection.title") }
    static var contactDetailsSectionMessage: String { return Localization.string(for: "contactDetailsSection.message") }
    static var informContactSectionTitle: String { return Localization.string(for: "informContactSection.title") }
    static var informContactSectionMessageIndex: String { return Localization.string(for: "informContactSection.message.index") }
    static var informContactSectionMessageStaff: String { return Localization.string(for: "informContactSection.message.staff") }
    
    static var informContactTitleIndex: String { return Localization.string(for: "informContactTitle.index") }
    static var informContactTitleStaff: String { return Localization.string(for: "informContactTitle.staff") }
    
    static func informContactGuidelinesClose(untilDate: String, daysRemaining: String) -> String { return Localization.string(for: "informContactGuidelines.close", [untilDate, daysRemaining]) }
    static func informContactGuidelinesCloseUntilDate(date: String) -> String { return Localization.string(for: "informContactGuidelines.close.untilDate", [date]) }
    static var informContactGuidelinesCloseDateFormat: String { return Localization.string(for: "informContactGuidelines.close.dateFormat") }
    static var informContactGuidelinesCloseDayRemaining: String { return Localization.string(for: "informContactGuidelines.close.dayRemaining") }
    static func informContactGuidelinesCloseDaysRemaining(daysRemaining: String) -> String { return Localization.string(for: "informContactGuidelines.close.daysRemaining", [daysRemaining]) }
    static var informContactGuidelinesOther: String { return Localization.string(for: "informContactGuidelines.other") }
    static var informContactShareGuidelines: String { return Localization.string(for: "informContactShareGuidelines") }
    
    static var livedTogetherRiskQuestion: String { return Localization.string(for: "livedTogetherRiskQuestion") }
    static var livedTogetherRiskQuestionAnswerPositive: String { return Localization.string(for: "livedTogetherRiskQuestion.answer.positive") }
    static var livedTogetherRiskQuestionAnswerNegative: String { return Localization.string(for: "livedTogetherRiskQuestion.answer.negative") }
    
    static var durationRiskQuestion: String { return Localization.string(for: "durationRiskQuestion") }
    static var durationRiskQuestionAnswerPositive: String { return Localization.string(for: "durationRiskQuestion.answer.positive") }
    static var durationRiskQuestionAnswerNegative: String { return Localization.string(for: "durationRiskQuestion.answer.negative") }
    
    static var distanceRiskQuestion: String { return Localization.string(for: "distanceRiskQuestion") }
    static var distanceRiskQuestionAnswerPositive: String { return Localization.string(for: "distanceRiskQuestion.answer.positive") }
    static var distanceRiskQuestionAnswerNegative: String { return Localization.string(for: "distanceRiskQuestion.answer.negative") }
    
    static var otherRiskQuestion: String { return Localization.string(for: "otherRiskQuestion") }
    static var otherRiskQuestionDescription: String { return Localization.string(for: "otherRiskQuestion.description") }
    static var otherRiskQuestionAnswerPositive: String { return Localization.string(for: "otherRiskQuestion.answer.positive") }
    static var otherRiskQuestionAnswerNegative: String { return Localization.string(for: "otherRiskQuestion.answer.negative") }
    
    static var contactFallbackTitle: String { return Localization.string(for: "contactFallbackTitle") }
    static var contactInformationFirstName: String { return Localization.string(for: "contactInformationFirstName") }
    static var contactInformationLastName: String { return Localization.string(for: "contactInformationLastName") }
    static var contactInformationPhoneNumber: String { return Localization.string(for: "contactInformationPhoneNumber") }
    static var contactInformationEmailAddress: String { return Localization.string(for: "contactInformationEmailAddress") }
    static var contactInformationBirthDate: String { return Localization.string(for: "contactInformationBirthDate") }
    static var contactInformationBSN: String { return Localization.string(for: "contactInformationBSN") }
    static var contactInformationLastExposure: String { return Localization.string(for: "contactInformationLastExposure") }
    
    /* MARK: - Informing contacts */
    static func contactInformPromptTitle(firstName: String) -> String { return Localization.string(for: "contactInformPromptTitle", [firstName]) }
    static var contantInformOptionDone: String { return Localization.string(for: "contantInformOptionDone") }
    static var contantInformOptionInformLater: String { return Localization.string(for: "contantInformOptionInformLater") }
    static var contantInformOptionInformNow: String { return Localization.string(for: "contantInformOptionInformNow") }
    
    /* MARK: - Uploading */
    static var unfinishedTasksOverviewTitle: String { return Localization.string(for: "unfinishedTasksOverviewTitle") }
    static var unfinishedTasksOverviewMessage: String { return Localization.string(for: "unfinishedTasksOverviewMessage") }
    static var uploadInProgressMessage: String { return Localization.string(for: "uploadInProgressMessage") }
    static var uploadFinishedTitle: String { return Localization.string(for: "uploadFinishedTitle") }
    static var uploadFinishedMessage: String { return Localization.string(for: "uploadFinishedMessage") }
    
}
