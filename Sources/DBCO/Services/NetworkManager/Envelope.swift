/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

protocol Envelopable {
    static var envelopeName: String { get }
}

struct Envelope<Item: Envelopable & Decodable>: Decodable {
    let items: [Item]
    
    struct CodingKeys: CodingKey {
        var stringValue: String
        var intValue: Int?

        init?(intValue: Int) {
            return nil
        }

        init?(stringValue: String) {
            if stringValue == Item.envelopeName {
                self.stringValue = stringValue
                self.intValue = nil
            } else {
                return nil
            }
        }
        
        static var items: Self {
            return CodingKeys(stringValue: Item.envelopeName)!
        }
    }
    
    init(from decoder: Decoder) throws {
        items = try decoder.container(keyedBy: CodingKeys.self).decode([Item].self, forKey: .items)
    }
}

extension Task: Envelopable { static let envelopeName = "tasks" }

extension Questionnaire: Envelopable { static let envelopeName = "questionnaires" }
