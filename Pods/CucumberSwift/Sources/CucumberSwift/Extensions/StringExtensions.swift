//
//  StringExtensions.swift
//  CucumberSwift
//
//  Created by Tyler Thompson on 4/7/18.
//  Copyright © 2018 Tyler Thompson. All rights reserved.
//

import Foundation
extension String {
    init(_ staticString: StaticString) {
        self = staticString.withUTF8Buffer {
            String(decoding: $0, as: UTF8.self)
        }
    }

    func matches(for regex: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex, options: .caseInsensitive)
            let results = regex.matches(in: self,
                                        range: NSRange(startIndex..., in: self))
            guard let firstResult = results.first else { return [] }
            var matches = [String]()
            for i in 0..<firstResult.numberOfRanges {
                if let range = Range(firstResult.range(at: i), in: self) {
                    matches.append(String(self[range]))
                }
            }
            return matches
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }

    func capitalizingFirstLetter() -> String {
        prefix(1).uppercased() + dropFirst()
    }

    func lowercasingFirstLetter() -> String {
        prefix(1).lowercased() + dropFirst()
    }

    func camelCasingString() -> String {
        var str = ""
        let words = replacingOccurrences( of: "[^a-zA-Z]", with: " ", options: .regularExpression)
                    .components(separatedBy: .whitespaces)
        for (i, word) in words.enumerated() {
            if i == 0 {
                str += word.lowercasingFirstLetter()
                continue
            }
            str += word.capitalizingFirstLetter()
        }
        return str
    }

    func isDocStringLiteral() -> Bool {
        guard count == 3 else { return false }
        return !compactMap { $0.unicodeScalars.first }
                .contains { !CharacterSet.docStrings.contains($0) }
    }
}
