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
