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
        
        // Image
        imageView = UIImageView(image: viewModel.image)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.setContentHuggingPriority(.required, for: .vertical)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        
        // Labels
        let labels = VStack(spacing: 16,
            Label(title2: viewModel.title).multiline(),
            Label(body: viewModel.message, textColor: Theme.colors.captionGray).multiline()
        )
        
        // Buttons
        let buttons: UIView = {
            let primaryButton = Button(title: viewModel.primaryButtonTitle, style: .primary)
                                  .touchUpInside(self, action: #selector(handlePrimary))
            
            if let secondaryButtonTitle = viewModel.secondaryButtonTitle {
                let secondaryButton = Button(title: secondaryButtonTitle, style: .secondary)
                                        .touchUpInside(self, action: #selector(handleSecondary))
                
                if viewModel.showSecondaryButtonOnTop {
                    return VStack(spacing: 16, secondaryButton, primaryButton)
                } else {
                    return VStack(spacing: 16, primaryButton, secondaryButton)
                }
            } else {
                return primaryButton
            }
        }()
                
        // Container
        let container =
            VStack(spacing: 32, imageView, labels, buttons)
            .distribution(.equalSpacing)
            .wrappedInReadableWidth(insets: .topBottom(32))
        
        // ScrollView
        let scrollView = UIScrollView()
        container.embed(in: scrollView.readableWidth)
        container.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.safeAreaLayoutGuide.heightAnchor, multiplier: 1, constant: 0).isActive = true
        scrollView.embed(in: view)
    }
    
    @objc private func handlePrimary() {
        delegate?.onboardingStepViewControllerDidSelectPrimaryButton(self)
    }
    
    @objc private func handleSecondary() {
        delegate?.onboardingStepViewControllerDidSelectSecondaryButton(self)
    }
}
