/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

protocol StepViewControllerDelegate: class {
    func stepViewControllerDidSelectPrimaryButton(_ controller: StepViewController)
    func stepViewControllerDidSelectSecondaryButton(_ controller: StepViewController)
}

class StepViewModel {
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

/// - Tag: StepViewController
class StepViewController: PromptableViewController {
    private let viewModel: StepViewModel
    private var imageView: UIImageView!
    
    weak var delegate: StepViewControllerDelegate?
    
    init(viewModel: StepViewModel, showSecondaryButtonOnTop: Bool = false) {
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
        
        // ScrollView
        let scrollView = UIScrollView()
        scrollView.embed(in: contentView)
        scrollView.delaysContentTouches = true
        
        // Image
        imageView = UIImageView(image: viewModel.image)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.setContentHuggingPriority(.required, for: .vertical)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        
        // Labels
        let labels = VStack(spacing: 16,
            UILabel(title2: viewModel.title).multiline(),
            UILabel(body: viewModel.message, textColor: Theme.colors.captionGray).multiline()
        )
          
        // Stack
        let margin: UIEdgeInsets = .top(64) + .bottom(64)
        let stack =
            VStack(spacing: 32, imageView, labels)
            .distribution(.equalCentering)
            .embed(in: scrollView.readableWidth, insets: margin)
        stack.heightAnchor.constraint(greaterThanOrEqualTo: contentView.safeAreaLayoutGuide.heightAnchor,
                                      multiplier: 1,
                                      constant: -(margin.top + margin.bottom)).isActive = true
        
        // Buttons
        promptView = {
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
    }
    
    @objc private func handlePrimary() {
        delegate?.stepViewControllerDidSelectPrimaryButton(self)
    }
    
    @objc private func handleSecondary() {
        delegate?.stepViewControllerDidSelectSecondaryButton(self)
    }
}
