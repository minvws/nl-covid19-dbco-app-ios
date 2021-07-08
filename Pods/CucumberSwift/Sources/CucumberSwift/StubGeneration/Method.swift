//
//  Method.swift
//  CucumberSwift
//
//  Created by Tyler Thompson on 8/4/18.
//  Copyright © 2018 Tyler Thompson. All rights reserved.
//

import Foundation
class Method {
    var keyword: Step.Keyword = []
    var keywords: [Step.Keyword] = []
    var comment = ""
    private(set) var regex = ""
    private(set) var matchesParameter = ""
    private(set) var variables:[(type: String, count: Int)] = []
    init(keyword: Step.Keyword, regex: String, matchesParameter: String, variables:[(type: String, count: Int)]) {
        self.keyword = keyword
        self.keywords = [keyword]
        self.regex = regex
        self.matchesParameter = matchesParameter
        self.variables = variables
    }

    func insertKeyword(_ keyword: Step.Keyword) {
        keywords.append(keyword)
        self.keyword.insert(keyword)
    }

    private func getKeywordStrings(matchAllAllowed: Bool) -> [String] {
        var keywordStrings = [String]()
        if keyword.hasMultipleValues() && matchAllAllowed {
            keywordStrings.append("MatchAll")
        } else if !matchAllAllowed && keyword.hasMultipleValues() {
            keywordStrings.append(contentsOf: keywords.map { $0.toString() })
        } else {
            keywordStrings.append(keyword.toString())
        }
        return keywordStrings
    }

    func generateSwift(matchAllAllowed: Bool = true) -> String {
        Scope.language ?= Language()
        var methodStrings = [String]()
        for keywordString in getKeywordStrings(matchAllAllowed: matchAllAllowed) {
            // swiftlint:disable:next empty_count
            let variablesOnStepObject = variables.filter { $0.type == "dataTable" || $0.type == "docString" }.filter { $0.count > 0 }
            let stepParameter = (!variablesOnStepObject.isEmpty) ? "step" : "_"
            var methodString = "\(keywordString.capitalizingFirstLetter())(\"^\(regex.trimmingCharacters(in: .whitespacesAndNewlines))$\") { \(matchesParameter), \(stepParameter) in\n"
            for variable in variables {
                for i in 0..<variable.count {
                    let spelledNumber = (i > 0) ? NumberFormatter.localizedString(from: .init(value: i + 1),
                                                                                  number: .spellOut) : ""
                    let varName = "\(variable.type) \(spelledNumber)".camelCasingString()
                    if variable.type != "dataTable" && variable.type != "docString" {
                        methodString += "    let \(varName) = \(matchesParameter)[\(i + 1)]\n"
                    } else {
                        methodString += "    let \(varName) = step.\(variable.type)\n"
                    }
                }
            }
            if variables.reduce(0, { $0 + $1.count }) <= 0 {
                methodString += "\n"
            }
            methodString += "}"
            methodStrings.append(methodString)
        }
        return comment + methodStrings.joined(separator: "\n")
    }
}
