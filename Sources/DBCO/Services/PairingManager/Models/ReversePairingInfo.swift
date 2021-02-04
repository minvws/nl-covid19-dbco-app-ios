/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

struct ReversePairingInfo: Codable {
    var code: String
    @ISO8601DateFormat var expiresAt: Date
    var token: String
    var refreshDelay: Int
    
    var statusInfo: ReversePairingStatusInfo {
        return ReversePairingStatusInfo(status: .pending, expiresAt: expiresAt, refreshDelay: refreshDelay)
    }
}

struct ReversePairingStatusInfo: Codable {
    enum Status: String, Codable {
        case pending
        case completed
    }
    
    var status: Status
    @ISO8601DateFormat var expiresAt: Date
    var refreshDelay: Int
    
    var pairingCode: String? = nil
}
