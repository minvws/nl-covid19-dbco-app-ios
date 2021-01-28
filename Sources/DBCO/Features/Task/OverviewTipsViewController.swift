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
            return "Maak een compleet overzicht van mensen die je vandaag hebt ontmoet"
        }
        
        let titleFormat = "Maak een compleet overzicht van mensen die je hebt ontmoet tussen %@ en vandaag"
        
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale.current
        formatter.dateFormat = "d MMMM"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
    
        return String(format: titleFormat, formatter.string(from: date))
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
        title = "Tips"
        
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
            let imageView = UIImageView(image: UIImage(named: icon))
            imageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            imageView.contentMode = .center
            
            return HStack(spacing: 8,
                          imageView,
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
                      Label(body: "Het is belangrijk dat we weten wie kans hebben gelopen besmet te zijn geraakt. Zo kunnen deze mensen op tijd worden geïnformeerd. Dit helpt om verdere verspreiding van het coronavirus te stoppen.", textColor: Theme.colors.tipItemColor).multiline()),
               VStack(spacing: 16,
                      createSectionHeader(icon: "EditContact/Section1", title: "Bedenk wat je hebt gedaan"),
                      Label(body: "Deze dingen kunnen je geheugen opfrissen:", textColor: Theme.colors.tipItemColor).multiline(),
                      VStack(spacing: 12,
                             createTipItem(icon: "MemoryTips/Photos", text: "Foto’s van of met jou"),
                             createTipItem(icon: "MemoryTips/Calendar", text: "Berichten op social media"),
                             createTipItem(icon: "MemoryTips/SocialMedia", text: "Je agenda"),
                             createTipItem(icon: "MemoryTips/Transactions", text: "Pintransacties")),
                      Label(bodyBold: "Deze activiteiten worden vaak vergeten:").multiline(),
                      VStack(spacing: 12,
                             createTipItem(icon: "MemoryTips/Car", text: "Samen in de auto zitten"),
                             createTipItem(icon: "MemoryTips/Meetings", text: "Ontmoetingen buiten of bij jou thuis"),
                             createTipItem(icon: "MemoryTips/Conversations", text: "Een onverwacht gesprek op werk"))),
               VStack(spacing: 16,
                      createSectionHeader(icon: "EditContact/Section2", title: "Zet de contacten in de app"),
                      VStack(spacing: 12,
                             Label(body: "Niet iedereen die je hebt ontmoet heeft risico op besmetting gelopen. We zijn op zoek naar mensen met wie je:", textColor: Theme.colors.tipItemColor).multiline(),
                             VStack(spacing: 16,
                                    createTipItem(icon: "ListItem/Checkmark", text: "Langer dan 15 minuten in dezelfde ruimte bent geweest"),
                                    createTipItem(icon: "ListItem/Checkmark", text: "Intens contact hebt gehad door zoenen of seksueel contact"),
                                    createTipItem(icon: "ListItem/Questionmark", text: "Twijfel je? Voeg de persoon dan toch toe")))))
            .embed(in: scrollView.readableWidth, insets: .top(16) + .bottom(16))
    }
    
    @objc private func close() {
        delegate?.overviewTipsViewControllerWantsClose(self)
    }

}
