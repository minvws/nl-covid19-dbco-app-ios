/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import Contacts

protocol NameRepresentable {
    var fullName: String { get }
}

extension CNContact: NameRepresentable {}

struct ContactSuggestionHelper {
    
    static func suggestions<T: NameRepresentable>(for name: String, in contacts: [T]) -> [T] {
        let name = name
            .lowercased()
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: "")
        
        let suggestedNameParts = name.split(separator: " ")
        var maxMatchedParts = 0
        
        func calculateMatchedParts(for contact: T) -> (count: Int, maxMatchLength: Int) {
            var matchedParts: Int = 0
            var contactNameParts = contact.fullName.lowercased().split(separator: " ")
            var maxMatchLength = 0
            
            for part in suggestedNameParts {
                if let matchedIndex = contactNameParts.firstIndex(where: { $0.starts(with: part) }) {
                    contactNameParts.remove(at: matchedIndex)
                    matchedParts += 1
                    maxMatchLength = max(part.count, maxMatchLength)
                }
            }
            
            maxMatchedParts = max(matchedParts, maxMatchedParts)
            
            return (matchedParts, maxMatchLength)
        }
        
        let sortedSuggestions = contacts
            .map { (contact: $0, matchedParts: calculateMatchedParts(for: $0)) }
            .filter { $0.matchedParts.count > 1 || $0.matchedParts.maxMatchLength > 1 }
            .sorted { $0.matchedParts.count > $1.matchedParts.count }
            .prefix { $0.matchedParts.count == maxMatchedParts }
        
        return sortedSuggestions.map { $0.contact }
    }
    
}
