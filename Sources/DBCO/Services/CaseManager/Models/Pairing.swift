/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */


import Foundation

@propertyWrapper struct ISO8601DateFormat: Codable, Equatable {
    enum DateFormatError: Error {
        case couldNotParseDate
    }
    
    private var value: Date
    private let dateFormatter = ISO8601DateFormatter()
    
    init(wrappedValue: Date) {
        value = wrappedValue
    }
    
    var wrappedValue: Date {
        get { value }
        set { value = newValue }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let valueString = try container.decode(String.self)
        
        guard let date = dateFormatter.date(from: valueString) else {
            throw DateFormatError.couldNotParseDate
        }
        
        value = date
    }
    
    func encode(to encoder: Encoder) throws {
        let valueString = dateFormatter.string(from: value)
        try valueString.encode(to: encoder)
    }
}

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
