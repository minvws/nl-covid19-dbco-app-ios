/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

protocol OverviewTipsViewControllerDelegate: class {
    func overviewTipsViewControllerWantsClose(_ controller: OverviewTipsViewController)
}

class OverviewTipsViewModel {
    
    var titleText: String {
        let date = Services.caseManager.dateOfSymptomOnset
        
        guard !Calendar.current.isDateInToday(date) else {
            return .overviewTipsTitleTodayOnly
        }
        
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale.current
        formatter.dateFormat = .overviewTipsTitleDateFormat
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
    
        return .overviewTipsTitle(date: formatter.string(from: date))
    }
}

class OverviewTipsViewController: ViewController {
    private let viewModel: OverviewTipsViewModel
    
    weak var delegate: OverviewTipsViewControllerDelegate?
    
    init(viewModel: OverviewTipsViewModel) {
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: .close, style: .plain, target: self, action: #selector(close))
        title = .overviewTipsShortTitle
        
        view.backgroundColor = .white
        
        let scrollView = UIScrollView(frame: .zero).embed(in: view)
        
        let widthProviderView = UIView()
        widthProviderView.snap(to: .top, of: scrollView, height: 0)
        widthProviderView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        
        func createTipItem(icon: String, text: String) -> UIView {
            let icon = UIImageView(image: UIImage(named: icon))
            icon.contentMode = .top
            icon.widthAnchor.constraint(equalToConstant: 22).isActive = true
            
            return HStack(spacing: 16,
                          icon,
                          Label(body: text, textColor: Theme.colors.tipItemColor).multiline())
        }
        
        func createSectionHeader(icon: String, title: String) -> UIView {
            return HStack(spacing: 8,
                          ImageView(imageName: icon).asIcon(),
                          Label(title2: title))
        }
        
        let imageContainerView = UIView()
        
        let headerImage = UIImage(named: "Onboarding2")!
        let imageView = UIImageView(image: headerImage)
        imageView.contentMode = .scaleAspectFit
        imageView.widthAnchor.constraint(greaterThanOrEqualTo: imageView.heightAnchor, multiplier: headerImage.size.width / headerImage.size.height).isActive = true
        
        imageView.embed(in: imageContainerView)
        
        VStack(spacing: 40,
               imageContainerView,
               VStack(spacing: 16,
                      Label(title2: viewModel.titleText).multiline(),
                      Label(body: .overviewTipsMessage, textColor: Theme.colors.tipItemColor).multiline()),
               VStack(spacing: 16,
                      createSectionHeader(icon: "EditContact/Section1", title: .overviewTipsSection1Title),
                      Label(body: .overviewTipsSection1Intro, textColor: Theme.colors.tipItemColor).multiline(),
                      VStack(spacing: 12,
                             createTipItem(icon: "MemoryTips/Photos", text: .overviewTipsSection1Photos),
                             createTipItem(icon: "MemoryTips/Calendar", text: .overviewTipsSection1Calendar),
                             createTipItem(icon: "MemoryTips/SocialMedia", text: .overviewTipsSection1SocialMedia),
                             createTipItem(icon: "MemoryTips/Transactions", text: .overviewTipsSection1Transactions)),
                      Label(bodyBold: .overviewTipsSection1ActivitiesIntro).multiline(),
                      VStack(spacing: 12,
                             createTipItem(icon: "MemoryTips/Car", text: .overviewTipsSection1Car),
                             createTipItem(icon: "MemoryTips/Meetings", text: .overviewTipsSection1Meetings),
                             createTipItem(icon: "MemoryTips/Conversations", text: .overviewTipsSection1Conversations))),
               VStack(spacing: 16,
                      createSectionHeader(icon: "EditContact/Section2", title: .overviewTipsSection2Title),
                      VStack(spacing: 12,
                             Label(body: .overviewTipsSection2Intro, textColor: Theme.colors.tipItemColor).multiline(),
                             VStack(spacing: 16,
                                    createTipItem(icon: "ListItem/Checkmark", text: .overviewTipsSection2Item1),
                                    createTipItem(icon: "ListItem/Checkmark", text: .overviewTipsSection2Item2),
                                    createTipItem(icon: "ListItem/Questionmark", text: .overviewTipsSection2Item3)))))
            .embed(in: scrollView.readableWidth, insets: .top(16) + .bottom(16))
    }
    
    @objc private func close() {
        delegate?.overviewTipsViewControllerWantsClose(self)
    }

}