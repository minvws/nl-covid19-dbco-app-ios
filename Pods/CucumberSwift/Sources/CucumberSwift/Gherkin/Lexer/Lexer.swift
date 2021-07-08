//
//  Lexer.swift
//  CucumberSwift
//
//  Created by Tyler Thompson on 7/15/18.
//  Copyright © 2018 Tyler Thompson. All rights reserved.
//

import Foundation
public class Lexer: StringReader {
    internal var atLineStart = true
    internal var lastScope: Scope?
    internal var lastKeyword: Step.Keyword?
    internal var url: URL?

    internal init(_ str: String, uri: String) {
        url = URL(string: uri)
        super.init(str)
    }

    override public var position: Position {
        let pos = super.position
        return Position(line: pos.line, column: pos.column, uri: url)
    }

    @discardableResult internal func readLineUntil(_ evaluation: ((Character) -> Bool)) -> String {
        readUntil { $0.isNewline || evaluation($0) }
    }

    @discardableResult internal func lookAheadAtLineUntil(_ evaluation: ((Character) -> Bool)) -> String {
        lookAheadUntil { $0.isNewline || evaluation($0) }
    }

    // table cells have weird rules I don't necessarily agree with...
    @discardableResult internal func readCellUntil(_ evaluation: ((Character) -> Bool)) -> String {
        var str = ""
        while let char = currentChar, !char.isNewline {
            if char.isEscapeCharacter,
               let next = nextChar,
               next.isTableCellDelimiter || next == "n" || next.isEscapeCharacter {
                if next == "n" {
                    str.append("\n")
                } else {
                    str.append(next)
                }
                advanceIndex()
                advanceIndex()
                continue
            }
            if evaluation(char) {
                break
            }
            str.append(char)
            advanceIndex()
        }
        return str
    }

    @discardableResult internal func readDocString(_ evaluation: ((Character) -> Bool)) -> String {
        var str = ""
        while let char = currentChar {
            if char.isEscapeCharacter,
               let next = nextChar,
               next.isDocStringLiteral {
                str.append(next)
                advanceIndex()
                advanceIndex()
                continue
            }
            if evaluation(char) {
                break
            }
            str.append(char)
            advanceIndex()
        }
        return str
    }

    @discardableResult internal func stripSpaceIfNecessary() -> Bool {
        if let c = currentChar, c.isSpace {
            readLineUntil { !$0.isSpace }
            return true
        }
        return false
    }

    @discardableResult private func advance<T>(_ t:@autoclosure () -> T) -> T {
        advanceIndex()
        return t()
    }

    internal func advanceToNextToken() -> Token? {
        guard let char = currentChar else { return nil }
        defer {
            if char.isNewline {
                atLineStart = true
                lastScope = nil
                lastKeyword = nil
            } else if char.isSymbol && previousChar?.isNewline != true {
                atLineStart = false
            }
        }

        switch char {
            case .newLine: return advance(.newLine(position))
            case .comment: return readComment()
            case .tagMarker: return advance(.tag(position, readLineUntil({ !$0.isTagCharacter })))
            case .tableCellDelimiter:
                let tableCellContents = advance(readCellUntil({ $0.isTableCellDelimiter })
                                                    .trimmingCharacters(in: .whitespaces))
                if currentChar != Character.tableCellDelimiter {
                    return advanceToNextToken()
                }
                return .tableCell(position, tableCellContents)
            case _ where atLineStart: return readScope()
            case .tableHeaderOpen:
                let str = advance(readLineUntil { $0.isHeaderClosed })
                return advance(.tableHeader(position, str))
            case _ where lastScope != nil:
                let title = readLineUntil { $0.isHeaderOpen }
                if title.isEmpty { // hack to get around potential infinite loop
                    return advance(advanceToNextToken())
                }
                return .title(position, title)
            case .quote: return readString()
            case _ where char.isNumeric: return .integer(position, readLineUntil { !$0.isNumeric })
            case _ where lastKeyword != nil: return .match(position, readLineUntil { $0.isSymbol })
            default: return advance(advanceToNextToken())
        }
    }

    private func readString() -> Token? {
        guard let char = currentChar,
              char.isDocStringLiteral else { return nil }
        let position = self.position
        let open = lookAheadAtLineUntil { !$0.isDocStringLiteral }
        if open.isDocStringLiteral() {
            readLineUntil { !$0.isDocStringLiteral }
            let docStringValues = readDocString {
                if $0.isDocStringLiteral {
                    let close = lookAheadAtLineUntil { !$0.isDocStringLiteral }
                    if close == open { return true }
                }
                return false
            }.components(separatedBy: "\n")
            .enumerated()
            .reduce(into: (whitespaceCount:0, trimmedLines:[String]())) { res, e in
                let (offset, line) = e
                if offset == 1 {
                    res.whitespaceCount ?= line.map { $0 }.firstIndex { !$0.isWhitespace }
                }
                let str = line.map { $0 }.dropFirst(upTo: res.whitespaceCount) {
                    $0.isWhitespace
                }
                res.trimmedLines.append(String(str))
            }
            .trimmedLines
            .dropLast { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

            readLineUntil { !$0.isDocStringLiteral }
            return advance(.docString(position, DocString(literal: docStringValues.dropFirst().joined(separator: "\n"),
                                                          contentType: docStringValues.first?.trimmingCharacters(in: .whitespacesAndNewlines))))
        } else if char == .quote {
            let str = advance(readLineUntil { $0.isQuote })
            return advance(.string(position, str))
        }
        return nil
    }

    private func readComment() -> Token? {
        let str = advance(readLineUntil { _ in false })
        let matches = str.matches(for: "^(?:\\s*)language(?:\\s*):(?:\\s*)(.*?)(?:\\s*)$")
        if !matches.isEmpty {
            if let language = Language(matches[1]) {
                Scope.language = language
            } else {
                Gherkin.errors.append("File: \(url?.lastPathComponent ?? "") declares an unsupported language")
            }
        }
        return advance(advanceToNextToken())
    }

    // Feature, Scenario, Step etc...
    private func readScope() -> Token? {
        if stripSpaceIfNecessary() {
            return advanceToNextToken()
        }
        if let stringToken = readString() {
            return stringToken
        }
        atLineStart = false
        let position = self.position
        let scope = Scope.scopeFor(str: lookAheadAtLineUntil { $0.isScopeTerminator })
        if scope != .unknown && !scope.isStep() {
            lastScope = scope
            readUntil { $0.isScopeTerminator }
            advance(stripSpaceIfNecessary())
            return .scope(position, scope)
        } else if case .step(let keyword) = scope {
            readLineUntil { $0.isSpace }
            lastKeyword = keyword
            stripSpaceIfNecessary()
            return .keyword(position, keyword)
        } else {
            return .description(position, readLineUntil { $0.isNewline }.trimmingCharacters(in: .whitespaces))
        }
    }

    internal func lex() -> [Token] {
        Scope.language = Language.default
        var toks = [Token]()
        while let tok = advanceToNextToken() {
            toks.append(tok)
        }
        if (!toks.contains(where: { !$0.isDescription() && !$0.isNewline() })) {
            Gherkin.errors.append("File: \(url?.lastPathComponent ?? "") does not contain any valid gherkin")
        }
        return toks
    }
}
