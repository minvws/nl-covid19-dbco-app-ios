/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

class GuidelinesHelper {
    
    private typealias ExposureDateRange = (range: NSRange, exposureDateOffset: Int)
    
    static private var exposureDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = .informContactGuidelinesDateFormat
        formatter.calendar = Calendar.current
        formatter.locale = .display
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        return formatter
    }()
    
    private static func exposureDateRange(from match: NSTextCheckingResult, in text: NSString) -> ExposureDateRange? {
        guard match.numberOfRanges == 2 else { return nil }
        guard let offset = Int(text.substring(with: match.range(at: 1))) else { return nil }
        
        return (match.range(at: 0), offset)
    }
    
    private static func replaceExposureDateRanges(in text: NSString, ranges: [ExposureDateRange], exposureDate: Date) -> String {
        var text = text
        
        for range in ranges.reversed() { // reversed order, so mutating the string doesn't invalidate the ranges
            let replacement = exposureDateFormatter.string(from: exposureDate.dateByAddingDays(range.exposureDateOffset))
            text = text.replacingCharacters(in: range.range, with: replacement) as NSString
        }
        
        return text as String
    }
    
    static func parseGuidelines(_ text: String, exposureDate: Date?, referenceNumber: String?, referenceNumberItem: String?) -> String {
        var text = text
        
        text = referenceNumber.map { text.replacingOccurrences(of: "{ReferenceNumber}", with: $0) } ?? text
        text = referenceNumberItem.map { text.replacingOccurrences(of: "{ReferenceNumberItem}", with: $0) } ?? text
        
        if let exposureDate = exposureDate {
            text = text.replacingOccurrences(of: "{ExposureDate}", with: exposureDateFormatter.string(from: exposureDate))
            
            let nsText = text as NSString
            
            if let regex = try? NSRegularExpression(pattern: #"\{ExposureDate\+([0-9]+)\}"#, options: []) {
                let textRange = NSRange(location: 0, length: nsText.length)
                let matches = regex.matches(in: text, options: [], range: textRange)
                let ranges = matches.compactMap { exposureDateRange(from: $0, in: nsText) }
                text = replaceExposureDateRanges(in: nsText, ranges: ranges, exposureDate: exposureDate)
            }
        }
        
        return text
    }
    
}
