/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

protocol ContactsExplanationViewControllerDelegate: class {
    func contactsExplanationViewControllerWantsToContinue(_ controller: ContactsExplanationViewController)
}

class ContactsExplanationViewModel {
    
}

/// - Tag: ContactsExplanationViewControlle
class ContactsExplanationViewController: PromptableViewController {
    private let viewModel: ContactsExplanationViewModel
    private let scrollView = UIScrollView(frame: .zero)
    
    weak var delegate: ContactsExplanationViewControllerDelegate?
    
    init(viewModel: ContactsExplanationViewModel) {
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
        
        scrollView.embed(in: contentView)
        scrollView.delaysContentTouches = false
        
        let headerBackgroundView = UIView(frame: .zero)
        headerBackgroundView.backgroundColor = .white
        
        headerBackgroundView.snap(to: .top, of: contentView)
        headerBackgroundView.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor).isActive = true
        
        let widthProviderView = UIView()
        widthProviderView.snap(to: .top, of: scrollView, height: 0)
        widthProviderView.widthAnchor.constraint(equalTo: contentView.widthAnchor).isActive = true
        
        func listItem(_ text: String, icon: String) -> UIView {
            let iconView = UIImageView(image: UIImage(named: "ListItem/\(icon)"))
            iconView.contentMode = .center
            iconView.setContentHuggingPriority(.required, for: .horizontal)
            
            return HStack(spacing: 16,
                          iconView,
                          Label(body: text, textColor: Theme.colors.captionGray).multiline())
                .alignment(.top)
        }
        
        let margin: UIEdgeInsets = .top(32) + .bottom(18) + .right(16)
        
        let stack =
            VStack(spacing: 24,
                   VStack(spacing: 24,
                       VStack(spacing: 16,
                              Label(title2: "We gaan een overzicht maken van mensen die je hebt ontmoet").multiline(),
                              Label(body: "Niet iedereen die je hebt ontmoet heeft risico op besmetting gelopen. We zijn op zoek naar mensen met wie je:", textColor: Theme.colors.captionGray).multiline()),
                       VStack(spacing: 16,
                              listItem("Langer dan 15 minuten in dezelfde ruimte bent geweest", icon: "Checkmark"),
                              listItem("Intens contact hebt gehad door zoenen of seksueel contact", icon: "Checkmark"),
                              listItem("Twijfel je? Voeg de persoon dan toch toe", icon: "Questionmark"),
                              listItem("Je hoeft je huisgenoten niet nog een keer toe te voegen", icon: "Stop"))),
                   UIView()) // Empty view for spacing
                .distribution(.equalSpacing)
                .embed(in: scrollView.readableWidth, insets: margin)
        
        stack.heightAnchor.constraint(greaterThanOrEqualTo: contentView.safeAreaLayoutGuide.heightAnchor,
                                      multiplier: 1,
                                      constant: -(margin.top + margin.bottom)).isActive = true
        
        promptView = Button(title: .next, style: .primary)
            .touchUpInside(self, action: #selector(handleContinue))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        navigationController?.hidesBarsOnSwipe = false
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let scrollingHeight = scrollView.contentSize.height + scrollView.safeAreaInsets.top + scrollView.safeAreaInsets.bottom
        let canScroll = scrollingHeight > scrollView.frame.height
        showPromptViewSeparator = canScroll
        
        navigationController?.hidesBarsOnSwipe = canScroll
    }
    
    @objc private func handleContinue() {
        delegate?.contactsExplanationViewControllerWantsToContinue(self)
    }
    
}
