/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */


import Foundation

struct Pairing: Codable, Equatable {
    struct Case: Codable, Equatable {
        let uuid: UUID
        @ISO8601DateFormat var expiresAt: Date
        
        enum CodingKeys: String, CodingKey {
            case uuid = "id"
            case expiresAt
        }
    }
    
    let signingKey: String
    let `case`: Case
}

extension UUID {
    static var empty: UUID {
        return UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    }
}

extension Pairing {
    static var empty: Pairing {
        Pairing(signingKey: "", case: Case(uuid: .empty, expiresAt: Date(timeIntervalSinceReferenceDate: 0)))
    }
}
