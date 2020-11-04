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
    static var close: String { return Localization.string(for: "close") }
    static var next: String { return Localization.string(for: "next") }
    static var start: String { return Localization.string(for: "start") }
    static var edit: String { return Localization.string(for: "edit") }
    static var selectDate: String { return Localization.string(for: "selectDate") }
    static var done: String { return Localization.string(for: "done") }
    static var ok: String { return Localization.string(for: "ok") }
    static var errorTitle: String { return Localization.string(for: "error.title") }
    
    // MARK: - Update App

    static var updateAppErrorMessage: String { return Localization.string(for: "updateApp.error.message") }
    static var updateAppTitle: String { return Localization.string(for: "updateApp.title") }
    
    static var updateAppContent: String { return Localization.string(for: "updateApp.content") }
    static var updateAppButton: String { return Localization.string(for: "updateApp.button") }
    
    /* MARK: - Onboarding */
    static var onboardingStep1Title: String { return Localization.string(for: "onboarding.step1.title") }
    static var onboardingStep1Message: String { return Localization.string(for: "onboarding.step1.message") }
    static var onboardingStep2Title: String { return Localization.string(for: "onboarding.step2.title") }
    static var onboardingStep3Title: String { return Localization.string(for: "onboarding.step3.title") }
    static var onboardingStep3Message: String { return Localization.string(for: "onboarding.step3.message") }
    
    static var onboardingLoadingErrorTitle: String { return Localization.string(for: "onboardingLoadingErrorTitle") }
    static var onboardingLoadingErrorMessage: String { return Localization.string(for: "onboardingLoadingErrorMessage") }
    
    /* MARK: - Task Overview */
    static var taskOverviewTitle: String { return Localization.string(for: "taskOverviewTitle") }
    static var taskOverviewDoneButtonTitle: String { return Localization.string(for: "taskOverviewDoneButtonTitle") }
    static var taskOverviewAddContactButtonTitle: String { return Localization.string(for: "taskOverviewAddContactButtonTitle") }
    
    static var taskOverviewUninformedContactsHeaderTitle: String { return Localization.string(for: "taskOverviewUninformedContactsHeader.title") }
    static var taskOverviewUninformedContactsHeaderSubtitle: String { return Localization.string(for: "taskOverviewUninformedContactsHeader.subtitle") }
    static var taskOverviewInformedContactsHeaderTitle: String { return Localization.string(for: "taskOverviewInformedContactsHeader.title") }
    static var taskOverviewInformedContactsHeaderSubtitle: String { return Localization.string(for: "taskOverviewInformedContactsHeader.subtitle") }
    
    static var taskContactCaptionCompleted: String { return Localization.string(for: "task.contact.caption.completed") }
    static var taskContactCaptionIncomplete: String { return Localization.string(for: "task.contact.caption.incomplete") }
    
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
    
    static func informContactTitleIndex(firstName: String?) -> String {
        if let firstName = firstName {
            return Localization.string(for: "informContactTitle.index.knownName", [firstName, firstName])
        } else {
            return Localization.string(for: "informContactTitle.index.unknownName")
        }
    }
    
    static func informContactTitleStaff(firstName: String?) -> String {
        if let firstName = firstName {
            return Localization.string(for: "informContactTitle.staff.knownName", [firstName, firstName])
        } else {
            return Localization.string(for: "informContactTitle.staff.unknownName")
        }
    }
    
    static func informContactGuidelinesClose(untilDate: String, daysRemaining: String) -> String { return Localization.string(for: "informContactGuidelines.close", [untilDate, daysRemaining]) }
    static func informContactGuidelinesCloseUntilDate(date: String) -> String { return Localization.string(for: "informContactGuidelines.close.untilDate", [date]) }
    static var informContactGuidelinesCloseDateFormat: String { return Localization.string(for: "informContactGuidelines.close.dateFormat") }
    static var informContactGuidelinesCloseDayRemaining: String { return Localization.string(for: "informContactGuidelines.close.dayRemaining") }
    static func informContactGuidelinesCloseDaysRemaining(daysRemaining: String) -> String { return Localization.string(for: "informContactGuidelines.close.daysRemaining", [daysRemaining]) }
    static var informContactGuidelinesOther: String { return Localization.string(for: "informContactGuidelines.other") }
    
    static var informContactCopyGuidelines: String { return Localization.string(for: "informContactCopyGuidelines") }
    static var informContactCopyGuidelinesAction: String { return Localization.string(for: "informContactCopyGuidelinesAction") }
    
    static func informContactCall(firstName: String?) -> String {
        if let firstName = firstName {
            return Localization.string(for: "informContactCall.knownName", [firstName])
        } else {
            return Localization.string(for: "informContactCall.unknownName")
        }
    }
    
    static var category1RiskQuestion: String { return Localization.string(for: "category1RiskQuestion") }
    static var category1RiskQuestionAnswerPositive: String { return Localization.string(for: "category1RiskQuestion.answer.positive") }
    static var category1RiskQuestionAnswerNegative: String { return Localization.string(for: "category1RiskQuestion.answer.negative") }
    
    static var category2aRiskQuestion: String { return Localization.string(for: "category2aRiskQuestion") }
    static var category2aRiskQuestionAnswerPositive: String { return Localization.string(for: "category2aRiskQuestion.answer.positive") }
    static var category2aRiskQuestionAnswerNegative: String { return Localization.string(for: "category2aRiskQuestion.answer.negative") }
    
    static var category2bRiskQuestion: String { return Localization.string(for: "category2bRiskQuestion") }
    static var category2bRiskQuestionDescription: String { return Localization.string(for: "category2bRiskQuestion.description") }
    static var category2bRiskQuestionAnswerPositive: String { return Localization.string(for: "category2bRiskQuestion.answer.positive") }
    static var category2bRiskQuestionAnswerNegative: String { return Localization.string(for: "category2bRiskQuestion.answer.negative") }
    
    static var category3RiskQuestion: String { return Localization.string(for: "category3RiskQuestion") }
    static var category3RiskQuestionAnswerPositive: String { return Localization.string(for: "category3RiskQuestion.answer.positive") }
    static var category3RiskQuestionAnswerNegative: String { return Localization.string(for: "category3RiskQuestion.answer.negative") }
    
    static var otherCategoryTitle: String { return Localization.string(for: "otherCategoryTitle") }
    static var otherCategoryMessage: String { return Localization.string(for: "otherCategoryMessage") }
    
    static var contactFallbackTitle: String { return Localization.string(for: "contactFallbackTitle") }
    static var contactInformationFirstName: String { return Localization.string(for: "contactInformationFirstName") }
    static var contactInformationLastName: String { return Localization.string(for: "contactInformationLastName") }
    static var contactInformationPhoneNumber: String { return Localization.string(for: "contactInformationPhoneNumber") }
    static var contactInformationEmailAddress: String { return Localization.string(for: "contactInformationEmailAddress") }
    static var contactInformationBirthDate: String { return Localization.string(for: "contactInformationBirthDate") }
    static var contactInformationBSN: String { return Localization.string(for: "contactInformationBSN") }
    static var contactInformationLastExposure: String { return Localization.string(for: "contactInformationLastExposure") }
    static var contactInformationLastExposureEarlier: String { return Localization.string(for: "contactInformationLastExposure.earlier") }
    
    /* MARK: - Informing contacts */
    static var contactPromptNameFallback: String { return Localization.string(for: "contactPromptNameFallback") }
    
    static func contactInformPromptTitle(firstName: String) -> String { return Localization.string(for: "contactInformPromptTitle", [firstName]) }
    static var contactInformOptionDone: String { return Localization.string(for: "contactInformOptionDone") }
    static var contactInformActionInformLater: String { return Localization.string(for: "contactInformActionInformLater") }
    static var contactInformActionInformNow: String { return Localization.string(for: "contactInformActionInformNow") }
    
    static func contactMissingDetailsPromptTitle(firstName: String) -> String { return Localization.string(for: "contactMissingDetailsPromptTitle", [firstName]) }
    static var contactMissingDetailsPromptMessage: String { return Localization.string(for: "contactMissingDetailsPromptMessage") }
    static var contactMissingDetailsActionIgnore: String { return Localization.string(for: "contactMissingDetailsActionIgnore") }
    static var contactMissingDetailsActionFillIn: String { return Localization.string(for: "contactMissingDetailsActionFillIn") }
    
    /* MARK: - Uploading */
    static var unfinishedTasksOverviewTitle: String { return Localization.string(for: "unfinishedTasksOverviewTitle") }
    static var unfinishedTasksOverviewMessage: String { return Localization.string(for: "unfinishedTasksOverviewMessage") }
    
    static var unfinishedTaskOverviewIndexContactsHeaderTitle: String { return Localization.string(for: "unfinishedTaskOverviewIndexContactsHeader.title") }
    static var unfinishedTaskOverviewIndexContactsHeaderSubtitle: String { return Localization.string(for: "unfinishedTaskOverviewIndexContactsHeader.subtitle") }
    static var unfinishedTaskOverviewStaffContactsHeaderTitle: String { return Localization.string(for: "unfinishedTaskOverviewStaffContactsHeader.title") }
    static var unfinishedTaskOverviewStaffContactsHeaderSubtitle: String { return Localization.string(for: "unfinishedTaskOverviewStaffContactsHeader.subtitle") }
    
    static var uploadInProgressMessage: String { return Localization.string(for: "uploadInProgressMessage") }
    static var uploadFinishedTitle: String { return Localization.string(for: "uploadFinishedTitle") }
    static var uploadFinishedMessage: String { return Localization.string(for: "uploadFinishedMessage") }
    
}
