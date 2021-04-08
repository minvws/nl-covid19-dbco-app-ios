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
    let date: Date?
    let actions: [OnboardingDateViewController.Action]
    
    init(title: String, subtitle: String, date: Date?, actions: [OnboardingDateViewController.Action]) {
        self.title = title
        self.subtitle = subtitle
        self.date = date
        self.actions = actions
    }
}

class OnboardingDateViewController: ViewController, ScrollViewNavivationbarAdjusting {
    
    let shortTitle: String = ""
    
    struct Action {
        let type: Button.ButtonType
        let title: String
        let action: (Date) -> Void
    }
    
    private let viewModel: OnboardingDateViewModel
    private let scrollView = UIScrollView()
    
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
        
        // ScrollView
        scrollView.embed(in: view)
        scrollView.delegate = self
        
        let widthProviderView = UIView()
        widthProviderView.snap(to: .top, of: scrollView, height: 0)
        widthProviderView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        
        datePicker.maximumDate = Date()
        datePicker.minimumDate = Calendar.current.date(byAdding: .month, value: -3, to: Date())
        datePicker.setDate(viewModel.date ?? Date(), animated: false)
        
        setupStackView()
    }
    
    private func createButtons() -> UIView {
        func createButton(for action: Action) -> Button {
            return Button(title: action.title, style: action.type)
                .touchUpInside(self, action: #selector(handleButton))
        }
        
        return VStack(spacing: 16, viewModel.actions.map(createButton))
    }
    
    private func setupStackView() {
        let topMargin: CGFloat = UIScreen.main.bounds.height < 600 ? 0 : 32
        let margin: UIEdgeInsets = .top(topMargin) + .bottom(16)
        
        let stack =
            VStack(VStack(spacing: 16,
                          UILabel(title2: viewModel.title).multiline(),
                          TextView(htmlText: viewModel.subtitle)),
                   datePicker,
                   createButtons())
            .distribution(.equalSpacing)
            .embed(in: scrollView.readableWidth, insets: margin)
        stack.heightAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.heightAnchor,
                                      multiplier: 1,
                                      constant: -(margin.top + margin.bottom)).isActive = true
        
        let preferredHeightConstraint = stack.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor,
                                                                      multiplier: 1,
                                                                      constant: -(margin.top + margin.bottom))
        preferredHeightConstraint.priority = UILayoutPriority(250)
        preferredHeightConstraint.isActive = true
    }
    
    func selectDate(_ date: Date) {
        datePicker.setDate(date, animated: true)
    }
    
    @objc private func handleButton(_ sender: Button) {
        let action = viewModel.actions.first { $0.title == sender.title }
        action?.action(datePicker.date)
    }
    
}

extension OnboardingDateViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        adjustNavigationBar(for: scrollView)
    }
    
}
