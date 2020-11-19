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
    
    static func == (lhs: ISO8601DateFormat, rhs: ISO8601DateFormat) -> Bool {
        return lhs.value == rhs.value
    }
}
