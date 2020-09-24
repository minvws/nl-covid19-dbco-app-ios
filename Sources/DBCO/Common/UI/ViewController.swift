/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

protocol DismissActionable {
    associatedtype Item
    
    var onDismissed: ((Item) -> Void)? { get set }
}

protocol PopActionable {
    associatedtype Item
    
    var onPopped: ((Item) -> Void)? { get set }
}

class ViewController: UIViewController, DismissActionable, PopActionable {
    var onDismissed: ((ViewController) -> Void)?
    var onPopped: ((ViewController) -> Void)?
    
    func applicationDidBecomeActive() {
        
    }
    
    func startReceivingDidBecomeActiveNotifications() {
        shouldAddDidBecomeActiveObserver = true
        
    }
    
    func stopReceivingDidBecomeActiveNotifications() {
        shouldAddDidBecomeActiveObserver = false
    }
    
    private var didBecomeActiveObserver: NSObjectProtocol?
    private var shouldAddDidBecomeActiveObserver = false
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        removeDidBecomeActiveObserverIfNeeded()
        
        if isBeingDismissed || navigationController?.isBeingDismissed == true || tabBarController?.isBeingDismissed == true {
            onDismissed?(self)
        } else if isMovingFromParent {
            onPopped?(self)
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if shouldAddDidBecomeActiveObserver {
            didBecomeActiveObserver = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
                self?.applicationDidBecomeActive()
            }
        }
    }
    
    private func removeDidBecomeActiveObserverIfNeeded() {
        if let observer = didBecomeActiveObserver {
            NotificationCenter.default.removeObserver(observer)
            didBecomeActiveObserver = nil
        }
    }
}

class PromptableViewController: ViewController {
    
    private class PromptView: UIView {
        var contentView = UIView()
        var promptContainerView = UIView()
        var hiddenObserver: Any?
        var promptView: UIView? {
            willSet {
                hiddenObserver = nil
                promptView?.removeFromSuperview()
            }
            
            didSet {
                guard let promptView = promptView else { return }
                
                
                promptView.setContentCompressionResistancePriority(.required, for: .vertical)
                promptView.setContentHuggingPriority(.required, for: .vertical)
                
                promptView.embed(in: CustomEmbeddable(view: promptContainerView,
                                                      leadingAnchor: promptContainerView.readableContentGuide.leadingAnchor,
                                                      trailingAnchor: promptContainerView.readableContentGuide.trailingAnchor,
                                                      topAnchor: promptContainerView.topAnchor,
                                                      bottomAnchor: promptContainerView.safeAreaLayoutGuide.bottomAnchor),
                                 insets: .top(12) + .bottom(16))
                
                hiddenObserver = promptView.observe(\.isHidden) { [weak self] view, _ in
                    self?.promptContainerView.isHidden = view.isHidden
                }
                
                promptContainerView.isHidden = promptView.isHidden
            }
        }
        
        init() {
            super.init(frame: .zero)
            preservesSuperviewLayoutMargins = true
            
            contentView.backgroundColor = .white
            contentView.preservesSuperviewLayoutMargins = true
            
            promptContainerView.backgroundColor = .white
            promptContainerView.preservesSuperviewLayoutMargins = true
            
            SeparatorView()
                .snap(to: .top, of: promptContainerView, height: 1)
            
            let stackView = UIStackView(vertical: [contentView, promptContainerView])
            stackView.preservesSuperviewLayoutMargins = true
            stackView.embed(in: self)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    var contentView: UIView {
        return (view as! PromptView).contentView
    }
    
    var promptView: UIView? {
        get {
            (view as! PromptView).promptView
        }
        
        set {
            (view as! PromptView).promptView = newValue
        }
    }
    
    override func loadView() {
        view = PromptView()
    }
    
    func hidePrompt(animated: Bool = true) {
        // Expands the view so the prompt container will be outside of the screen (animated)
        // Then hides the prompt container and restores the view's height
        
        guard promptView?.isHidden == false else {
            return
        }
        
        let originalFrame = self.view.frame
        
        var frame = view.frame
        frame.size.height += (view as! PromptView).promptContainerView.frame.height
        view.frame = frame
        
        UIView.animate(
            withDuration: 0.3,
            animations: {
                self.view.layoutIfNeeded()
            },
            completion: { _ in
                self.promptView?.isHidden = true
                self.promptView?.layoutIfNeeded()
                self.view.frame = originalFrame
            })
    }
    
    func showPrompt(animated: Bool = true) {
        // Shows the prompt container
        // Then expands the view so the prompt container will be outside of the screen
        // Then restores view's original height (animated)
        
        guard promptView?.isHidden == true else {
            return
        }
        
        let originalFrame = self.view.frame
        
        promptView?.isHidden = false
        
        self.view.layoutIfNeeded()
        
        var frame = view.frame
        frame.size.height += (view as! PromptView).promptContainerView.frame.height
        view.frame = frame
        
        self.view.layoutIfNeeded()
        
        self.view.frame = originalFrame
        
        UIView.animate(
            withDuration: 0.3,
            animations: {
                self.view.layoutIfNeeded()
            })
    }
    
}
