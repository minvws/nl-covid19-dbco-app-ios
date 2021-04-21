/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

/// Not all GGD regions might actively using the app. To determine whether or not the user is located in a "active" GGD region, the four digits of the zip code are asked.
/// The config fetched by the app contains all the [ZipRange](x-source-tag://ZipRange) that are part of municipalities within the active GGD regions.
///
/// - Tag: ZipRange
struct ZipRange: Codable {
    let start: Int
    let end: Int
    
    func contains(_ value: Int) -> Bool {
        return start <= value && value <= end
    }
}
