/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */


import Foundation

struct Pairing: Codable {
    let signingKey: String
    let caseUuid: String
    let expiresAt: String
    
    enum RootKeys: String, CodingKey {
        case `case`
        case signingKey
    }
    
    enum CaseKeys: String, CodingKey {
        case caseUuid = "id"
        case expiresAt
    }
}
