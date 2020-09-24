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
        
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = .mainAppVersionTitle
        label.textColor = .lightGray
        label.font = UIFont.preferredFont(forTextStyle: .footnote)
        
        let stackView = UIStackView(arrangedSubviews: [button, label])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 10
        
        view.addSubview(stackView)
    
        stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20).isActive = true
    }
    
    @objc private func openHelp(_ sender: Any) {
        delegate?.mainViewControllerWantsHelp(self)
    }

}
