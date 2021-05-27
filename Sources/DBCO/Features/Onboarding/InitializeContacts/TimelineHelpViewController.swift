/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

protocol TimelineHelpViewControllerDelegate: AnyObject {
    func timelineHelpViewControllerDidSelectClose(_ controller: TimelineHelpViewController)
}

class TimelineHelpViewModel {
    
}

class TimelineHelpViewController: ViewController {
    private let viewModel: TimelineHelpViewModel
    
    weak var delegate: TimelineHelpViewControllerDelegate?

    init(viewModel: TimelineHelpViewModel) {
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
        
        title = .contactsTimelineHelpTitle
        
        let scrollView = UIScrollView(frame: .zero)
        scrollView.embed(in: view)
        scrollView.contentWidth(equalTo: view)
        
        VStack(spacing: 16,
               UILabel(body: .contactsTimelineHelpMessage,
                       textColor: Theme.colors.captionGray),
               listItem(.contactsTimelineHelpItem1),
               listItem(.contactsTimelineHelpItem2),
               listItem(.contactsTimelineHelpItem3))
            .embed(in: scrollView.readableWidth, insets: .topBottom(32))
    }
    
    @objc private func close(_ sender: Any?) {
        delegate?.timelineHelpViewControllerDidSelectClose(self)
    }

}
