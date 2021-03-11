/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

protocol DatePicking: UIView {
    var maximumDate: Date? { get set }
    var minimumDate: Date? { get set }
    
    var date: Date { get set }
    
    func setDate(_ date: Date, animated: Bool)
}

extension UIDatePicker: DatePicking {}

class OnboardingDateViewModel {
    let title: String
    let subtitle: String
    let primaryButtonTitle: String
    let secondaryButtonTitle: String?
    let date: Date?
    
    init(title: String, subtitle: String, primaryButtonTitle: String, secondaryButtonTitle: String?, date: Date?) {
        self.title = title
        self.subtitle = subtitle
        self.primaryButtonTitle = primaryButtonTitle
        self.secondaryButtonTitle = secondaryButtonTitle
        self.date = date
    }
}

class OnboardingDateViewController: ViewController {
    private let viewModel: OnboardingDateViewModel
    fileprivate let datePicker: DatePicking = {
        if #available(iOS 14, *) {
            let datePicker = UIDatePicker(frame: CGRect(x: 0, y: 0, width: 280, height: 100))
            datePicker.preferredDatePickerStyle = .inline
            datePicker.datePickerMode = .date

            return datePicker
        } else {
            return OnsetDatePicker()
        }
    }()
    
    init(viewModel: OnboardingDateViewModel) {
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
        
        let primaryButton = Button(title: viewModel.primaryButtonTitle, style: .primary)
            .touchUpInside(self, action: #selector(handlePrimaryButton))
        let secondaryButton = Button(title: viewModel.secondaryButtonTitle ?? "", style: .secondary)
            .touchUpInside(self, action: #selector(handleSecondaryButton))
        
        secondaryButton.isHidden = viewModel.secondaryButtonTitle == nil
        
        datePicker.maximumDate = Date()
        datePicker.minimumDate = Calendar.current.date(byAdding: .month, value: -3, to: Date())
        datePicker.setDate(viewModel.date ?? Date(), animated: false)
        
        VStack(VStack(spacing: 16,
                      Label(title2: viewModel.title).multiline(),
                      Label(body: viewModel.subtitle, textColor: Theme.colors.captionGray).multiline()),
               datePicker,
               VStack(spacing: 16,
                      secondaryButton,
                      primaryButton))
            .distribution(.equalSpacing)
            .wrappedInReadableWidth()
            .embed(in: view.safeAreaLayoutGuide, insets: .top(32) + .bottom(16))
    }
    
    @objc fileprivate func handlePrimaryButton() {}
    
    @objc fileprivate func handleSecondaryButton() {}
    
}

protocol SelectTestDateViewControllerDelegate: class {
    func selectTestDateViewController(_ controller: SelectTestDateViewController, didSelect date: Date)
}

class SelectTestDateViewController: OnboardingDateViewController {
    weak var delegate: SelectTestDateViewControllerDelegate?
    
    init() {
        super.init(viewModel: OnboardingDateViewModel(title: .contagiousPeriodSelectTestDateTitle,
                                                      subtitle: .contagiousPeriodSelectTestDateMessage,
                                                      primaryButtonTitle: .next,
                                                      secondaryButtonTitle: nil,
                                                      date: Services.onboardingManager.contagiousPeriod.testDate))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate override func handlePrimaryButton() {
        delegate?.selectTestDateViewController(self, didSelect: datePicker.date)
    }
}

protocol SelectSymptomOnsetDateViewControllerDelegate: class {
    func selectSymptomOnsetDateViewController(_ controller: SelectSymptomOnsetDateViewController, didSelect date: Date)
    func selectSymptomOnsetDateViewControllerWantsHelp(_ controller: SelectSymptomOnsetDateViewController)
}

class SelectSymptomOnsetDateViewController: OnboardingDateViewController {
    weak var delegate: SelectSymptomOnsetDateViewControllerDelegate?
    
    init() {
        super.init(viewModel: OnboardingDateViewModel(title: .contagiousPeriodSelectOnsetDateTitle,
                                                      subtitle: .contagiousPeriodSelectOnsetDateMessage,
                                                      primaryButtonTitle: .next,
                                                      secondaryButtonTitle: .contagiousPeriodSelectOnsetDateHelpButtonTitle,
                                                      date: Services.onboardingManager.contagiousPeriod.symptomOnsetDate))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate override func handlePrimaryButton() {
        delegate?.selectSymptomOnsetDateViewController(self, didSelect: datePicker.date)
    }
    
    fileprivate override func handleSecondaryButton() {
        delegate?.selectSymptomOnsetDateViewControllerWantsHelp(self)
    }
    
    func selectDate(_ date: Date) {
        datePicker.setDate(date, animated: true)
    }
}
