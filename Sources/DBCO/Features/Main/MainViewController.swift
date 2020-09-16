/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

protocol MainViewControllerDelegate: class {
    func mainViewControllerWantsHelp(_ controller: MainViewController)
}

class MainViewController: UIViewController {
    
    weak var delegate: MainViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.backgroundColor = .white
        
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(.helpTitle, for: .normal)
        button.addTarget(self, action: #selector(openHelp), for: .touchUpInside)
        
        view.addSubview(button)
        button.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20).isActive = true
        
    }
    
    @objc private func openHelp(_ sender: Any) {
        delegate?.mainViewControllerWantsHelp(self)
    }

}
