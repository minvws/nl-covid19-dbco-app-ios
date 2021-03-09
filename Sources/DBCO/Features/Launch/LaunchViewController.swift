/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

class LaunchViewModel {
    
}

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
        ImageView(imageName: "LaunchScreen/Background").embed(in: view)
        
        let icon = ImageView(imageName: "LaunchScreen/Icon")
        icon.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(icon)
        
        icon.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -2).isActive = true
        icon.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -3).isActive = true
    }

}
