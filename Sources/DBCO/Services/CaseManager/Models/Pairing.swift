/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */


import Foundation

struct Pairing: Codable, Equatable {
    let signingKey: String
    let caseUuid: UUID
    let expiresAt: Date
    
    enum RootKeys: String, CodingKey {
        case `case`
        case signingKey
    }
    
    enum CaseKeys: String, CodingKey {
        case caseUuid = "id"
        case expiresAt
    }
}

extension UUID {
    static var empty: UUID {
        return UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    }
}

extension Pairing {
    static var empty: Pairing {
        Pairing(signingKey: "", caseUuid: .empty, expiresAt: Date(timeIntervalSinceReferenceDate: 0))
    }
}
