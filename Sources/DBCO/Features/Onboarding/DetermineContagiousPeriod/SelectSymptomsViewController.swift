/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

protocol SelectSymptomsViewControllerDelegate: class {
    func selectSymptomsViewController(_ controller: SelectSymptomsViewController, didSelect symptoms: [String])
}

class SelectSymptomsViewModel {
    
    // These are temporary and will be replaced by an API call
    let selectableSymptoms = [
        "Neusverkoudheid", "Schorre stem", "Keelpijn", "(Licht) hoesten", "Kortademigheid/benauwdheid", "Pijn bij de ademhaling", "Koorts (= boven 38 graden Celsius)", "Koude rillingen", "Verlies van of verminderde reuk", "Verlies van of verminderde smaak", "Algehele malaise", "Vermoeidheid", "Hoofdpijn", "Spierpijn", "Pijn achter de ogen", "Algehele pijnklachten", "Duizeligheid", "Prikkelbaarheid/verwardheid", "Verlies van eetlust", "Misselijkheid", "Overgeven", "Diarree", "Buikpijn", "Rode prikkende ogen (oogontsteking)", "Huidafwijkingen"
    ]
    
    private(set) var selectedSymptoms = [String]()
    
    let continueWithSymptomsButtonTitle: String
    let continueWithoutSymptomsButtonTitle: String
    
    @Bindable private(set) var continueWithSymptomsButtonHidden: Bool
    @Bindable private(set) var continueWithoutSymptomsButtonHidden: Bool
    
    init(continueWithSymptomsButtonTitle: String, continueWithoutSymptomsButtonTitle: String) {
        self.continueWithSymptomsButtonTitle = continueWithSymptomsButtonTitle
        self.continueWithoutSymptomsButtonTitle = continueWithoutSymptomsButtonTitle
        
        if case .finishedWithSymptoms(let symptoms, _) = Services.onboardingManager.contagiousPeriod {
            selectedSymptoms = symptoms
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

class SelectSymptomsViewController: ViewController {
    private let viewModel: SelectSymptomsViewModel
    private let navigationBackgroundView = UIView()
    private let separatorView = SeparatorView()
    
    private let scrollView = UIScrollView(frame: .zero)
    
    weak var delegate: SelectSymptomsViewControllerDelegate?
    
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
        
        navigationBackgroundView.backgroundColor = .white
        navigationBackgroundView.snap(to: .top, of: view)
        
        navigationBackgroundView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        
        separatorView.snap(to: .top, of: view.safeAreaLayoutGuide)
        
        let margin: UIEdgeInsets = .top(32) + .bottom(16)
        
        func button(for index: Int, symptom: String) -> UIView {
            let button = SymptomToggleButton(title: symptom, selected: viewModel.selectedSymptoms.contains(symptom))
            button.tag = index
            button.addTarget(self, action: #selector(toggleSymptom), for: .valueChanged)
            return button
        }
        
        let buttonContainerView = UIView()
        buttonContainerView.layer.cornerRadius = 8
        buttonContainerView.clipsToBounds = true
        
        VStack(spacing: 0.5,
               viewModel.selectableSymptoms.enumerated().map(button))
            .embed(in: buttonContainerView)
        
        let continueWithSymptomsButton = Button(title: viewModel.continueWithSymptomsButtonTitle, style: .primary)
            .touchUpInside(self, action: #selector(finish))
        let continueWithoutSymptomsButton = Button(title: viewModel.continueWithoutSymptomsButtonTitle, style: .secondary)
            .touchUpInside(self, action: #selector(finish))
        
        viewModel.$continueWithSymptomsButtonHidden.binding = { continueWithSymptomsButton.isHidden = $0 }
        viewModel.$continueWithoutSymptomsButtonHidden.binding = { continueWithoutSymptomsButton.isHidden = $0 }
        
        VStack(spacing: 24,
               VStack(spacing: 16,
                      Label(title2: .contagiousPeriodSelectSymptomsTitle).multiline(),
                      Label(body: .contagiousPeriodSelectSymptomsMessage, textColor: Theme.colors.captionGray).multiline()),
               buttonContainerView,
               continueWithSymptomsButton,
               continueWithoutSymptomsButton)
            .distribution(.equalSpacing)
            .embed(in: scrollView.readableWidth, insets: margin)
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
        // TODO: This pattern is used multiple times
        let shouldShow = scrollView.contentOffset.y + scrollView.safeAreaInsets.top > 0
        let isShown = navigationBackgroundView.isHidden == false
        
        if shouldShow != isShown {
            UIView.animate(withDuration: 0.2) {
                if shouldShow {
                    self.separatorView.alpha = 1
                    self.navigationBackgroundView.isHidden = false
                    self.navigationItem.title = .contagiousPeriodSelectSymptomsShortTitle
                } else {
                    self.separatorView.alpha = 0
                    self.navigationBackgroundView.isHidden = true
                    self.navigationItem.title = nil
                }
            }
        }
    }
    
}