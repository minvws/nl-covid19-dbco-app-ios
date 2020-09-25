/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

protocol MainViewControllerDelegate: class {
    func mainViewControllerWantsHelp(_ controller: MainViewController)
    func mainViewControllerRequestContact(_ controller: MainViewController, with name: String?)
}

class MainViewController: UIViewController {
    
    weak var delegate: MainViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.backgroundColor = .white
        
        let versionLabel = UILabel(frame: .zero)
        versionLabel.text = .mainAppVersionTitle
        versionLabel.textAlignment = .center
        versionLabel.textColor = Theme.colors.gray
        versionLabel.font = Theme.fonts.footnote
        
        let stackView = UIStackView(
            vertical: [
                Button(title: "Choose Contact")
                    .touchUpInside(self, action: #selector(requestContact)),
                Button(title: "Choose Contact for \"Anna\"")
                    .touchUpInside(self, action: #selector(requestSpecificContact)),
                Button(title: .helpTitle, style: .info)
                    .touchUpInside(self, action: #selector(openHelp)),
                versionLabel
            ],
            spacing: 10)
        
        stackView.snap(
            to: .bottom,
            of: view.readableContentGuide,
            insets: .bottom(20))
    }
    
    @objc private func openHelp() {
        delegate?.mainViewControllerWantsHelp(self)
    }
    
    @objc private func requestContact() {
        delegate?.mainViewControllerRequestContact(self, with: nil)
    }
    
    @objc private func requestSpecificContact() {
        delegate?.mainViewControllerRequestContact(self, with: "Anna")
    }

}
