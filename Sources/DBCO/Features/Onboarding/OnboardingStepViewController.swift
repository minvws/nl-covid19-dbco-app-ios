/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

protocol OnboardingStepViewControllerDelegate: class {
    func onboardingStepViewControllerDidSelectPrimaryButton(_ controller: OnboardingStepViewController)
    func onboardingStepViewControllerDidSelectSecondaryButton(_ controller: OnboardingStepViewController)
}

class OnboardingStepViewModel {
    let image: UIImage
    let title: String
    let message: String
    let primaryButtonTitle: String
    let secondaryButtonTitle: String?
    let showSecondaryButtonOnTop: Bool
    
    init(image: UIImage, title: String, message: String, primaryButtonTitle: String, secondaryButtonTitle: String? = nil, showSecondaryButtonOnTop: Bool = false) {
        self.image = image
        self.title = title
        self.message = message
        self.primaryButtonTitle = primaryButtonTitle
        self.secondaryButtonTitle = secondaryButtonTitle
        self.showSecondaryButtonOnTop = showSecondaryButtonOnTop
    }
}

/// - Tag: OnboardingStepViewController
class OnboardingStepViewController: ViewController {
    private let viewModel: OnboardingStepViewModel
    private var imageView: UIImageView!
    
    weak var delegate: OnboardingStepViewControllerDelegate?
    
    init(viewModel: OnboardingStepViewModel, showSecondaryButtonOnTop: Bool = false) {
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
        navigationItem.largeTitleDisplayMode = .never
        
        let buttonStack: UIView
        let primaryButton = Button(title: viewModel.primaryButtonTitle, style: .primary)
            .touchUpInside(self, action: #selector(handlePrimary))
        
        if let secondaryButtonTitle = viewModel.secondaryButtonTitle {
            let secondaryButton = Button(title: secondaryButtonTitle, style: .secondary)
                .touchUpInside(self, action: #selector(handleSecondary))
            
            if viewModel.showSecondaryButtonOnTop {
                buttonStack = VStack(spacing: 16,
                                     secondaryButton,
                                     primaryButton)
            } else {
                buttonStack = VStack(spacing: 16,
                                     primaryButton,
                                     secondaryButton)
            }
        } else {
            buttonStack = primaryButton
        }
        
        let textContainerView =
            VStack(spacing: 32,
                   VStack(spacing: 16,
                          Label(title2: viewModel.title).multiline(),
                          Label(body: viewModel.message, textColor: Theme.colors.captionGray).multiline()),
                   buttonStack)
            .distribution(.equalSpacing)
        
        textContainerView.snap(to: .bottom,
                               of: view.readableContentGuide,
                               insets: .bottom(8))
        
        let heightConstraint = textContainerView.heightAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.4)
        heightConstraint.priority = .defaultHigh
        heightConstraint.isActive = true
        
        imageView = UIImageView(image: viewModel.image)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.setContentHuggingPriority(.required, for: .vertical)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        
        view.addSubview(imageView)
        
        imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        imageView.widthAnchor.constraint(lessThanOrEqualTo: textContainerView.widthAnchor, multiplier: 1).isActive = true
        
        let imageCenterYConstraint = imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        imageCenterYConstraint.priority = .defaultLow
        imageCenterYConstraint.isActive = true
        
        imageView.bottomAnchor.constraint(lessThanOrEqualTo: textContainerView.topAnchor, constant: -32).isActive = true
        
        let imageTextSpacingConstraint = imageView.bottomAnchor.constraint(lessThanOrEqualTo: textContainerView.topAnchor, constant: -105)
        imageTextSpacingConstraint.priority = .defaultLow
        imageTextSpacingConstraint.isActive = true
        
        imageView.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor, constant: 0).isActive = true
    }
    
    @objc private func handlePrimary() {
        delegate?.onboardingStepViewControllerDidSelectPrimaryButton(self)
    }
    
    @objc private func handleSecondary() {
        delegate?.onboardingStepViewControllerDidSelectSecondaryButton(self)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        // Hide image on landscape orientation (= width > height)
        imageView.isHidden = (UIScreen.main.bounds.width > UIScreen.main.bounds.height)
    }
}
