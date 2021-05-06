/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

protocol PrivacyConsentViewControllerDelegate: AnyObject {
    func privacyConsentViewControllerWantsToContinue(_ controller: PrivacyConsentViewController)
    func privacyConsentViewController(_ controller: PrivacyConsentViewController, wantsToOpen url: URL)
}

class PrivacyConsentViewModel {
    let buttonTitle: String
    
    @Bindable private(set) var isContinueButtonEnabled: Bool = false
    
    init(buttonTitle: String) {
        self.buttonTitle = buttonTitle
    }
    
    func registerConsent(value: Bool) {
        isContinueButtonEnabled = value
    }
}

/// - Tag: PrivacyConsentViewController
class PrivacyConsentViewController: ViewController, ScrollViewNavivationbarAdjusting {
    private let viewModel: PrivacyConsentViewModel
    private let scrollView = UIScrollView(frame: .zero)
    
    weak var delegate: PrivacyConsentViewControllerDelegate?
    
    let shortTitle: String = .onboardingConsentShortTitle
    
    init(viewModel: PrivacyConsentViewModel) {
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if #available(iOS 14.0, *) {
            navigationItem.backButtonDisplayMode = .generic
        }
        
        view.backgroundColor = .white
        
        scrollView.embed(in: view)
        scrollView.delegate = self
        scrollView.delaysContentTouches = false
        
        let widthProviderView = UIView()
        widthProviderView.snap(to: .top, of: scrollView, height: 0)
        widthProviderView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        
        let continueButton = Button(title: viewModel.buttonTitle, style: .primary)
            .touchUpInside(self, action: #selector(handleContinue))

        viewModel.$isContinueButtonEnabled.binding = { continueButton.isEnabled = $0 }
        
        let margin: UIEdgeInsets = .top(32) + .bottom(16)
        
        let stack =
            VStack(spacing: 24,
                   VStack(spacing: 24,
                       VStack(spacing: 16,
                              UILabel(title2: .onboardingConsentTitle).multiline(),
                              TextView(htmlText: .onboardingConsentMessage, textColor: Theme.colors.captionGray)
                                .linkTouched { [unowned self] in self.open($0) }),
                       VStack(spacing: 16,
                              listItem(.onboardingConsentItem1),
                              listItem(.onboardingConsentItem2),
                              listItem(.onboardingConsentItem3),
                              listItem(.onboardingConsentItem4))),
                   VStack(spacing: 24,
                          ConsentButton(title: .onboardingConsentButtonTitle, selected: false).valueChanged(self, action: #selector(consentValueChanged)),
                          continueButton))
                .distribution(.equalSpacing)
                .embed(in: scrollView.readableWidth, insets: margin)
        
        stack.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.safeAreaLayoutGuide.heightAnchor,
                                      multiplier: 1,
                                      constant: -(margin.top + margin.bottom)).isActive = true
    }
    
    @objc private func handleContinue() {
        delegate?.privacyConsentViewControllerWantsToContinue(self)
    }
    
    private func open(_ url: URL) {
        delegate?.privacyConsentViewController(self, wantsToOpen: url)
    }
    
    @objc private func consentValueChanged(_ sender: ConsentButton) {
        viewModel.registerConsent(value: sender.isSelected)
    }
    
}

extension PrivacyConsentViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        adjustNavigationBar(for: scrollView)
    }
    
}

private class ConsentButton: UIButton {
    
    override var isSelected: Bool {
        didSet { applyState() }
    }
    
    override var isEnabled: Bool {
        didSet { applyState() }
    }
    
    override var accessibilityTraits: UIAccessibilityTraits {
        get { return UISwitch().accessibilityTraits }
        set { super.accessibilityTraits = newValue }
    }
    
    override var accessibilityValue: String? {
        get { return isSelected ? "1" : "0" }
        set { super.accessibilityValue = newValue }
    }
    
    var useHapticFeedback = true
    
    required init(title: String = "", selected: Bool = false) {
        icon = UIImageView(image: UIImage(named: "Toggle/Normal"),
                           highlightedImage: UIImage(named: "Toggle/Selected"))
        
        super.init(frame: .zero)
        
        setTitle(title, for: .normal)

        addTarget(self, action: #selector(touchUpAnimation), for: .touchDragExit)
        addTarget(self, action: #selector(touchUpAnimation), for: .touchCancel)
        addTarget(self, action: #selector(touchUpAnimation), for: .touchUpInside)
        addTarget(self, action: #selector(toggle), for: .touchUpInside)
        addTarget(self, action: #selector(touchDownAnimation), for: .touchDown)
        
        icon.tintColor = Theme.colors.primary
        icon.contentMode = .top
        icon.snap(to: .left, of: self, insets: .left(16) + .top(16) + .bottom(16))
        
        isSelected = selected
        
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Private
    
    fileprivate func setup() {
        clipsToBounds = true
        contentEdgeInsets = .topBottom(17) + .left(52) + .right(16)
        
        layer.cornerRadius = 8
        
        titleLabel?.font = Theme.fonts.body
        titleLabel?.lineBreakMode = .byWordWrapping
        titleLabel?.numberOfLines = 0
        
        tintColor = .white
        backgroundColor = Theme.colors.tertiary
        setTitleColor(UIColor(white: 0.235, alpha: 0.85), for: .normal)
        contentHorizontalAlignment = .left
        
        applyState()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        titleLabel?.preferredMaxLayoutWidth = bounds.width - contentEdgeInsets.left - contentEdgeInsets.right
    }
    
    override var intrinsicContentSize: CGSize {
        var base = titleLabel?.intrinsicContentSize ?? .zero
        base.height += contentEdgeInsets.top + contentEdgeInsets.bottom
        base.width += contentEdgeInsets.left + contentEdgeInsets.right
        return base
    }
    
    @discardableResult
    func valueChanged(_ target: Any?, action: Selector) -> Self {
        super.addTarget(target, action: action, for: .valueChanged)
        return self
    }
    
    private func applyState() {
        switch (isSelected, isEnabled) {
        case (true, true):
            icon.tintColor = Theme.colors.primary
            icon.isHighlighted = true
        case (true, false):
            icon.tintColor = Theme.colors.disabledIcon
            icon.isHighlighted = true
        default:
            icon.tintColor = Theme.colors.primary
            icon.isHighlighted = false
        }
    }
    
    @objc private func toggle() {
        isSelected.toggle()
        sendActions(for: .valueChanged)
    }
    
    @objc private func touchDownAnimation() {
        if useHapticFeedback { Haptic.light() }

        UIButton.animate(withDuration: 0.2, animations: {
            self.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        })
    }

    @objc private func touchUpAnimation() {
        UIButton.animate(withDuration: 0.2, animations: {
            self.transform = CGAffineTransform.identity
        })
    }
    
    fileprivate let icon: UIImageView
}
