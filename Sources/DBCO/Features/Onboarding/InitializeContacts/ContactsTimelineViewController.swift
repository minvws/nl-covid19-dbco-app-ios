/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

protocol ContactsTimelineViewControllerDelegate: class {
    func contactsTimelineViewController(_ controller: ContactsTimelineViewController, didFinishWith contacts: [String], dateOfSymptomOnset: Date)
    func contactsTimelineViewController(_ controller: ContactsTimelineViewController, didFinishWith contacts: [String], testDate: Date)
}

extension Date {
    var normalized: Date {
        Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: self)!
    }
}

extension String {
    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }

    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
}

class ContactsTimelineViewModel {
    
    struct Section {
        let tag: Int
        let title: String
        var subtitle: String?
    }
    
    enum Configuration {
        case dateOfSymptomOnset(Date)
        case testDate(Date)
        
        var date: Date {
            switch self {
            case .dateOfSymptomOnset(let date):
                return date
            case .testDate(let date):
                return date
            }
        }
    }
    
    private var configuration: Configuration
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = .current
        formatter.timeZone = .current
        formatter.dateFormat = "EEEE d MMMM"
        
        return formatter
    }()
    
    private let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = .current
        formatter.timeZone = .current
        formatter.dateFormat = "d MMMM"
        
        return formatter
    }()
    
    private var remainingExtraDays = 2
    
    init(dateOfSymptomOnset: Date) {
        configuration = .dateOfSymptomOnset(dateOfSymptomOnset.normalized)
    }
    
    init(testDate: Date) {
        configuration = .testDate(testDate.normalized)
    }
    
    var title: String {
        let endDate = Calendar.current.date(byAdding: .day, value: -2, to: configuration.date)!
        
        return "Wie heb je ontmoet tussen \(dateFormatter.string(from: endDate)) en vandaag?"
    }
    
    var sections: [Section] {
        let today = Date().normalized
        
        let endDate = Calendar.current.date(byAdding: .day, value: -2, to: configuration.date)!
        let numberOfDays = Calendar.current.dateComponents([.day], from: endDate, to: today).day! + 1
        
        func title(for index: Int, date: Date) -> String {
            let titleFormats = [
                "Vandaag (%@)",
                "Gisteren (%@)",
                "Eergisteren (%@)"
            ]
            
            if titleFormats.indices.contains(index) {
                return String(format: titleFormats[index], dateFormatter.string(from: date))
            } else {
                return dateFormatter.string(from: date).capitalizingFirstLetter()
            }
        }
        
        func subtitle(for index: Int) -> String? {
            let reversedSubtitles: [String?]
            
            switch configuration {
            case .dateOfSymptomOnset:
                reversedSubtitles = [
                    "Deze dag was je ook al besmettelijk",
                    "Deze dag was je ook al besmettelijk",
                    "De eerste dag dat je klachten had"
                ]
            case .testDate:
                reversedSubtitles = [
                    nil,
                    nil,
                    "Op deze dag liet je jezelf testen"
                ]
            }
            
            let reversedIndex = (numberOfDays - 1) - index
            
            if reversedSubtitles.indices.contains(reversedIndex) {
                return reversedSubtitles[reversedIndex]
            } else {
                return nil
            }
        }
        
        return (0 ..< numberOfDays).map { index in
            let date = Calendar.current.date(byAdding: .day, value: -index, to: today)!
            let section = Section(tag: Int(date.timeIntervalSinceReferenceDate),
                                  title: title(for: index, date: date),
                                  subtitle: subtitle(for: index))
            
            return section
        }
    }
    
    var hideExtraDaySection: Bool {
        switch configuration {
        case .dateOfSymptomOnset:
            return remainingExtraDays == 0
        case .testDate:
            return true
        }
    }
    
    var addExtraDayTitle: String? {
        guard case .dateOfSymptomOnset(let date) = configuration else { return nil }
        
        return "Weet je zeker dat je voor \(shortDateFormatter.string(from: date)) nog geen klachten had?"
    }
    
    func addExtraDay() {
        guard case .dateOfSymptomOnset(let date) = configuration else { return }
        guard remainingExtraDays > 0 else { return }
        
        let adjustedDate = Calendar.current.date(byAdding: .day, value: -1, to: date)!
        
        configuration = .dateOfSymptomOnset(adjustedDate)
        
        remainingExtraDays -= 1
    }
}

class ContactsTimelineViewController: ViewController {
    private let viewModel: ContactsTimelineViewModel
    private let navigationBackgroundView = UIView()
    private let separatorView = SeparatorView()
    private let titleLabel = Label(title2: nil)
    private var addExtraDaySectionView: UIStackView!
    private let addExtraDayTitleLabel = Label(bodyBold: nil)
    
    private let scrollView = UIScrollView(frame: .zero)
    private var sectionStackView: UIStackView!
    
