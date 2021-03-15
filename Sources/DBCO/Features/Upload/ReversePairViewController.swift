/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

protocol ReversePairViewControllerDelegate: class {
    func reversePairViewControllerWantsToResumePairing(_ controller: ReversePairViewController)
    func reversePairViewControllerWantsToContinue(_ controller: ReversePairViewController)
    func reversePairViewControllerWantsToClose(_ controller: ReversePairViewController)
}

class ReversePairViewModel {
    enum PairingCodeStatus {
        case waiting
        case done(code: NSAttributedString)
        case expired
    }
    
    enum PairingStatus {
        case waiting
        case finished
        case error
    }
    
    @Bindable private(set) var pairingCodeStatus: PairingCodeStatus = .waiting
    @Bindable private(set) var pairingStatus: PairingStatus = .waiting
    
    @Bindable private(set) var isContinueButtonEnabled: Bool = false
    
    func applyPairingCode(_ code: String) {
        var code = code
        var codeSegments = [String]()
        
        stride(from: 0, to: code.count, by: 3).forEach { stride in
            codeSegments.append(String(code.prefix(3)))
            code = String(code.dropFirst(3))
        }
        
        let attributes: [NSAttributedString.Key: Any] = [
            .kern: 6.5
        ]
        
        pairingCodeStatus = .done(code: NSAttributedString(string: codeSegments.joined(separator: "-"),
                                                           attributes: attributes))
    }

    func showPairingSuccessful() {
        pairingStatus = .finished
    }
    
    func showPairingError() {
        pairingStatus = .error
    }
    
    func showPairingCodeExpired() {
        pairingCodeStatus = .expired
    }
    
    func clearPairingCode() {
        pairingCodeStatus = .waiting
    }
    
    func clearError() {
        pairingStatus = .waiting
    }
    
}

class ReversePairViewController: PromptableViewController {
    private let viewModel: ReversePairViewModel
    private let scrollView = UIScrollView(frame: .zero)
    
    weak var delegate: ReversePairViewControllerDelegate?
    
    init(viewModel: ReversePairViewModel) {
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if #available(iOS 13.0, *) {
            isModalInPresentation = true
        }
        
