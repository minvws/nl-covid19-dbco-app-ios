/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

class LaunchViewModel {
    
}

/// [ViewController](x-source-tag://ViewController) simulating the LaunchScreen.storyboard. Used for hiding the app's contents in the background and delay showin the app when loading the configuration
///
/// # See also
/// [LaunchCoordinator](x-source-tag://LaunchCoordinator)
/// - Tag: LaunchViewController
class LaunchViewController: ViewController {
    private let viewModel: LaunchViewModel
    
    required init(viewModel: LaunchViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        UIImageView(imageName: "LaunchScreen/Background").embed(in: view)
        
        let icon = UIImageView(imageName: "LaunchScreen/Icon")
        icon.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(icon)
        
        icon.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -2).isActive = true
        icon.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -3).isActive = true
    }

}
