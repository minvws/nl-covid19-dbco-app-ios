/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

protocol ReversePairViewControllerDelegate: class {
    func reversePairViewControllerWantsToContinue(_ controller: ReversePairViewController)
    func reversePairViewControllerWantsToClose(_ controller: ReversePairViewController)
}

class ReversePairViewModel {
    @Bindable private(set) var isWaitingViewHidden: Bool = false
    @Bindable private(set) var isSuccessViewHidden: Bool = true
    @Bindable private(set) var isContinueButtonEnabled: Bool = false
    @Bindable private(set) var pairingCode: NSAttributedString?
    
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
        
        pairingCode = NSAttributedString(string: codeSegments.joined(separator: "-"),
                                         attributes: attributes)
    }
    
    func showPairingSuccessful() {
        isWaitingViewHidden = true
        isSuccessViewHidden = false
        isContinueButtonEnabled = true
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
        if #available(iOS 14.0, *) {
            navigationItem.backButtonDisplayMode = .generic
        }
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: .close, style: .plain, target: self, action: #selector(close))
        title = "Koppelen"
        
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
        codeContainerView.heightAnchor.constraint(equalToConstant: 80).isActive = true
        
        let codeLabel = Label(nil, font: .monospacedDigitSystemFont(ofSize: 22, weight: .semibold))
        codeLabel.textAlignment = .center
        codeLabel.embed(in: codeContainerView)
        
        viewModel.$pairingCode.binding = { codeLabel.attributedText = $0 }
        
        let step2IconView: UIView = ImageView(imageName: "Step2").asIcon()
        
        let statusContainerView = UIView()
        statusContainerView.backgroundColor = Theme.colors.graySeparator
        statusContainerView.layer.cornerRadius = 8
        statusContainerView.heightAnchor.constraint(equalToConstant: 80).isActive = true
        
        let activityIndicator = UIActivityIndicatorView(style: .gray)
        activityIndicator.startAnimating()
        activityIndicator.setContentHuggingPriority(.required, for: .horizontal)
        
        let waitingView = HStack(spacing: 8,
                                 activityIndicator,
                                 Label(body: "Wachten op GGD-medewerker", textColor: Theme.colors.captionGray).multiline())
            .withInsets(.left(24))
        
        let successView = VStack(HStack(spacing: 8,
                                        ImageView(imageName: "ListItem/Checkmark").asIcon(),
                                        Label(body: "Gekoppeld met GGD", textColor: Theme.colors.captionGray)))
            .alignment(.center)
        
        viewModel.$isWaitingViewHidden.binding = { waitingView.isHidden = $0 }
        viewModel.$isSuccessViewHidden.binding = { successView.isHidden = $0 }
        
        VStack(waitingView, successView)
            .embed(in: statusContainerView)
        
        VStack(spacing: 24,
               VStack(spacing: 16,
                      Label(title2: "Koppel de app met de GGD om je gegevens te delen").multiline(),
                      Label(body: "Heb je de app nog niet gekoppeld? Dan belt de GGD je om dit samen te doen. Daarna kun je via de app contactgegevens en locaties delen.", textColor: Theme.colors.captionGray).multiline()),
               VStack(spacing: 16,
                      HStack(spacing: 16,
                             step1IconView,
                             Label(title3: "Geef deze code door aan de GGD-medewerker:").multiline())
                        .alignment(.top),
                      codeContainerView.withInsets(.left(40))),
               VStack(spacing: 16,
                      HStack(spacing: 16,
                             step2IconView,
                             VStack(spacing: 4,
                                    Label(title3: "Wacht tot de GGD-medewerker de code heeft ingevoerd").multiline(),
                                    Label(body: "Wil je ondertussen nog gegevens aanvullen? Dan kun je dit scherm sluiten.", textColor: Theme.colors.captionGray).multiline()))
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
    
    @objc private func handleContinue() {
        delegate?.reversePairViewControllerWantsToContinue(self)
    }
    
    @objc private func close() {
        delegate?.reversePairViewControllerWantsToClose(self)
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
    
    func showPairingSuccessful() {
        viewModel.showPairingSuccessful()
    }

}
