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
            return !arguments.isEmpty ? String(format: value, arguments: arguments) : value
        }
        guard
            let path = Bundle(for: Localization.self).path(forResource: "Base", ofType: "lproj"),
            let bundle = Bundle(path: path) else {
            return !arguments.isEmpty ? String(format: value, arguments: arguments) : value
        }
        let localizedString = NSLocalizedString(key, bundle: bundle, comment: "")
        return !arguments.isEmpty ? String(format: localizedString, arguments: arguments) : localizedString
    }

    public static func attributedString(for key: String, comment: String = "", _ arguments: [CVarArg] = []) -> NSMutableAttributedString {
        return NSMutableAttributedString(string: string(for: key, arguments))
    }

    public static func attributedStrings(for key: String, comment: String = "", _ arguments: [CVarArg] = []) -> [NSMutableAttributedString] {
        let value = string(for: key, arguments)
        let paragraph = "\n\n"
        let strings = value.components(separatedBy: paragraph)

        return strings.enumerated().map { index, element -> NSMutableAttributedString in
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
    static var yes: String { return Localization.string(for: "yes") }
    static var no: String { return Localization.string(for: "no") }
    static var save: String { return Localization.string(for: "save") }
    static var cancel: String { return Localization.string(for: "cancel") }
    static var close: String { return Localization.string(for: "close") }
    static var next: String { return Localization.string(for: "next") }
    static var start: String { return Localization.string(for: "start") }
    static var edit: String { return Localization.string(for: "edit") }
    static var selectDate: String { return Localization.string(for: "selectDate") }
    static var done: String { return Localization.string(for: "done") }
    static var ok: String { return Localization.string(for: "ok") }
    static var tryAgain: String { return Localization.string(for: "tryAgain") }
    static var back: String { return Localization.string(for: "back") }
    static var delete: String { return Localization.string(for: "delete") }
    static var errorTitle: String { return Localization.string(for: "error.title") }
    static var other: String { return Localization.string(for: "other") }
    static var collapsed: String { return Localization.string(for: "collapsed") }
    static var expanded: String { return Localization.string(for: "expanded") }
    static var completed: String { return Localization.string(for: "completed") }
    static var disabled: String { return Localization.string(for: "disabled") }
    static var loading: String { return Localization.string(for: "loading") }
    
    // MARK: - Update App
    static var updateAppErrorMessage: String { return Localization.string(for: "updateApp.error.message") }
    static var updateAppTitle: String { return Localization.string(for: "updateApp.title") }
    
    static var updateAppContent: String { return Localization.string(for: "updateApp.content") }
    static var updateAppButton: String { return Localization.string(for: "updateApp.button") }
    
    /* MARK: - Onboarding */
    static var onboardingStartTitle: String { return Localization.string(for: "onboarding.start.title") }
    static var onboardingStartMessage: String { return Localization.string(for: "onboarding.start.message") }
    static var onboardingStartHasCodeButton: String { return Localization.string(for: "onboarding.start.hasCodeButton") }
    static var onboardingStartNoCodeButton: String { return Localization.string(for: "onboarding.start.noCodeButton") }
    static var onboardingPairingIntroTitle: String { return Localization.string(for: "onboarding.pairingIntro.title") }
    static var onboardingPairingIntroMessage: String { return Localization.string(for: "onboarding.pairingIntro.message") }
    static var onboardingPairingTitle: String { return Localization.string(for: "onboarding.pairing.title") }
    static var onboardingPairingCodeHint: String { return Localization.string(for: "onboarding.pairing.codeHint") }
    
    /* MARK: - Privacy */
    static var onboardingConsentShortTitle: String { return Localization.string(for: "onboarding.consent.shortTitle") }
    static var onboardingConsentTitle: String { return Localization.string(for: "onboarding.consent.title") }
    static var onboardingConsentMessage: String { return Localization.string(for: "onboarding.consent.message") }
    static var onboardingConsentItem1: String { return Localization.string(for: "onboarding.consent.item1") }
    static var onboardingConsentItem2: String { return Localization.string(for: "onboarding.consent.item2") }
    static var onboardingConsentItem3: String { return Localization.string(for: "onboarding.consent.item3") }
    static var onboardingConsentItem4: String { return Localization.string(for: "onboarding.consent.item4") }
    static var onboardingConsentButtonTitle: String { return Localization.string(for: "onboarding.consent.buttonTitle") }
    
    /* MARK: - Onboarding Error */
    static var onboardingLoadingErrorTitle: String { return Localization.string(for: "onboardingLoadingErrorTitle") }
    static var onboardingLoadingErrorMessage: String { return Localization.string(for: "onboardingLoadingErrorMessage") }
    static var onboardingLoadingErrorCancelAction: String { return Localization.string(for: "onboardingLoadingErrorCancelAction") }
    static var onboardingLoadingErrorRetryAction: String { return Localization.string(for: "onboardingLoadingErrorRetryAction") }
    
    /* MARK: - Contagious Period */
    static var contagiousPeriodSelectSymptomsShortTitle: String { return Localization.string(for: "contagiousPeriodSelectSymptoms.shortTitle") }
    static var contagiousPeriodSelectSymptomsTitle: String { return Localization.string(for: "contagiousPeriodSelectSymptoms.title") }
    static var contagiousPeriodSelectSymptomsMessage: String { return Localization.string(for: "contagiousPeriodSelectSymptoms.message") }
    
    static var contagiousPeriodAllSymptomsButton: String { return Localization.string(for: "contagiousPeriodAllSymptomsButton") }
    static var contagiousPeriodNoSymptomsButton: String { return Localization.string(for: "contagiousPeriodNoSymptomsButton") }
    
    static var contagiousPeriodSelectTestDateTitle: String { return Localization.string(for: "contagiousPeriodSelectTestDate.title") }
    static var contagiousPeriodSelectTestDateMessage: String { return Localization.string(for: "contagiousPeriodSelectTestDate.message") }
    
    static var contagiousPeriodSelectOnsetDateTitle: String { return Localization.string(for: "contagiousPeriodSelectOnsetDate.title") }
    static var contagiousPeriodSelectOnsetDateMessage: String { return Localization.string(for: "contagiousPeriodSelectOnsetDate.message") }
    static var contagiousPeriodSelectOnsetDateHelpButtonTitle: String { return Localization.string(for: "contagiousPeriodSelectOnsetDate.helpButtonTitle") }
    
    static var contagiousPeriodNoSymptomsVerifyTitle: String { return Localization.string(for: "contagiousPeriodNoSymptomsVerify.title") }
    static var contagiousPeriodNoSymptomsVerifyMessage: String { return Localization.string(for: "contagiousPeriodNoSymptomsVerify.message") }
    static var contagiousPeriodNoSymptomsVerifyConfirmButton: String { return Localization.string(for: "contagiousPeriodNoSymptomsVerify.confirmButton") }
    static var contagiousPeriodNoSymptomsVerifyCancelButton: String { return Localization.string(for: "contagiousPeriodNoSymptomsVerify.cancelButton") }
    
    static var contagiousPeriodOnsetDateVerifyDateFormat: String { return Localization.string(for: "contagiousPeriodOnsetDateVerify.dateFormat") }
    
    static func contagiousPeriodOnsetDateVerifyTitle(date: String) -> String { return Localization.string(for: "contagiousPeriodOnsetDateVerify.title", [date]) }
    
    static var contagiousPeriodOnsetDateVerifyMessage: String { return Localization.string(for: "contagiousPeriodOnsetDateVerify.message") }
    static var contagiousPeriodOnsetDateVerifyConfirmButton: String { return Localization.string(for: "contagiousPeriodOnsetDateVerify.confirmButton") }
    static var contagiousPeriodOnsetDateVerifyCancelButton: String { return Localization.string(for: "contagiousPeriodOnsetDateVerify.cancelButton") }
    
    /* MARK: - Determine contacts */
    static var onboardingDetermineContactsIntroTitle: String { return Localization.string(for: "onboardingDetermineContactsIntro.title") }
    static var onboardingDetermineContactsIntroMessage: String { return Localization.string(for: "onboardingDetermineContactsIntro.message") }
    
    static var determineContactsAuthorizationTitle: String { return Localization.string(for: "determineContactsAuthorization.title") }
    static var determineContactsAuthorizationMessage: String { return Localization.string(for: "determineContactsAuthorization.message") }
    static var determineContactsAuthorizationAllowButton: String { return Localization.string(for: "determineContactsAuthorization.allowButton") }
    static var determineContactsAuthorizationAddManuallyButton: String { return Localization.string(for: "determineContactsAuthorization.addManuallyButton") }
    
    static var determineRoommatesShortTitle: String { return Localization.string(for: "determineRoommates.shortTitle") }
    static var determineRoommatesTitle: String { return Localization.string(for: "determineRoommates.title") }
    static var determineRoommatesMessage: String { return Localization.string(for: "determineRoommates.message") }
    static var determineRoommatesAddContact: String { return Localization.string(for: "determineRoommatesAddContact") }
    static var determineRoommatesNoContactsButtonTitle: String { return Localization.string(for: "determineRoommatesNoContactsButtonTitle") }
    
    static var determineContactsExplanationShortTitle: String { return Localization.string(for: "determineContactsExplanation.shortTitle") }
    static var determineContactsExplanationTitle: String { return Localization.string(for: "determineContactsExplanation.title") }
    static var determineContactsExplanationMessage: String { return Localization.string(for: "determineContactsExplanation.message") }
    static var determineContactsExplanationItem1: String { return Localization.string(for: "determineContactsExplanation.item.1") }
    static var determineContactsExplanationItem2: String { return Localization.string(for: "determineContactsExplanation.item.2") }
    static var determineContactsExplanationItem3: String { return Localization.string(for: "determineContactsExplanation.item.3") }
    static var determineContactsExplanationItem4: String { return Localization.string(for: "determineContactsExplanation.item.4") }
    
    /* MARK: - Onboarding Contacts Timeline */
    static var contactsTimelineDateFormat: String { return Localization.string(for: "contactsTimeline.dateFormat") }
    static var contactsTimelineShortDateFormat: String { return Localization.string(for: "contactsTimeline.shortDateFormat") }
    static var contactsTimelineShortTitle: String { return Localization.string(for: "contactsTimeline.shortTitle") }
    
    static func contactsTimelineTitle(endDate: String) -> String { return Localization.string(for: "contactsTimeline.title", [endDate]) }
    
    static var contactsTimelineMessage: String { return Localization.string(for: "contactsTimeline.message") }
    
    static var contactsTimelineAddContact: String { return Localization.string(for: "contactsTimelineAddContact") }
    
    static var contactsTimelineSectionTitleTodayFormat: String { return Localization.string(for: "contactsTimelineSectionTitle.todayFormat") }
    static var contactsTimelineSectionTitleYesterdayFormat: String { return Localization.string(for: "contactsTimelineSectionTitle.yesterdayFormat") }
    static var contactsTimelineSectionTitle2DaysAgoFormat: String { return Localization.string(for: "contactsTimelineSectionTitle.2daysAgoFormat") }
    
    static var contactsTimelineSectionSubtitleSymptomOnset: String { return Localization.string(for: "contactsTimelineSectionSubtitle.symptomOnset") }
    static var contactsTimelineSectionSubtitleBeforeOnset: String { return Localization.string(for: "contactsTimelineSectionSubtitle.beforeOnset") }
    static var contactsTimelineSectionSubtitleTestDate: String { return Localization.string(for: "contactsTimelineSectionSubtitle.testDate") }
    
    static func contactsTimelineAddExtraDayTitle(endDate: String) -> String { return Localization.string(for: "contactsTimelineAddExtraDay.title", [endDate]) }
    
    static var contactsTimelineAddExtraDayButton: String { return Localization.string(for: "contactsTimelineAddExtraDay.button") }
    
    static var contactsTimelineEmptyDaysTitle: String { return Localization.string(for: "contactsTimelineEmptyDays.title") }
    
    static func contactsTimelineEmptyDaysMessage(days: String) -> String { return Localization.string(for: "contactsTimelineEmptyDays.message", [days]) }
    
    static var contactsTimelineEmptyDaysSeparator: String { return Localization.string(for: "contactsTimelineEmptyDays.separator") }
    static var contactsTimelineEmptyDaysFinalSeparator: String { return Localization.string(for: "contactsTimelineEmptyDays.finalSeparator") }
    static var contactsTimelineEmptyDaysBackButton: String { return Localization.string(for: "contactsTimelineEmptyDays.backButton") }
    static var contactsTimelineEmptyDaysContinueButton: String { return Localization.string(for: "contactsTimelineEmptyDays.continueButton") }
    
    static var contactsTimelineTip: String { return Localization.string(for: "contactsTimelineTip") }
    
    static var contactsTimelineReviewTipTitle: String { return Localization.string(for: "contactsTimelineReviewTip.title") }
    static var contactsTimelineReviewTipPhotos: String { return Localization.string(for: "contactsTimelineReviewTip.photos") }
    static var contactsTimelineReviewTipCalendar: String { return Localization.string(for: "contactsTimelineReviewTip.calendar") }
    static var contactsTimelineReviewTipSocialMedia: String { return Localization.string(for: "contactsTimelineReviewTip.socialMedia") }
    static var contactsTimelineReviewTipTransactions: String { return Localization.string(for: "contactsTimelineReviewTip.transactions") }
    
    static var contactsTimelineActivityTipTitle: String { return Localization.string(for: "contactsTimelineActivityTip.title") }
    static var contactsTimelineActivityTipCar: String { return Localization.string(for: "contactsTimelineActivityTip.car") }
    static var contactsTimelineActivityTipMeetings: String { return Localization.string(for: "contactsTimelineActivityTip.meetings") }
    static var contactsTimelineActivityTipConversations: String { return Localization.string(for: "contactsTimelineActivityTip.conversations") }
    
    /* MARK: - Task Overview */
    static var taskOverviewTipsTitle: String { return Localization.string(for: "taskOverviewTipsTitle") }
    static var taskOverviewTipsDateFormat: String { return Localization.string(for: "taskOverviewTipsDateFormat") }
    
    static func taskOverviewTipsMessage(date: String) -> String { return Localization.string(for: "taskOverviewTipsMessage", [date]) }
    
    static var taskOverviewTipsButton: String { return Localization.string(for: "taskOverviewTipsButton") }
    
    static var taskOverviewTitle: String { return Localization.string(for: "taskOverviewTitle") }
    static var taskOverviewDoneButtonTitle: String { return Localization.string(for: "taskOverviewDoneButtonTitle") }
    static var taskOverviewDeleteDataButtonTitle: String { return Localization.string(for: "taskOverviewDeleteDataButtonTitle") }
    static var taskOverviewAddContactButtonTitle: String { return Localization.string(for: "taskOverviewAddContactButtonTitle") }
    
    static var taskOverviewUnsyncedContactsHeader: String { return Localization.string(for: "taskOverviewUnsyncedContactsHeader") }
    static var taskOverviewSyncedContactsHeader: String { return Localization.string(for: "taskOverviewSyncedContactsHeader") }
    
    static var taskContactUnknownName: String { return Localization.string(for: "taskContactUnknownName") }
    
    static var taskLoadingErrorTitle: String { return Localization.string(for: "taskLoadingErrorTitle") }
    static var taskLoadingErrorMessage: String { return Localization.string(for: "taskLoadingErrorMessage") }
    
    static var deleteDataPromptTitle: String { return Localization.string(for: "deleteDataPromptTitle") }
    static var deleteDataPromptMessage: String { return Localization.string(for: "deleteDataPromptMessage") }
    static var deleteDataPromptOptionCancel: String { return Localization.string(for: "deleteDataPromptOptionCancel") }
    static var deleteDataPromptOptionDelete: String { return Localization.string(for: "deleteDataPromptOptionDelete") }
    
    static var windowExpiredMessage: String { return Localization.string(for: "windowExpiredMessage") }
    
    static var contactTaskStatusStaffWillInform: String { return Localization.string(for: "contactTaskStatusStaffWillInform") }
    static var contactTaskStatusIndexDidInform: String { return Localization.string(for: "contactTaskStatusIndexDidInform") }
    static var contactTaskStatusIndexWillInform: String { return Localization.string(for: "contactTaskStatusIndexWillInform") }
    static var contactTaskStatusMissingDetails: String { return Localization.string(for: "contactTaskStatusMissingDetails") }
    
    static var taskOverviewWaitingForPairing: String { return Localization.string(for: "taskOverviewWaitingForPairing") }
    static var taskOverviewPairingTryAgain: String { return Localization.string(for: "taskOverviewPairingTryAgain") }
    
    /* MARK: - Overview Tips */
    static var overviewTipsShortTitle: String { return Localization.string(for: "overviewTipsShortTitle") }
    static var overviewTipsTitleTodayOnly: String { return Localization.string(for: "overviewTipsTitleTodayOnly") }
    
    static func overviewTipsTitle(date: String) -> String { return Localization.string(for: "overviewTipsTitle", [date]) }
    
    static var overviewTipsTitleDateFormat: String { return Localization.string(for: "overviewTipsTitleDateFormat") }
    static var overviewTipsMessage: String { return Localization.string(for: "overviewTipsMessage") }
    
    static var overviewTipsSection1Title: String { return Localization.string(for: "overviewTipsSection1.title") }
    static var overviewTipsSection1Intro: String { return Localization.string(for: "overviewTipsSection1.intro") }
    static var overviewTipsSection1Photos: String { return Localization.string(for: "overviewTipsSection1.photos") }
    static var overviewTipsSection1SocialMedia: String { return Localization.string(for: "overviewTipsSection1.socialMedia") }
    static var overviewTipsSection1Calendar: String { return Localization.string(for: "overviewTipsSection1.calendar") }
    static var overviewTipsSection1Transactions: String { return Localization.string(for: "overviewTipsSection1.transactions") }
    static var overviewTipsSection1ActivitiesIntro: String { return Localization.string(for: "overviewTipsSection1.activitiesIntro") }
    static var overviewTipsSection1Car: String { return Localization.string(for: "overviewTipsSection1.car") }
    static var overviewTipsSection1Meetings: String { return Localization.string(for: "overviewTipsSection1.meetings") }
    static var overviewTipsSection1Conversations: String { return Localization.string(for: "overviewTipsSection1.conversations") }
    
    static var overviewTipsSection2Title: String { return Localization.string(for: "overviewTipsSection2.title") }
    static var overviewTipsSection2Intro: String { return Localization.string(for: "overviewTipsSection2.intro") }
    static var overviewTipsSection2Item1: String { return Localization.string(for: "overviewTipsSection2.item1") }
    static var overviewTipsSection2Item2: String { return Localization.string(for: "overviewTipsSection2.item2") }
    static var overviewTipsSection2Item3: String { return Localization.string(for: "overviewTipsSection2.item3") }
    
    // MARK: - Contact Selection
    static var selectContactTitle: String { return Localization.string(for: "selectContactTitle") }
    static var selectContactSearch: String { return Localization.string(for: "selectContactSearch") }
    static var selectContactAddManually: String { return Localization.string(for: "selectContactAddManually") }
    static var selectContactSuggestions: String { return Localization.string(for: "selectContactSuggestions") }
    static var selectContactOtherContacts: String { return Localization.string(for: "selectContactOtherContacts") }
    static var selectContactFromContactsFallback: String { return Localization.string(for: "selectContactFromContactsFallback") }
    static var selectContactAddManuallyFallback: String { return Localization.string(for: "selectContactAddManuallyFallback") }
    
    static func selectContactAuthorizationTitle(name: String) -> String { return Localization.string(for: "selectContactAuthorizationTitle", [name]) }
    
    static var selectContactAuthorizationFallbackTitle: String { return Localization.string(for: "selectContactAuthorizationFallbackTitle") }
    
    static var selectContactAuthorizationMessage: String { return Localization.string(for: "selectContactAuthorizationMessage") }
    static var selectContactAuthorizationItem1: String { return Localization.string(for: "selectContactAuthorization.item1") }
    static var selectContactAuthorizationItem2: String { return Localization.string(for: "selectContactAuthorization.item2") }
    static var selectContactAuthorizationItem3: String { return Localization.string(for: "selectContactAuthorization.item3") }
    static var selectContactAuthorizationAllowButton: String { return Localization.string(for: "selectContactAuthorizationAllowButton") }
    static var selectContactAuthorizationManualButton: String { return Localization.string(for: "selectContactAuthorizationManualButton") }
    
    // MARK: - Editing Contacts
    static func contactSectionLabel(index: Int, title: String, caption: String, isCollapsed: Bool, isCompleted: Bool, isEnabled: Bool) -> String {
        let status = !isEnabled ? disabled : isCompleted ? completed : isCollapsed ? collapsed : expanded
        return Localization.string(for: "contactSection.label", [status, index, title, caption])
    }
    
    static func contactSectionCompleted(index: Int) -> String {
        return Localization.string(for: "contactSection.completed", [index])
    }
    
    static var contactTypeSectionTitle: String { return Localization.string(for: "contactTypeSection.title") }
    static var contactTypeSectionMessage: String { return Localization.string(for: "contactTypeSection.message") }
        
    static var contactDetailsSectionTitle: String { return Localization.string(for: "contactDetailsSection.title") }
    static var contactDetailsSectionMessage: String { return Localization.string(for: "contactDetailsSection.message") }
    
    static var informContactSectionTitle: String { return Localization.string(for: "informContactSection.title") }
    static var informContactSectionMessage: String { return Localization.string(for: "informContactSection.message") }
    
    static func informContactTitle(firstName: String?) -> String {
        let firstName = firstName ?? .contactPromptNameFallback
        return Localization.string(for: "informContactTitle", [firstName])
    }
    
    static func informContactFooterIndex(firstName: String?) -> String {
        let firstName = firstName ?? .contactPromptNameFallback
        return Localization.string(for: "informContactFooter.index", [firstName])
    }
    
    static func informContactFooterStaff(firstName: String?) -> String {
        let firstName = firstName ?? .contactPromptNameFallback
        return Localization.string(for: "informContactFooter.staff", [firstName])
    }
    
    static func informContactFooterUnknown(firstName: String?) -> String {
        let firstName = firstName ?? .contactPromptNameFallback
        return Localization.string(for: "informContactFooter.unknown", [firstName])
    }
    
    static var informContactGuidelinesDateFormat: String { return Localization.string(for: "informContactGuidelines.dateFormat") }
    
    static func informContactGuidelines(category: Task.Contact.Category, exposureDatePlus5: String, exposureDatePlus10: String, exposureDatePlus11: String, exposureDatePlus14: String) -> String {
        switch category {
        case .category1:
            return Localization.string(for: "informContactGuidelines.category1", [exposureDatePlus11])
        case .category2a, .category2b:
            return Localization.string(for: "informContactGuidelines.category2", [exposureDatePlus5, exposureDatePlus10])
        case .category3a, .category3b:
            return Localization.string(for: "informContactGuidelines.category3", [exposureDatePlus14])
        default:
            return ""
        }
    }
    
    static func informContactGuidelinesIntro(category: Task.Contact.Category, exposureDate: String) -> String {
        switch category {
        case .category1:
            return Localization.string(for: "informContactGuidelines.category1.intro")
        case .category2a, .category2b:
            return Localization.string(for: "informContactGuidelines.category2.intro", [exposureDate])
        case .category3a, .category3b:
            return Localization.string(for: "informContactGuidelines.category3.intro", [exposureDate])
        default:
            return ""
        }
    }
    
    static func informContactGuidelinesGeneric(category: Task.Contact.Category) -> String {
        switch category {
        case .category1:
            return Localization.string(for: "informContactGuidelines.generic.category1")
        case .category2a, .category2b:
            return Localization.string(for: "informContactGuidelines.generic.category2")
        case .category3a, .category3b:
            return Localization.string(for: "informContactGuidelines.generic.category3")
        default:
            return ""
        }
    }
    
    static func informContactGuidelinesIntroGeneric(category: Task.Contact.Category) -> String {
        switch category {
        case .category1:
            return Localization.string(for: "informContactGuidelines.generic.category1.intro")
        case .category2a, .category2b:
            return Localization.string(for: "informContactGuidelines.generic.category2.intro")
        case .category3a, .category3b:
            return Localization.string(for: "informContactGuidelines.generic.category3.intro")
        default:
            return ""
        }
    }
    
    static func informContactLink(category: Task.Contact.Category) -> String {
        switch category {
        case .category1:
            return Localization.string(for: "informContactLink.category1")
        case .category2a:
            return Localization.string(for: "informContactLink.category2a")
        case .category2b:
            return Localization.string(for: "informContactLink.category2b")
        case .category3a, .category3b:
            return Localization.string(for: "informContactLink.category3")
        default:
            return ""
        }
    }
    
    static var informContactCopyGuidelines: String { return Localization.string(for: "informContactCopyGuidelines") }
    static var informContactCopyGuidelinesAction: String { return Localization.string(for: "informContactCopyGuidelinesAction") }
    
    static func informContactCall(firstName: String?) -> String {
        if let firstName = firstName {
            return Localization.string(for: "informContactCall.knownName", [firstName])
        } else {
            return Localization.string(for: "informContactCall.unknownName")
        }
    }
    
    static var sameHouseholdRiskQuestion: String { return Localization.string(for: "sameHouseholdRiskQuestion") }
    static var sameHouseholdRiskQuestionAnswerPositive: String { return Localization.string(for: "sameHouseholdRiskQuestion.answer.positive") }
    static var sameHouseholdRiskQuestionAnswerNegative: String { return Localization.string(for: "sameHouseholdRiskQuestion.answer.negative") }
    
    static var distanceRiskQuestion: String { return Localization.string(for: "distanceRiskQuestion") }
    static var distanceRiskQuestionAnswerMoreThan15Min: String { return Localization.string(for: "distanceRiskQuestion.answer.moreThan15Min") }
    static var distanceRiskQuestionAnswerLessThan15Min: String { return Localization.string(for: "distanceRiskQuestion.answer.lessThan15Min") }
    static var distanceRiskQuestionAnswerNegative: String { return Localization.string(for: "distanceRiskQuestion.answer.negative") }
    
    static var physicalContactRiskQuestion: String { return Localization.string(for: "physicalContactRiskQuestion") }
    static var physicalContactRiskQuestionDescription: String { return Localization.string(for: "physicalContactRiskQuestion.description") }
    static var physicalContactRiskQuestionAnswerPositive: String { return Localization.string(for: "physicalContactRiskQuestion.answer.positive") }
    static var physicalContactRiskQuestionAnswerNegative: String { return Localization.string(for: "physicalContactRiskQuestion.answer.negative") }
    
    static var sameRoomRiskQuestion: String { return Localization.string(for: "sameRoomRiskQuestion") }
    static var sameRoomRiskQuestionAnswerPositive: String { return Localization.string(for: "sameRoomRiskQuestion.answer.positive") }
    static var sameRoomRiskQuestionAnswerNegative: String { return Localization.string(for: "sameRoomRiskQuestion.answer.negative") }
    
    static var otherCategoryTitle: String { return Localization.string(for: "otherCategoryTitle") }
    static var otherCategoryMessage: String { return Localization.string(for: "otherCategoryMessage") }
    
    static var contactFallbackTitle: String { return Localization.string(for: "contactFallbackTitle") }
    static var contactInformationFirstName: String { return Localization.string(for: "contactInformationFirstName") }
    static var contactInformationLastName: String { return Localization.string(for: "contactInformationLastName") }
    static var contactInformationPhoneNumber: String { return Localization.string(for: "contactInformationPhoneNumber") }
    static var contactInformationPhoneNumberPlaceholder: String { return Localization.string(for: "contactInformationPhoneNumberPlaceholder") }
    static var contactInformationEmailAddress: String { return Localization.string(for: "contactInformationEmailAddress") }
    static var contactInformationEmailAddressPlaceholder: String { return Localization.string(for: "contactInformationEmailAddressPlaceholder") }
    static var contactInformationBirthDate: String { return Localization.string(for: "contactInformationBirthDate") }
    static var contactInformationBSN: String { return Localization.string(for: "contactInformationBSN") }
    static var contactInformationLastExposure: String { return Localization.string(for: "contactInformationLastExposure") }
    static var contactInformationLastExposureEarlier: String { return Localization.string(for: "contactInformationLastExposure.earlier") }
    static var contactInformationLastExposureEveryDay: String { return Localization.string(for: "contactInformationLastExposure.everyDay") }
    
    static var earlierExposureDateTitle: String { return Localization.string(for: "earlierExposureDateTitle") }
    static var earlierExposureDateMessage: String { return Localization.string(for: "earlierExposureDateMessage") }
    
    static var contactDeletePromptTitle: String { return Localization.string(for: "contactDeletePromptTitle") }
    static var contactDeletePromptMessage: String { return Localization.string(for: "contactDeletePromptMessage") }
    
    static var contactQuestionDisabledMessage: String { return Localization.string(for: "contactQuestionDisabledMessage") }
    
    /* MARK: - Informing contacts */
    static var contactPromptNameFallback: String { return Localization.string(for: "contactPromptNameFallback") }
    
    static func contactInformPromptTitle(firstName: String) -> String { return Localization.string(for: "contactInformPromptTitle", [firstName]) }
    
    static var contactInformPromptMessage: String { return Localization.string(for: "contactInformPromptMessage") }
    static var contactInformOptionDone: String { return Localization.string(for: "contactInformOptionDone") }
    static var contactInformActionInformLater: String { return Localization.string(for: "contactInformActionInformLater") }
    static var contactInformActionInformNow: String { return Localization.string(for: "contactInformActionInformNow") }
    
    static func contactMissingDetailsPromptTitle(firstName: String) -> String { return Localization.string(for: "contactMissingDetailsPromptTitle", [firstName]) }
    
    static var contactMissingDetailsPromptMessage: String { return Localization.string(for: "contactMissingDetailsPromptMessage") }
    static var contactMissingDetailsActionIgnore: String { return Localization.string(for: "contactMissingDetailsActionIgnore") }
    static var contactMissingDetailsActionFillIn: String { return Localization.string(for: "contactMissingDetailsActionFillIn") }
    
    /* MARK: - Reverse Pairing */
    static var reversePairingTitle: String { return Localization.string(for: "reversePairingTitle") }
    static var reversePairingWaiting: String { return Localization.string(for: "reversePairingWaiting") }
    static var reversePairingFinished: String { return Localization.string(for: "reversePairingFinished") }
    
    static var reversePairingStep1Title: String { return Localization.string(for: "reversePairingStep1.title") }
    static var reversePairingStep1Message: String { return Localization.string(for: "reversePairingStep1.message") }
    static var reversePairingStep1Code: String { return Localization.string(for: "reversePairingStep1.code") }
    
    static var reversePairingStep2Title: String { return Localization.string(for: "reversePairingStep2.title") }
    static var reversePairingStep2Message: String { return Localization.string(for: "reversePairingStep2.message") }
    
    static var reversePairingErrorTitle: String { return Localization.string(for: "reversePairingError.title") }
    static var reversePairingErrorMessage: String { return Localization.string(for: "reversePairingError.message") }
    
    static var reversePairingCloseAlert: String { return Localization.string(for: "reversePairingCloseAlert") }
    
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
