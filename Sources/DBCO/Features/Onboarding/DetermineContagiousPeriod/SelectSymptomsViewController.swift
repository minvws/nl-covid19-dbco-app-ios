/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

protocol SelectSymptomsViewControllerDelegate: class {
    func selectSymptomsViewController(_ controller: SelectSymptomsViewController, didSelect symptoms: [Symptom])
}

class SelectSymptomsViewModel {
    
    let selectableSymptoms = Services.configManager.symptoms
    
    private(set) var selectedSymptoms = [Symptom]()
    
    let continueWithSymptomsButtonTitle: String
    let continueWithoutSymptomsButtonTitle: String
    
    @Bindable private(set) var continueWithSymptomsButtonHidden: Bool
    @Bindable private(set) var continueWithoutSymptomsButtonHidden: Bool
    
    let initiallyVisibleSymptomsCount: Int
    
    init(continueWithSymptomsButtonTitle: String, continueWithoutSymptomsButtonTitle: String) {
        self.continueWithSymptomsButtonTitle = continueWithSymptomsButtonTitle
        self.continueWithoutSymptomsButtonTitle = continueWithoutSymptomsButtonTitle
        
        let minVisibleSymptoms = 14
        if case .finishedWithSymptoms(let symptoms, _) = Services.onboardingManager.contagiousPeriod {
            selectedSymptoms = symptoms
            let lastSelectedIndex = selectableSymptoms.lastIndex { symptoms.contains($0) }
            initiallyVisibleSymptomsCount = max((lastSelectedIndex ?? 0) + 1, minVisibleSymptoms)
        } else {
            initiallyVisibleSymptomsCount = minVisibleSymptoms
        }
        
        continueWithSymptomsButtonHidden = selectedSymptoms.isEmpty
        continueWithoutSymptomsButtonHidden = !selectedSymptoms.isEmpty
    }
    
    func toggleSymptom(at index: Int) {
        guard selectableSymptoms.indices.contains(index) else { return }
        
        let symptom = selectableSymptoms[index]
        
        if let index = selectedSymptoms.firstIndex(of: symptom) {
            selectedSymptoms.remove(at: index)
        } else {
            selectedSymptoms.append(symptom)
        }
        
        continueWithSymptomsButtonHidden = selectedSymptoms.isEmpty
        continueWithoutSymptomsButtonHidden = !selectedSymptoms.isEmpty
    }
}

/// Shows a list of selectable [Symptom](x-source-tag://Symptom)s. The symptoms are fetched by the [ConfigManager](x-source-tag://ConfigManaging)
/// - Tag: SelectSymptomsViewController
class SelectSymptomsViewController: ViewController, ScrollViewNavivationbarAdjusting {
    private let viewModel: SelectSymptomsViewModel
    private var symptomButtonStackView: UIStackView!
    
    private let scrollView = UIScrollView(frame: .zero)
    
    weak var delegate: SelectSymptomsViewControllerDelegate?
    
    let shortTitle: String = .contagiousPeriodSelectSymptomsShortTitle
    
    init(viewModel: SelectSymptomsViewModel) {
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
        scrollView.delegate = self
        
        let margin: UIEdgeInsets = .top(32) + .bottom(16)
        
        func button(for index: Int, symptom: Symptom) -> UIView {
            let button = SymptomToggleButton(title: symptom.label, selected: viewModel.selectedSymptoms.contains(symptom))
            button.tag = index
            button.addTarget(self, action: #selector(toggleSymptom), for: .valueChanged)
            button.isHidden = index >= viewModel.initiallyVisibleSymptomsCount
            return button
        }
        
        let buttonContainerView = UIView()
        buttonContainerView.layer.cornerRadius = 8
        buttonContainerView.clipsToBounds = true
        
        symptomButtonStackView =
            VStack(spacing: 0.5,
                   viewModel.selectableSymptoms.enumerated().map(button))
            .embed(in: buttonContainerView)
        
        let continueWithSymptomsButton = Button(title: viewModel.continueWithSymptomsButtonTitle, style: .primary)
            .touchUpInside(self, action: #selector(finish))
        let continueWithoutSymptomsButton = Button(title: viewModel.continueWithoutSymptomsButtonTitle, style: .secondary)
            .touchUpInside(self, action: #selector(finish))
        
        viewModel.$continueWithSymptomsButtonHidden.binding = { continueWithSymptomsButton.isHidden = $0 }
        viewModel.$continueWithoutSymptomsButtonHidden.binding = { continueWithoutSymptomsButton.isHidden = $0 }
        
        let showAllSymptomsButton = Button(title: .contagiousPeriodAllSymptomsButton, style: .info)
            .touchUpInside(self, action: #selector(showAllSymptoms))
        
        showAllSymptomsButton.isHidden = symptomButtonStackView.arrangedSubviews.allSatisfy { $0.isHidden == false }
        
        VStack(spacing: 24,
               VStack(spacing: 16,
                      UILabel(title2: .contagiousPeriodSelectSymptomsTitle).multiline(),
                      UILabel(body: .contagiousPeriodSelectSymptomsMessage, textColor: Theme.colors.captionGray).multiline()),
               buttonContainerView,
               showAllSymptomsButton,
               continueWithSymptomsButton,
               continueWithoutSymptomsButton)
            .distribution(.equalSpacing)
            .embed(in: scrollView.readableWidth, insets: margin)
    }
    
    @objc private func showAllSymptoms(_ sender: UIButton) {
        symptomButtonStackView.arrangedSubviews.forEach { $0.isHidden = false }
        
        sender.isHidden = true
    }
    
    @objc private func toggleSymptom(_ sender: SymptomToggleButton) {
        viewModel.toggleSymptom(at: sender.tag)
    }
    
    @objc private func finish() {
        delegate?.selectSymptomsViewController(self, didSelect: viewModel.selectedSymptoms)
    }

}

extension SelectSymptomsViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        adjustNavigationBar(for: scrollView)
    }
    
}
