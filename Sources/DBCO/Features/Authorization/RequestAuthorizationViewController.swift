/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit
import Combine

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

protocol RequestAuthorizationViewModel {
    var title: AnyPublisher<String?, Never> { get }
    var body: AnyPublisher<String?, Never> { get }
    var hideAuthorizeButton: AnyPublisher<Bool, Never> { get }
    var hideSettingsButton: AnyPublisher<Bool, Never> { get }
    
    var authorizeButtonTitle: String { get }
    var continueButtonTitle: String { get }
    var settingsButtonTitle: String { get }

    func configure(for status: AuthorizationStatusConvertible)
}

protocol RequestAuthorizationViewControllerDelegate: class {
    func requestAuthorization(for controller: RequestAuthorizationViewController)
    func redirectToSettings(for controller: RequestAuthorizationViewController)
    func continueWithoutAuthorization(for controller: RequestAuthorizationViewController)
    func currentAutorizationStatus(for controller: RequestAuthorizationViewController) -> AuthorizationStatusConvertible
}

class RequestAuthorizationViewController: ViewController {
    private var didBecomeActiveObserver: NSObjectProtocol?
    private var cancellables = Set<AnyCancellable>()
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
        
        requestAuthorizationStatus()
        startReceivingDidBecomeActiveNotifications()
        setupView()
    }
    
    private func setupView() {
        let titleLabel = UILabel()
        titleLabel.font = Theme.fonts.title1
        titleLabel.numberOfLines = 0
    
        viewModel.title
            .assign(to: \.text, on: titleLabel)
            .store(in: &cancellables)
        
        let bodyLabel = UILabel()
        bodyLabel.font = Theme.fonts.body
        bodyLabel.numberOfLines = 0
        
        viewModel.body
            .assign(to: \.text, on: bodyLabel)
            .store(in: &cancellables)
        
        let authorizeButton = Button(title: viewModel.authorizeButtonTitle)
            .touchUpInside(self, action: #selector(authorize))
        
        viewModel.hideAuthorizeButton
            .assign(to: \.isHidden, on: authorizeButton)
            .store(in: &cancellables)
        
        let continueButton = Button(title: viewModel.continueButtonTitle, style: .secondary)
            .touchUpInside(self, action: #selector(continueWithoutAuthorization))
        
        let settingsButton = Button(title: viewModel.settingsButtonTitle)
            .touchUpInside(self, action: #selector(redirectToSettings))
        
        viewModel.hideSettingsButton
            .assign(to: \.isHidden, on: settingsButton)
            .store(in: &cancellables)
        
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
        viewModel.configure(for: status)
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

}
