/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

protocol PairViewControllerDelegate: AnyObject {
    func pairViewController(_ controller: PairViewController, wantsToPairWith code: String)
}

class PairViewModel {}

/// - Tag: PairViewController
class PairViewController: ViewController {
    private let viewModel: PairViewModel
    
    private let scrollView = UIScrollView()
    private let codeField =
        CodeField(with: CodeDescription(digitGroupSize: 4,
                                        numberOfGroups: 3,
                                        accessibilityLabel: .onboardingPairingTitle,
                                        accessibilityHint: .onboardingPairingCodeHint,
                                        adjustKerningForWidth: true))
    
    private let loadingOverlay = UIView()
    private let loadingIndicator = ActivityIndicatorView(style: .white)
    private var keyboardSpacerHeightConstraint: NSLayoutConstraint!
    
    weak var delegate: PairViewControllerDelegate?
    
    init(viewModel: PairViewModel) {
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.backgroundColor = .white

        let titleLabel = UILabel(title2: .onboardingPairingTitle).multiline()
        
        let keyboardSpacerView = UIView()
        keyboardSpacerHeightConstraint = keyboardSpacerView.heightAnchor.constraint(equalToConstant: 0)
        keyboardSpacerHeightConstraint.isActive = true
        
        let nextButton = Button(title: .next, style: .primary)
            .touchUpInside(self, action: #selector(pair))
        
        nextButton.isEnabled = false
        codeField.didUpdatePairingCode { nextButton.isEnabled = $0 != nil }
        
        let topMargin: CGFloat = UIScreen.main.bounds.height < 600 ? 16 : 66
        
        let containerView =
            VStack(spacing: 32,
                   VStack(spacing: 16,
                          titleLabel,
                          codeField),
                   VStack(spacing: 20,
                          nextButton,
                          keyboardSpacerView))
            .distribution(.equalSpacing)
        
        containerView.embed(in: scrollView.readableWidth, insets: .top(topMargin))
        
        containerView.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.safeAreaLayoutGuide.heightAnchor, multiplier: 1, constant: -topMargin).isActive = true
        
        scrollView.embed(in: view)
        scrollView.delegate = self
        
        loadingOverlay.backgroundColor = UIColor(white: 0, alpha: 0.4)
        loadingOverlay.embed(in: view)
        loadingOverlay.isHidden = true
        
        loadingOverlay.addSubview(loadingIndicator)
        loadingIndicator.color = .white
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.centerYAnchor.constraint(equalTo: nextButton.centerYAnchor).isActive = true
        loadingIndicator.trailingAnchor.constraint(equalTo: nextButton.trailingAnchor, constant: -16).isActive = true
        loadingIndicator.startAnimating()
        
        registerForKeyboardNotifications()
    }
    
    func startLoadingAnimation() {
        loadingOverlay.isHidden = false
        loadingOverlay.alpha = 0
        codeField.isIgnoringInput = true
        
        UIAccessibility.post(notification: .announcement, argument: String.loading)
        
        UIView.animate(withDuration: 0.3) {
            self.loadingOverlay.alpha = 1
        }
    }
    
    func stopLoadingAnimation() {
        UIView.animate(withDuration: 0.3, delay: 0.1, options: [], animations: {
            self.loadingOverlay.alpha = 0
        }, completion: { _ in
            self.loadingOverlay.isHidden = true
            self.codeField.isIgnoringInput = false
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: animated)
        codeField.becomeFirstResponder()
    }
    
    @objc private func pair() {
        guard let code = codeField.code else {
            return
        }
        
        delegate?.pairViewController(self, wantsToPairWith: code)
    }
    
    // MARK: - Keyboard handling
    
    private func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIWindow.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIWindow.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }
        let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? .zero
        let convertedFrame = view.window?.convert(endFrame, to: view)
        
        let inset = view.frame.maxY - (convertedFrame?.minY ?? 0) - view.safeAreaInsets.bottom
        
        keyboardSpacerHeightConstraint.constant = inset
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        keyboardSpacerHeightConstraint.constant = 0
    }
}

// MARK: - UIScrollViewDelegate

extension PairViewController: UIScrollViewDelegate {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        codeField.resignFirstResponder() // Hide keyboard on scroll
    }
}
