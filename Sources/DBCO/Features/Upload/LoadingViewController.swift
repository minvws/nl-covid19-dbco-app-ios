/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

class LoadingViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.backgroundColor = .white
        
        let activityIndicator = ActivityIndicatorView(style: .whiteLarge)
        activityIndicator.color = .black
        activityIndicator.startAnimating()
        
        let stack = VStack(spacing: 8, activityIndicator, Label(body: .uploadInProgressMessage)).alignment(.center)
        
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        
        stack.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        stack.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        if #available(iOS 13.0, *) {
            isModalInPresentation = true
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
}
