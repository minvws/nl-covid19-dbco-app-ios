/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

protocol HelpItem {
    var title: String { get }
}

enum HelpOverviewItem: HelpItem {
    case question(HelpQuestion)
    
    var title: String {
        switch self {
        case .question(let question):
            return question.question
        }
    }
}

final class HelpQuestion {
    let question: String
    let answer: String
    var linkedItems: [HelpOverviewItem] = []

    init(question: String, answer: String) {
        self.question = question
        self.answer = answer
    }

    func appending(linkedItems: [HelpOverviewItem]) -> HelpQuestion {
        self.linkedItems.append(contentsOf: linkedItems)
        return self
    }
}

final class HelpItemManager {
    let overviewItems: [HelpOverviewItem]

    init() {
        let reason = HelpQuestion(question: .helpFaqReasonTitle, answer: .helpFaqReasonDescription)
        let location = HelpQuestion(question: .helpFaqLocationTitle, answer: .helpFaqLocationDescription)
        let anonymous = HelpQuestion(question: .helpFaqAnonymousTitle, answer: .helpFaqAnonymousDescription1 + "<br><br>" + .helpFaqAnonymousDescription2)
        let notification = HelpQuestion(question: .helpFaqNotificationTitle, answer: .helpFaqNotificationDescription)
        let bluetooth = HelpQuestion(question: .helpFaqBluetoothTitle, answer: .helpFaqBluetoothDescription)
        let power = HelpQuestion(question: .helpFaqPowerUsageTitle, answer: .helpFaqPowerUsageDescription)

        overviewItems = [
            .question(reason.appending(linkedItems: [
                HelpOverviewItem.question(location)
            ])),

            .question(location.appending(linkedItems: [
                HelpOverviewItem.question(bluetooth)
            ])),

            .question(anonymous.appending(linkedItems: [
                HelpOverviewItem.question(location)
            ])),

            .question(notification.appending(linkedItems: [
                HelpOverviewItem.question(bluetooth)
            ])),

            .question(bluetooth.appending(linkedItems: [
                HelpOverviewItem.question(notification),
                HelpOverviewItem.question(anonymous)
            ])),

            .question(power.appending(linkedItems: [
                HelpOverviewItem.question(reason)
            ]))
        ]
    }
}


