/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

/// Adopters of this protocol expose an onDismissed callback property that is called whenever the object is dismissed
/// - Tag: DismissActionable
protocol DismissActionable {
    associatedtype Item
    
    var onDismissed: ((Item) -> Void)? { get set }
}

/// Adopters of this protocol expose an onPopped callback property that is called whenever the object is popped from a navigation stack
/// - Tag: PopActionable
protocol PopActionable {
    associatedtype Item
    
    var onPopped: ((Item) -> Void)? { get set }
}

protocol KeyboardActionable {
    func keyboardWillShow(with convertedFrame: CGRect, notification: NSNotification)
    func keyboardWillHide(notification: NSNotification)
    
    var keyboardFrameTargetView: UIView { get }
}

/// A UIViewController subclass to be used as base for ViewController in the app.
/// Conforms to [DismissActionable](x-source-tag://DismissActionable) and [PopActionable](x-source-tag://PopActionable)
///
/// - Tag: ViewController
class ViewController: UIViewController, DismissActionable, PopActionable {
    var onDismissed: ((ViewController) -> Void)?
    var onPopped: ((ViewController) -> Void)?
    
    /// Override this method to receive applicationDidBecomeActive notifications
    /// Requires `startReceivingDidBecomeActiveNotifications()` to be called, to start observing the required notifications
    func applicationDidBecomeActive() {
        
    }

    func startReceivingDidBecomeActiveNotifications() {
        shouldAddDidBecomeActiveObserver = true
    }
    
    func stopReceivingDidBecomeActiveNotifications() {
        shouldAddDidBecomeActiveObserver = false
        removeDidBecomeActiveObserverIfNeeded()
    }
    
    private var didBecomeActiveObserver: NSObjectProtocol?
    private var shouldAddDidBecomeActiveObserver = false
    private var needsFocus = true
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self is KeyboardActionable {
            NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillShow), name: UIWindow.keyboardWillShowNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillHide), name: UIWindow.keyboardWillHideNotification, object: nil)
        }
    }

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
        
        // Move focus to the first header when the ViewControler appears for the first time.
        if needsFocus {
            needsFocus = false
            
            UIAccessibility.screenChanged(self)

            if let header = view.find(traits: .header) {
                UIAccessibility.layoutChanged(header)
            }
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all // Allows all orientations on all devices
    }
    
    private func removeDidBecomeActiveObserverIfNeeded() {
        if let observer = didBecomeActiveObserver {
            NotificationCenter.default.removeObserver(observer)
            didBecomeActiveObserver = nil
        }
    }
    
    @objc private func handleKeyboardWillShow(notification: NSNotification) {
        guard let actionable = self as? KeyboardActionable else { return }
        guard let userInfo = notification.userInfo else { return }
        
        let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? .zero
        let convertedFrame = view.window?.convert(endFrame, to: actionable.keyboardFrameTargetView) ?? .zero
        
        actionable.keyboardWillShow(with: convertedFrame, notification: notification)
    }

    @objc private func handleKeyboardWillHide(notification: NSNotification) {
        guard let actionable = self as? KeyboardActionable else { return }
        actionable.keyboardWillHide(notification: notification)
    }
}

extension KeyboardActionable where Self: ViewController {
    var keyboardFrameTargetView: UIView { view }
}
