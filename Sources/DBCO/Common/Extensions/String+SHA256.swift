/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import CommonCrypto

extension String {
    
    var sha256: String {
        let str = cString(using: .utf8)
        let strLen = CUnsignedInt(lengthOfBytes(using: .utf8))
        let digestLen = Int(CC_SHA256_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)

        CC_SHA256(str, strLen, result)

        let hash = NSMutableString()
        
        for i in 0 ..< digestLen {
            hash.appendFormat("%02x", result[i])
        }

        result.deallocate()

        return String(format: hash as String)
    }
    
}
