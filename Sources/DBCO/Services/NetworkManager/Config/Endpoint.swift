/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

struct Path {
    let components: [String]

    init(components: String?...) {
        self.components = Array(components).compactMap { $0 }
    }
}

struct Endpoint {

    // MARK: - API

    static let appConfiguration = Path(components: "config")
    
    static let pairings = Path(components: "pairings")
    
    static func `case`(identifier: String) -> Path { Path(components: "cases", identifier) }
    
    static let questionnaires = Path(components: "questionnaires")
    
    static func pairingRequests(token: String?) -> Path { Path(components: "pairingrequests", token) }
}
