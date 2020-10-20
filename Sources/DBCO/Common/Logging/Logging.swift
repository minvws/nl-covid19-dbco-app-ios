/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

public protocol Logging {
    var loggingCategory: String { get }

    func logDebug(_ message: String, function: StaticString, file: StaticString, line: UInt)
    func logInfo(_ message: String, function: StaticString, file: StaticString, line: UInt)
    func logWarning(_ message: String, function: StaticString, file: StaticString, line: UInt)
    func logError(_ message: String, function: StaticString, file: StaticString, line: UInt)
}

public extension Logging {

    /// The category with which the class that conforms to the `Logging`-protocol is logging.
    var loggingCategory: String {
        return "default"
    }

    func logDebug(_ message: String, function: StaticString = #function, file: StaticString = #file, line: UInt = #line) {
        NSLog("🐞 \(message)")
    }

    func logInfo(_ message: String, function: StaticString = #function, file: StaticString = #file, line: UInt = #line) {
        NSLog("📋 \(message)")
    }

    func logWarning(_ message: String, function: StaticString = #function, file: StaticString = #file, line: UInt = #line) {
        NSLog("❗️ \(message)")
    }

    func logError(_ message: String, function: StaticString = #function, file: StaticString = #file, line: UInt = #line) {
        NSLog("🔥 \(message)")
    }
}
