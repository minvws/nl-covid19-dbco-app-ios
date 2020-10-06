/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

protocol StartViewControllerDelegate: class {
    func startViewControllerWantsToContinue(_ controller: StartViewController)
}

class StartViewModel {}

class StartViewController: UIViewController {
    private let viewModel: StartViewModel
    private var imageView: UIImageView!
    
    weak var delegate: StartViewControllerDelegate?
    
    init(viewModel: StartViewModel) {
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.backgroundColor = .white
        
        let titleLabel = UILabel()
        titleLabel.font = Theme.fonts.title2
        titleLabel.numberOfLines = 0
        titleLabel.text = "Help de GGD bij het contactonderzoek"
        
        let bodyLabel = UILabel()
        bodyLabel.font = Theme.fonts.body
        bodyLabel.textColor = Theme.colors.captionGray
        bodyLabel.numberOfLines = 0
        bodyLabel.text = "Je kunt via deze app gegevens van je contacten met de GGD delen. Zo zorg je dat het contactonderzoek sneller gaat."
        
        let textContainerView =
            VStack(spacing: 32,
                   VStack(spacing: 16,
                          titleLabel,
                          bodyLabel),
                   Button(title: "Volgende", style: .primary)
                       .touchUpInside(self, action: #selector(handleContinue)))
        
        textContainerView.snap(to: .bottom,
                               of: view.readableContentGuide,
                               insets: .bottom(16))
        
        imageView = UIImageView(image: UIImage(named: "StartVisual"))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.setContentHuggingPriority(.required, for: .vertical)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        
        view.addSubview(imageView)
        
        imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        let imageCenterYConstraint = imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        imageCenterYConstraint.priority = .defaultLow
        imageCenterYConstraint.isActive = true
        
        imageView.bottomAnchor.constraint(lessThanOrEqualTo: textContainerView.topAnchor, constant: -32).isActive = true
        
        let imageTextSpacingConstraint = imageView.bottomAnchor.constraint(lessThanOrEqualTo: textContainerView.topAnchor, constant: -105)
        imageTextSpacingConstraint.priority = .defaultLow
        imageTextSpacingConstraint.isActive = true
        
        imageView.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor, constant: 16).isActive = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    @objc private func handleContinue() {
        delegate?.startViewControllerWantsToContinue(self)
    }

}
