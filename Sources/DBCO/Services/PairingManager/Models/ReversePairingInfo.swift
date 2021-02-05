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
        return ReversePairingStatusInfo(self)
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
    
    var pairingCode: String?
    
    init(_ pairingInfo: ReversePairingInfo) {
        status = .pending
        expiresAt = pairingInfo.expiresAt
        refreshDelay = pairingInfo.refreshDelay
        pairingCode = nil
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        status = try container.decode(Status.self, forKey: .status)
        _expiresAt = try container.decode(ISO8601DateFormat.self, forKey: .expiresAt)
        refreshDelay = try container.decode(Int.self, forKey: .refreshDelay)
        
        pairingCode = try container.decodeIfPresent(String.self, forKey: .pairingCode)
    }
}
