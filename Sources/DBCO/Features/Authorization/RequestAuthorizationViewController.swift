/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

enum AuthorizationStatus {
    case notDetermined
    case restricted
    case denied
    case authorized
}

protocol AuthorizationStatusConvertible {
    var status: AuthorizationStatus { get }
}

extension AuthorizationStatus: AuthorizationStatusConvertible {
    var status: AuthorizationStatus {
        return self
    }
}

struct RequestAuthorizationViewConfiguration {
    let title: String?
    let body: String?
    let hideAuthorizeButton: Bool
    let hideSettingsButton: Bool
}

protocol RequestAuthorizationViewModel {
    var authorizeButtonTitle: String { get }
    var continueButtonTitle: String { get }
    var settingsButtonTitle: String { get }

    func configure(for status: AuthorizationStatusConvertible) -> RequestAuthorizationViewConfiguration
}

protocol RequestAuthorizationViewControllerDelegate: class {
    func requestAuthorization(for controller: RequestAuthorizationViewController)
    func redirectToSettings(for controller: RequestAuthorizationViewController)
    func continueWithoutAuthorization(for controller: RequestAuthorizationViewController)
    func currentAutorizationStatus(for controller: RequestAuthorizationViewController) -> AuthorizationStatusConvertible
}

class RequestAuthorizationViewController: ViewController {
    private var didBecomeActiveObserver: NSObjectProtocol?
    private let viewModel: RequestAuthorizationViewModel
    
    weak var delegate: RequestAuthorizationViewControllerDelegate?
    
    init(viewModel: RequestAuthorizationViewModel) {
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
        
        setupView()
        requestAuthorizationStatus()
        startReceivingDidBecomeActiveNotifications()
    }
    
    private func setupView() {
        titleLabel.font = Theme.fonts.title1
        titleLabel.numberOfLines = 0
        
        bodyLabel.font = Theme.fonts.body
        bodyLabel.textColor = Theme.colors.captionGray
        bodyLabel.numberOfLines = 0
        
        authorizeButton.title = viewModel.authorizeButtonTitle
        authorizeButton.touchUpInside(self, action: #selector(authorize))
        
        let continueButton = Button(title: viewModel.continueButtonTitle, style: .secondary)
            .touchUpInside(self, action: #selector(continueWithoutAuthorization))
        
        settingsButton.title = viewModel.settingsButtonTitle
        settingsButton.touchUpInside(self, action: #selector(redirectToSettings))
        
        let containerView = UIStackView(vertical: [
            UIStackView(vertical: [titleLabel, bodyLabel], spacing: 10),
            UIStackView(vertical: [authorizeButton, settingsButton, continueButton], spacing: 10)
        ])
        
        containerView.distribution = .equalSpacing
        
        containerView.embed(in: view.readableContentGuide, insets: .topBottom(16))
    }
    
    override func applicationDidBecomeActive() {
        super.applicationDidBecomeActive()
        
        requestAuthorizationStatus()
    }
    
    private func requestAuthorizationStatus() {
        guard let status = delegate?.currentAutorizationStatus(for: self) else { return }
        let configuration = viewModel.configure(for: status)
        
        titleLabel.text = configuration.title
        bodyLabel.text = configuration.body
        authorizeButton.isHidden = configuration.hideAuthorizeButton
        settingsButton.isHidden = configuration.hideSettingsButton
    }
    
    @objc private func authorize() {
        delegate?.requestAuthorization(for: self)
    }
    
    @objc private func continueWithoutAuthorization() {
        delegate?.continueWithoutAuthorization(for: self)
    }
    
    
    @objc private func redirectToSettings() {
        delegate?.redirectToSettings(for: self)
    }
    
    private let titleLabel = UILabel()
    private let bodyLabel = UILabel()
    private let authorizeButton = Button()
    private let settingsButton = Button()

}
