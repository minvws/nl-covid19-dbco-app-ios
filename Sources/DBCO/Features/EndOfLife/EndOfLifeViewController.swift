/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit



protocol EndOfLifeViewControllerDelegate: AnyObject {
    func endOfLifeViewController(_ controller: EndOfLifeViewController, wantsToOpen url: URL)
}

/// Fullscreen alert informing the user about the app no longer being necessary
///
/// - Tag: EndOfLifeViewController
class EndOfLifeViewController: NavigationController {
    
    weak var endOfLifedelegate: EndOfLifeViewControllerDelegate?
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        let viewModel = StepViewModel(image: UIImage(named: "Onboarding2"),
                                      title: .endOfLifeTitle,
                                      message: .endOfLifeMessage,
                                      actions: [])
        
        setViewControllers([StepViewController(viewModel: viewModel)], animated: false)
        
        modalPresentationStyle = .overFullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
