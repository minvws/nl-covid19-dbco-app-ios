/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

protocol OverviewTipsViewControllerDelegate: AnyObject {
    func overviewTipsViewControllerWantsClose(_ controller: OverviewTipsViewController)
}

class OverviewTipsViewModel {
    
    var titleText: String {
        let date = Services.caseManager.startOfContagiousPeriod ?? Date()
        
        guard !Calendar.current.isDateInToday(date) else {
            return .overviewTipsTitleTodayOnly
        }
        
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = .display
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
        
        let scrollView = UIScrollView(frame: .zero)
            .embed(in: view)
            .contentWidth(equalTo: view)
        
        setupContent(with: scrollView)
    }
    
    private func createHeaderView() -> UIView {
        let imageContainerView = UIView()
        
        let headerImage = UIImage(named: "Onboarding2")!
        let imageView = UIImageView(image: headerImage)
        imageView.contentMode = .scaleAspectFit
        imageView.widthAnchor.constraint(greaterThanOrEqualTo: imageView.heightAnchor, multiplier: headerImage.size.width / headerImage.size.height).isActive = true
        
        imageView.embed(in: imageContainerView)
        
        return imageContainerView
    }
    
    private func setupContent(with scrollView: UIScrollView) {
        VStack(spacing: 40,
               createHeaderView(),
               VStack(spacing: 16,
                      UILabel(title2: viewModel.titleText),
                      UILabel(body: .overviewTipsMessage, textColor: Theme.colors.tipItemColor)),
               VStack(spacing: 16,
                      createSectionHeader(icon: "EditContact/Section1", title: .overviewTipsSection1Title),
                      UILabel(body: .overviewTipsSection1Intro, textColor: Theme.colors.tipItemColor),
                      VStack(spacing: 12,
                             createTipItem(icon: "MemoryTips/Photos", text: .overviewTipsSection1Photos),
                             createTipItem(icon: "MemoryTips/Calendar", text: .overviewTipsSection1Calendar),
                             createTipItem(icon: "MemoryTips/SocialMedia", text: .overviewTipsSection1SocialMedia),
                             createTipItem(icon: "MemoryTips/Transactions", text: .overviewTipsSection1Transactions)),
                      UILabel(bodyBold: .overviewTipsSection1ActivitiesIntro),
                      VStack(spacing: 12,
                             createTipItem(icon: "MemoryTips/Car", text: .overviewTipsSection1Car),
                             createTipItem(icon: "MemoryTips/Meetings", text: .overviewTipsSection1Meetings),
                             createTipItem(icon: "MemoryTips/Conversations", text: .overviewTipsSection1Conversations))),
               VStack(spacing: 16,
                      createSectionHeader(icon: "EditContact/Section2", title: .overviewTipsSection2Title),
                      VStack(spacing: 12,
                             UILabel(body: .overviewTipsSection2Intro, textColor: Theme.colors.tipItemColor),
                             VStack(spacing: 16,
                                    createTipItem(icon: "ListItem/Checkmark", text: .overviewTipsSection2Item1),
                                    createTipItem(icon: "ListItem/Checkmark", text: .overviewTipsSection2Item2),
                                    createTipItem(icon: "ListItem/Questionmark", text: .overviewTipsSection2Item3)))))
            .embed(in: scrollView.readableWidth, insets: .top(16) + .bottom(16))
    }
    
    private func createTipItem(icon: String, text: String) -> UIView {
        let icon = UIImageView(image: UIImage(named: icon))
        icon.contentMode = .top
        icon.widthAnchor.constraint(equalToConstant: 22).isActive = true
        
        return HStack(spacing: 16,
                      icon,
                      UILabel(body: text, textColor: Theme.colors.tipItemColor))
    }
    
    private func createSectionHeader(icon: String, title: String) -> UIView {
        return HStack(spacing: 8,
                      UIImageView(imageName: icon).asIcon(),
                      UILabel(title2: title))
    }
    
    @objc private func close() {
        delegate?.overviewTipsViewControllerWantsClose(self)
    }

}