    weak var delegate: ContactsTimelineViewControllerDelegate?
    
    init(viewModel: ContactsTimelineViewModel) {
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
        
        view.backgroundColor = .white
        
        scrollView.embed(in: view)
        scrollView.keyboardDismissMode = .onDrag
        scrollView.delegate = self
        
        navigationBackgroundView.backgroundColor = .white
        navigationBackgroundView.snap(to: .top, of: view)
        
        navigationBackgroundView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        
        separatorView.snap(to: .top, of: view.safeAreaLayoutGuide)
        
        let margin: UIEdgeInsets = .top(32) + .bottom(16)
        
        sectionStackView = VStack(spacing: 40)
        
        let addExtraDayButton = Button(title: "Extra dag toevoegen", style: .secondary)
            .touchUpInside(self, action: #selector(addExtraDay))
        
        addExtraDayButton.setImage(UIImage(named: "Plus"), for: .normal)
        addExtraDayButton.titleEdgeInsets = .left(5)
        addExtraDayButton.imageEdgeInsets = .right(5)
        
        addExtraDaySectionView = VStack(spacing: 24,
                                        addExtraDayTitleLabel.multiline(),
                                        addExtraDayButton)

        let stack =
            VStack(spacing: 40,
                   VStack(spacing: 16,
                          titleLabel.multiline(),
                          Label(body: "Weet je niet hoe iemand heet? Zet het contact er dan toch in. Bijvoorbeeld als trainer, kapper of buurvrouw. Je hoeft hier geen huisgenoten toe te voegen.", textColor: Theme.colors.captionGray).multiline()),
                   sectionStackView,
                   VStack(spacing: 16,
                          addExtraDaySectionView,
                          Button(title: .next, style: .primary).touchUpInside(self, action: #selector(handleContinue))))
                .distribution(.fill)
                .embed(in: scrollView.readableWidth, insets: margin)
        
        stack.heightAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.heightAnchor,
                                          multiplier: 1,
                                          constant: -(margin.top + margin.bottom)).isActive = true
        
        configureSections()
        
        registerForKeyboardNotifications()
    }
    
    private func configureSections() {
        titleLabel.text = viewModel.title
        
        viewModel.sections.forEach { section in
            let existingSectionViews = self.sectionStackView.arrangedSubviews.compactMap { $0 as? DaySectionView }
            
            if let sectionView = existingSectionViews.first(where: { $0.isConfigured(for: section) }) {
                sectionView.section = section
            } else {
                let sectionView = DaySectionView()
                sectionView.section = section
                self.sectionStackView.addArrangedSubview(sectionView)
            }
        }
        
        addExtraDaySectionView.isHidden = viewModel.hideExtraDaySection
        addExtraDayTitleLabel.text = viewModel.addExtraDayTitle
    }
    
    @objc private func handleContinue() {
        delegate?.contactsTimelineViewController(self, didFinishWith: [], testDate: Date())
    }
    
    @objc private func addExtraDay() {
        viewModel.addExtraDay()
        
        configureSections()
    }
    
    // MARK: - Keyboard handling
    
    private func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIWindow.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIWindow.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }
        let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? .zero
        
        let convertedFrame = view.window?.convert(endFrame, to: view)
        
        let inset = view.frame.maxY - (convertedFrame?.minY ?? 0)
        
        scrollView.contentInset.bottom = inset
        scrollView.verticalScrollIndicatorInsets.bottom = inset
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset = .zero
        scrollView.verticalScrollIndicatorInsets.bottom = .zero
    }

}

private class DaySectionView: UIView {
    
    private let titleLabel = Label(bodyBold: nil)
    private let subtitleLabel = Label(body: nil, textColor: Theme.colors.captionGray)
    
    var section: ContactsTimelineViewModel.Section? {
        didSet { configureForSection() }
    }
    
    init() {
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        VStack(spacing: 8,
               VStack(spacing: 4,
                      titleLabel.multiline(),
                      subtitleLabel.multiline().hideIfEmpty()),
               ContactListInputView(placeholder: "Contact toevoegen"))
            .embed(in: self)
    }
        
    private func configureForSection() {
        titleLabel.text = section?.title
        subtitleLabel.text = section?.subtitle
        tag = section?.tag ?? 0
    }
    
    func isConfigured(for section: ContactsTimelineViewModel.Section) -> Bool {
        return tag == section.tag
    }
    
}

extension ContactsTimelineViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        UIView.animate(withDuration: 0.2) {
            if scrollView.contentOffset.y + scrollView.safeAreaInsets.top > 0 {
                self.separatorView.alpha = 1
                self.navigationBackgroundView.isHidden = false
                self.navigationItem.title = "Contacten"
            } else {
                self.separatorView.alpha = 0
                self.navigationBackgroundView.isHidden = true
                self.navigationItem.title = nil
            }
        }
    }
    
}
