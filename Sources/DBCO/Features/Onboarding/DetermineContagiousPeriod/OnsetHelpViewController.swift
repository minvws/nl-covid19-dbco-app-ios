/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

protocol OnsetHelpViewControllerDelegate: class {
    func onsetHelpViewControllerDidSelectClose(_ controller: OnsetHelpViewController)
}

class OnsetHelpViewModel {
    
}

class OnsetHelpViewController: ViewController {
    private let viewModel: OnsetHelpViewModel
    
    weak var delegate: OnsetHelpViewControllerDelegate?

    init(viewModel: OnsetHelpViewModel) {
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
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: .close, style: .plain, target: self, action: #selector(close))
        
        title = .contagiousPeriodOnsetDateHelpTitle
        
        let scrollView = UIScrollView(frame: .zero)
        scrollView.embed(in: view)
        
        let widthProviderView = UIView()
        widthProviderView.snap(to: .top, of: scrollView, height: 0)
        widthProviderView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        
        TextView(htmlText: .contagiousPeriodOnsetDateHelpMessage,
                 font: Theme.fonts.body,
                 textColor: Theme.colors.captionGray,
                 boldTextColor: .black)
            .embed(in: scrollView.readableWidth, insets: .leftRight(16) + .topBottom(32))
    }
    
    @objc private func close(_ sender: Any?) {
        delegate?.onsetHelpViewControllerDidSelectClose(self)
    }

}