/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

extension String {
    
    // "GIT_HASH" is set on compile time with a run script-phase

    static var mainAppVersionTitle: String? {
        guard let dictionary = Bundle.main.infoDictionary,
              let version = dictionary["CFBundleShortVersionString"] as? String,
              let build = dictionary["CFBundleVersion"] as? String else {
            return nil
        }
        
        let buildAndHash = "\(build)-\(GIT_HASH)"
        
        return Localization.string(for: "appVersionTitle", [version, buildAndHash])
    }

}
