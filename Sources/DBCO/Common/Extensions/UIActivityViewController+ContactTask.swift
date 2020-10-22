/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

extension UIActivityViewController {
    
    convenience init(contactTask: Task, completionHandler: ((_ success: Bool) -> Void)?) {
        guard contactTask.taskType == .contact else {
            fatalError()
        }
        
        // Actual contents to be shared are still being determined, this is a temporary implementation
        
        let url: NSURL
        switch contactTask.contact.category {
        case .category1:
            url = NSURL(string: "https://lci.rivm.nl/covid-19-huisgenoten")!
        case .category2a, .category2b:
            url = NSURL(string: "https://lci.rivm.nl/covid-19-nauwe-contacten")!
        case .category3, .other:
            url = NSURL(string: "https://lci.rivm.nl/covid-19-overige-contacten")!
        }
        
        self.init(activityItems: [url], applicationActivities: nil)
        excludedActivityTypes = [.addToReadingList]
        self.completionWithItemsHandler = { _, success, _, _ in
            completionHandler?(success)
        }
    }
    
}
