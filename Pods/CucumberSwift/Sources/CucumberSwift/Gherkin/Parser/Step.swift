//
//  Step.swift
//  CucumberSwift
//
//  Created by Tyler Thompson on 4/7/18.
//  Copyright © 2018 Tyler Thompson. All rights reserved.
//

import Foundation
import XCTest

public class Step: CustomStringConvertible {
    public var description: String {
        "TAGS:\(tags)\n\(keyword.toString()): \(match)"
    }

    public var continueAfterFailure = true {
        willSet {
            testCase?.continueAfterFailure = newValue
        }
    }

    public var canExecute: Bool {
        execute != nil
            || executeSelector != nil
            || executeClass != nil
    }

    public private(set)  var match = ""
    public private(set)  var keyword: Keyword = []
    public internal(set) var tags = [String]()
    public internal(set) var scenario: Scenario?
    public internal(set) var dataTable: DataTable?
    public private(set)  var docString: DocString?
    public private(set)  var location: Lexer.Position
    public internal(set) var testCase: XCTestCase?

    var result: Reporter.Result = .pending
    var execute: (([String], Step) -> Void)?
    var executeSelector: Selector?
    var executeClass: AnyClass?
    var executeInstance: NSObject?
    var regex: String = ""
    var errorMessage: String = ""
    var startTime: Date?
    var endTime: Date?
    var executionDuration: Measurement<UnitDuration> {
        // Converting to nanoseconds from seconds has a rounding error, so storing as nanoseconds is actually better.
        guard let start = startTime, let end = endTime else { return Measurement(value: 0, unit: .seconds) }
        if #available(iOS 13.0, macOS 10.15, tvOS 13, *) {
            return Measurement(value: end.timeIntervalSince(start) * 1_000_000_000, unit: .nanoseconds)
        } else {
            return Measurement(value: end.timeIntervalSince(start), unit: .seconds)
        }
    }
    var tokens = [Lexer.Token]()

    init(with node: AST.StepNode) {
        location = node.tokens.first { $0.isKeyword() }?.position ?? .start
        tokens = node.tokens.filter { !$0.isKeyword() }
        for token in node.tokens {
            if case Lexer.Token.keyword(_, let kw) = token {
                keyword = kw
            } else if case Lexer.Token.match(_, let m) = token {
                match += m
            } else if case Lexer.Token.string(_, let s) = token {
                match += "\"\(s)\""
            } else if case Lexer.Token.integer(_, let n) = token {
                match += n
            } else if case Lexer.Token.tableHeader(_, let h) = token {
                match += h
            } else if case Lexer.Token.docString(_, let s) = token {
                docString = s
            }
        }
        let tableLines = node.tokens
            .filter { $0.isTableCell() || $0.isNewline() }
            .groupedByLine()
            .map { line -> [String] in
                return line.filter { $0.isTableCell() }
                    .map { token -> String in
                        if case Lexer.Token.tableCell(_, let cellText) = token {
                            return cellText
                        }
                        return ""
                    }
            }
        if !tableLines.isEmpty {
            dataTable = DataTable(tableLines)
        }
        match = match.trimmingCharacters(in: .whitespaces)
    }

    init(with execute:@escaping (([String], Step) -> Void), match: String?, position: Lexer.Position) {
        location = position
        self.match ?= match
        self.execute = execute
    }

    func toJSON() -> [String: Any] {
        if #available(iOS 13.0, macOS 10.15, tvOS 13, *) {
            return [
                "result": ["status": "\(result)", "error_message": errorMessage, "duration": executionDuration.converted(to: .nanoseconds).value],
                "name": "\(match)",
                "keyword": "\(keyword.toString())"
            ]
        } else {
            return [
                "result": ["status": "\(result)", "error_message": errorMessage, "duration": executionDuration.converted(to: .seconds).value * 1_000_000_000],
                "name": "\(match)",
                "keyword": "\(keyword.toString())"
            ]
        }
    }
}

extension Step {
    public struct Keyword: OptionSet, Hashable {
        public let rawValue: Int
        private var stringValue: String?
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public init?(_ str: String) {
            stringValue = str
            var set: Keyword = []
            if Scope.language.matchesGiven(str) {
                set.insert(.given)
            }
            if Scope.language.matchesWhen(str) {
                set.insert(.when)
            }
            if Scope.language.matchesThen(str) {
                set.insert(.then)
            }
            if Scope.language.matchesAnd(str) {
                set.insert(.and)
            }
            if Scope.language.matchesBut(str) {
                set.insert(.but)
            }
            guard !set.isEmpty else { return nil }
            self = set
        }

        public func toString() -> String {
            if let str = stringValue {
                return str
            }
            if contains(Keyword.given) {
                return Scope.language.given
            }
            if contains(Keyword.when) {
                return Scope.language.when
            }
            if contains(Keyword.then) {
                return Scope.language.then
            }
            if contains(Keyword.and) {
                return Scope.language.and
            }
            if contains(Keyword.but) {
                return Scope.language.but
            }
            return "UNKNOWN"
        }

        public func hasMultipleValues() -> Bool {
            guard rawValue > 2 else { return false }
            return ceil(log2(Double(rawValue))) != floor(log2(Double(rawValue)))
        }

        public static let given = Keyword(rawValue: 1 << 0)
        public static let when  = Keyword(rawValue: 1 << 1)
        public static let then  = Keyword(rawValue: 1 << 2)
        public static let and   = Keyword(rawValue: 1 << 3)
        public static let but   = Keyword(rawValue: 1 << 4)
    }
}
