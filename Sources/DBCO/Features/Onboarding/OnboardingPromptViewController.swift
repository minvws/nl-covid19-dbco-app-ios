/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

class OnboardingPromptViewModel {
    
    let image: UIImage?
    let title: String
    let message: String?
    let actions: [OnboardingPromptViewController.Action]
    
    init(image: UIImage?, title: String, message: String?, actions: [OnboardingPromptViewController.Action]) {
        self.image = image
        self.title = title
        self.message = message
        self.actions = actions
    }
}

/// - Tag: OnboardingPromptViewController
class OnboardingPromptViewController: ViewController, ScrollViewNavivationbarAdjusting {
    let shortTitle: String = ""
    
    struct Action {
        let type: Button.ButtonType
        let title: String
        let action: () -> Void
    }
    
    private let viewModel: OnboardingPromptViewModel
    private let scrollView = UIScrollView()
    private var imageView: UIImageView!
    
    init(viewModel: OnboardingPromptViewModel) {
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
        scrollView.delaysContentTouches = false
        
        let widthProviderView = UIView()
        widthProviderView.snap(to: .top, of: scrollView, height: 0)
        widthProviderView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        
        // Image
        imageView = UIImageView(image: viewModel.image)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.setContentHuggingPriority(.required, for: .vertical)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        
        // Labels
        let labels = VStack(spacing: 16,
            UILabel(title2: viewModel.title).multiline(),
            UILabel(body: viewModel.message, textColor: Theme.colors.captionGray).multiline().hideIfEmpty()
        )
        
        func createButton(for action: Action) -> Button {
            return Button(title: action.title, style: action.type)
                .touchUpInside(self, action: #selector(handleButton))
        }
        
        // Buttons
        let buttons = VStack(spacing: 16,
                             viewModel.actions.map(createButton))
          
        // Stack
        let margin: UIEdgeInsets = .top(64) + .bottom(16)
        let stack =
            VStack(spacing: 32,
                   imageView,
                   VStack(spacing: 32,
                          labels,
                          buttons))
            .distribution(.equalSpacing)
            .embed(in: scrollView.readableWidth, insets: margin)
        stack.heightAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.heightAnchor,
                                      multiplier: 1,
                                      constant: -(margin.top + margin.bottom)).isActive = true
    }
    
    @objc private func handleButton(_ sender: Button) {
        let action = viewModel.actions.first { $0.title == sender.title }
        action?.action()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
}

extension OnboardingPromptViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        adjustNavigationBar(for: scrollView)
    }
    
}
