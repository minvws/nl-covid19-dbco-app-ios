/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

protocol SelectRoommatesViewControllerDelegate: class {
    func selectRoommatesViewController(_ controller: SelectRoommatesViewController, didSelect roommates: [String])
}

class SelectRoommatesViewModel {
    
}

class SelectRoommatesViewController: ViewController {
    private let viewModel: SelectRoommatesViewModel
    private let navigationBackgroundView = UIView()
    private let separatorView = SeparatorView()
    
    private let scrollView = UIScrollView(frame: .zero)
    
    weak var delegate: SelectRoommatesViewControllerDelegate?
    
    init(viewModel: SelectRoommatesViewModel) {
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
        scrollView.keyboardDismissMode = .onDrag
        scrollView.delegate = self
        
        navigationBackgroundView.backgroundColor = .white
        navigationBackgroundView.snap(to: .top, of: view)
        
        navigationBackgroundView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        
        separatorView.snap(to: .top, of: view.safeAreaLayoutGuide)
        
        let margin: UIEdgeInsets = .top(32) + .bottom(16)

        let stack =
            VStack(spacing: 24,
                   VStack(spacing: 16,
                          Label(title2: "Wie zijn je huisgenoten?").multiline(),
                          Label(body: "Dit zijn de mensen met wie je in één huis woont.", textColor: Theme.colors.captionGray).multiline()),
                   ContactListInputView(placeholder: "Voeg huisgenoot toe"),
                   Button(title: .next, style: .primary).touchUpInside(self, action: #selector(handleContinue)))
                .distribution(.fill)
                .embed(in: scrollView.readableWidth, insets: margin)
        
        stack.heightAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.heightAnchor,
                                      multiplier: 1,
                                      constant: -(margin.top + margin.bottom)).isActive = true
        
        registerForKeyboardNotifications()
    }
    
    @objc private func handleContinue() {
        delegate?.selectRoommatesViewController(self, didSelect: [])
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
        
        let inset = view.frame.maxY - (convertedFrame?.minY ?? 0)
        
        scrollView.contentInset.bottom = inset
        scrollView.verticalScrollIndicatorInsets.bottom = inset
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset = .zero
        scrollView.verticalScrollIndicatorInsets.bottom = .zero
    }

}

extension SelectRoommatesViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        UIView.animate(withDuration: 0.2) {
            if scrollView.contentOffset.y + scrollView.safeAreaInsets.top > 0 {
                self.separatorView.alpha = 1
                self.navigationBackgroundView.isHidden = false
                self.navigationItem.title = "Huisgenoten"
            } else {
                self.separatorView.alpha = 0
                self.navigationBackgroundView.isHidden = true
                self.navigationItem.title = nil
            }
        }
    }
    
}
