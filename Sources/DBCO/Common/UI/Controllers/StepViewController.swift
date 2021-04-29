/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

class StepViewModel {
    
    let image: UIImage?
    let title: String
    let message: String?
    let actions: [StepViewController.Action]
    
    init(image: UIImage?, title: String, message: String?, actions: [StepViewController.Action]) {
        self.image = image
        self.title = title
        self.message = message
        self.actions = actions
    }
}

/// [ViewController](x-source-tag://ViewController) showing an optional image, title and optional message along with a set of buttons linked to actions.
/// Similar to how UIAlertController works, but tapping a button (action) won't dismiss (or pop) the `StepViewController`.
///
/// - Tag: StepViewController
class StepViewController: ViewController, ScrollViewNavivationbarAdjusting {
    
    let shortTitle: String = ""
    
    struct Action {
        let type: Button.ButtonType
        let title: String?
        let action: () -> Void
        
        init(type: Button.ButtonType, title: String?, action: @escaping () -> Void) {
            self.type = type
            self.title = title
            self.action = action
        }
        
        init(type: Button.ButtonType, title: String?, target: AnyObject, action: Selector) {
            self.type = type
            self.title = title
            self.action = { [weak target] in
                _ = target?.perform(action)
            }
        }
    }
    
    private let viewModel: StepViewModel
    private let scrollView = UIScrollView()

    init(viewModel: StepViewModel) {
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
        
        setupStackView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if navigationController?.viewControllers.count == 1 {
            navigationController?.setNavigationBarHidden(true, animated: animated)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    private func createImage() -> UIView {
        let imageView = UIImageView(image: viewModel.image)
        imageView.contentMode = .scaleAspectFit
        imageView.setContentHuggingPriority(.required, for: .vertical)
        imageView.setContentCompressionResistancePriority(UILayoutPriority(100), for: .vertical)
        imageView.heightAnchor.constraint(greaterThanOrEqualToConstant: 160).isActive = true
        
        return imageView
    }
    
    private func createLabels() -> UIView {
        return VStack(spacing: 16,
                      UILabel(title2: viewModel.title).multiline(),
                      UILabel(body: viewModel.message, textColor: Theme.colors.captionGray)
                          .multiline()
                          .hideIfEmpty())
    }
    
    private func createButtons() -> UIView {
        func createButton(for offset: Int, action: Action) -> Button {
            let button = Button(title: action.title ?? "", style: action.type)
                .touchUpInside(self, action: #selector(handleButton))
            button.tag = offset
            button.isHidden = action.title == nil
            return button
        }
        
        return VStack(spacing: 16,
                      viewModel.actions.enumerated().map(createButton))
    }
    
    private func setupStackView() {
        let isSmallScreen = UIScreen.main.bounds.height < 600
        let margin: UIEdgeInsets = .top(isSmallScreen ? 16 : 32) + .bottom(16)
        let stack =
            VStack(spacing: 32,
                   createImage(),
                   VStack(spacing: 32,
                          createLabels(),
                          createButtons())
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
    
    @objc private func handleButton(_ sender: Button) {
        viewModel.actions[sender.tag].action()
    }
}

extension StepViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        adjustNavigationBar(for: scrollView)
    }
    
}
