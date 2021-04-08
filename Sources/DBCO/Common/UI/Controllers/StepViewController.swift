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
class StepViewController: ViewController, ScrollViewNavivationbarAdjusting {
    
    let shortTitle: String = ""
    
    private let viewModel: StepViewModel
    private let scrollView = UIScrollView()
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
        scrollView.embed(in: view)
        scrollView.delegate = self
        
        let widthProviderView = UIView()
        widthProviderView.snap(to: .top, of: scrollView, height: 0)
        widthProviderView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        
        // Image
        imageView = UIImageView(image: viewModel.image)
        imageView.contentMode = .scaleAspectFit
        imageView.setContentHuggingPriority(.required, for: .vertical)
        imageView.setContentCompressionResistancePriority(UILayoutPriority(100), for: .vertical)
        imageView.heightAnchor.constraint(greaterThanOrEqualToConstant: 80).isActive = true
        
        // Labels
        let labels = VStack(spacing: 16,
            UILabel(title2: viewModel.title).multiline(),
            UILabel(body: viewModel.message, textColor: Theme.colors.captionGray)
                .multiline()
                .hideIfEmpty()
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
          
        // Stack
        let margin: UIEdgeInsets = .top(32) + .bottom(16)
        let stack =
            VStack(spacing: 32,
                   imageView,
                   VStack(spacing: 32,
                          labels,
                          buttons)
                    .distribution(.equalSpacing)
                    .heightConstraint(to: 300,
                                      priority: UILayoutPriority(50)))
            .distribution(.equalSpacing)
            .embed(in: scrollView.readableWidth, insets: margin)
        stack.heightAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.heightAnchor,
                                      multiplier: 1,
                                      constant: -(margin.top + margin.bottom)).isActive = true
        
        let preferredHeightConstraint = stack.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor,
                                                                      multiplier: 1,
                                                                      constant: -(margin.top + margin.bottom))
        preferredHeightConstraint.priority = UILayoutPriority(250)
        preferredHeightConstraint.isActive = true
    }
    
    @objc private func handlePrimary() {
        delegate?.stepViewControllerDidSelectPrimaryButton(self)
    }
    
    @objc private func handleSecondary() {
        delegate?.stepViewControllerDidSelectSecondaryButton(self)
    }
}

extension StepViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        adjustNavigationBar(for: scrollView)
    }
    
}
