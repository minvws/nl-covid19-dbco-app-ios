/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

extension String {
    
    /// Localized string describing the app version.
    static var mainAppVersionTitle: String? {
        // "GitHash" is set dynamically for the built app with a run script-phase
        guard let dictionary = Bundle.main.infoDictionary,
              let version = dictionary["CFBundleShortVersionString"] as? String,
              let build = dictionary["CFBundleVersion"] as? String,
              let hash = dictionary["GitHash"] as? String else {
            return nil
        }
        
        let buildAndHash = "\(build)-\(hash)"
        
        return Localization.string(for: "appVersionTitle", [version, buildAndHash])
    }

}