        if #available(iOS 14.0, *) {
            navigationItem.backButtonDisplayMode = .generic
        }
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: .close, style: .plain, target: self, action: #selector(close))
        title = .reversePairingTitle
        
        view.backgroundColor = .white
        
        scrollView.embed(in: contentView)
        scrollView.delaysContentTouches = false
        
        let continueButton = Button(title: .next, style: .primary)
            .touchUpInside(self, action: #selector(handleContinue))
        
        viewModel.$isContinueButtonEnabled.binding = { continueButton.isEnabled = $0 }
        
        promptView = continueButton
        
        let step1IconView: UIView = ImageView(imageName: "Step1").asIcon()
        
        let codeContainerView = UIView()
        codeContainerView.backgroundColor = Theme.colors.graySeparator
        codeContainerView.layer.cornerRadius = 8
        codeContainerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 80).isActive = true
        
        let codeActivityIndicator = ActivityIndicatorView(style: .gray)
        codeActivityIndicator.startAnimating()
        codeActivityIndicator.contentMode = .center
        
        let codeLabel = Label(nil, font: .monospacedDigitSystemFont(ofSize: 22, weight: .semibold))
        codeLabel.textAlignment = .center
        
        let codeExpiredView = createErrorView(label: "De code is verlopen. Geef een nieuwe code door aan de GGD.", button: "Maak nieuwe code")
        
        VStack(codeActivityIndicator, codeLabel, codeExpiredView)
            .embed(in: codeContainerView)
        
        viewModel.$pairingCodeStatus.binding = {
            switch $0 {
            case .done(let code):
                codeLabel.attributedText = code
                
                codeActivityIndicator.isHidden = true
                codeLabel.isHidden = false
                codeExpiredView.isHidden = true
            case .waiting:
                codeActivityIndicator.isHidden = false
                codeLabel.isHidden = true
                codeExpiredView.isHidden = true
            case .expired:
                codeActivityIndicator.isHidden = true
                codeLabel.isHidden = true
                codeExpiredView.isHidden = false
            }
        }
        
        let step2IconView: UIView = ImageView(imageName: "Step2").asIcon()
        
        let statusContainerView = UIView()
        statusContainerView.backgroundColor = Theme.colors.graySeparator
        statusContainerView.layer.cornerRadius = 8
        statusContainerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 80).isActive = true
        
        let activityIndicator = ActivityIndicatorView(style: .gray)
        activityIndicator.startAnimating()
        activityIndicator.setContentHuggingPriority(.required, for: .horizontal)
        
        let waitingView = HStack(spacing: 8,
                                 activityIndicator,
                                 Label(body: .reversePairingWaiting, textColor: Theme.colors.captionGray).multiline())
            .withInsets(.left(24))
        
        let successView = VStack(HStack(spacing: 8,
                                        ImageView(imageName: "ListItem/Checkmark").asIcon(),
                                        Label(body: .reversePairingFinished, textColor: Theme.colors.captionGray)))
            .alignment(.center)
        
        let errorView = createErrorView(label: "Er ging iets mis. Controleer of de GGD de juiste code heeft en of je internetverbinding werkt.", button: "Probeer opnieuw")
        
        VStack(waitingView, successView, errorView)
            .embed(in: statusContainerView)
        
        viewModel.$pairingStatus.binding = {
            successView.isHidden = $0 != .finished
            waitingView.isHidden = $0 != .waiting
            errorView.isHidden = $0 != .error
        }
        
        VStack(spacing: 24,
               VStack(spacing: 16,
                      Label(title2: .reversePairingStep1Title).multiline(),
                      Label(body: .reversePairingStep1Message, textColor: Theme.colors.captionGray).multiline()),
               VStack(spacing: 16,
                      HStack(spacing: 16,
                             step1IconView,
                             Label(title3: .reversePairingStep1Code).multiline())
                        .alignment(.top),
                      codeContainerView.withInsets(.left(40))),
               VStack(spacing: 16,
                      HStack(spacing: 16,
                             step2IconView,
                             VStack(spacing: 4,
                                    Label(title3: .reversePairingStep2Title).multiline(),
                                    Label(body: .reversePairingStep2Message, textColor: Theme.colors.captionGray).multiline()))
                        .alignment(.top),
                      statusContainerView.withInsets(.left(40))))
            .embed(in: scrollView.readableWidth, insets: .top(32) + .bottom(16))
        
        let lineView = UIView()
        lineView.translatesAutoresizingMaskIntoConstraints = false
        lineView.backgroundColor = Theme.colors.graySeparator
        lineView.layer.zPosition = -10
        
        scrollView.addSubview(lineView)
        
        lineView.topAnchor.constraint(equalTo: step1IconView.bottomAnchor, constant: 2).isActive = true
        lineView.bottomAnchor.constraint(equalTo: step2IconView.topAnchor, constant: -2).isActive = true
        lineView.centerXAnchor.constraint(equalTo: step1IconView.centerXAnchor).isActive = true
        lineView.widthAnchor.constraint(equalToConstant: 4).isActive = true
    }
    
    private func createErrorView(label: String, button: String) -> UIView {
        return VStack(Label(body: label, textColor: Theme.colors.captionGray)
                        .textAlignment(.center)
                        .multiline(),
                      Button(title: button, style: .info)
                        .touchUpInside(self, action: #selector(resumePairing)))
            .withInsets(.top(16) + .leftRight(16))
    }
    
    @objc private func handleContinue() {
        delegate?.reversePairViewControllerWantsToContinue(self)
    }
    
    @objc private func close() {
        delegate?.reversePairViewControllerWantsToClose(self)
    }
    
    @objc private func resumePairing() {
        delegate?.reversePairViewControllerWantsToResumePairing(self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let scrollingHeight = scrollView.contentSize.height + scrollView.safeAreaInsets.top + scrollView.safeAreaInsets.bottom
        let canScroll = scrollingHeight > scrollView.frame.height
        showPromptViewSeparator = canScroll
    }
    
    func applyPairingCode(_ code: String) {
        viewModel.applyPairingCode(code)
    }
    
    func showPairingCodeExpired() {
        viewModel.showPairingCodeExpired()
    }
    
    func clearPairingCode() {
        viewModel.clearPairingCode()
    }
    
    func showError() {
        viewModel.showPairingError()
    }
    
    func clearError() {
        viewModel.clearError()
    }
    func showPairingSuccessful() {
        viewModel.showPairingSuccessful()
    }

}
