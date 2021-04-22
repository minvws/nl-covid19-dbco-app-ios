/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

class AppUpdateViewModel {
    let image: UIImage
    let message: String?
    let updateURL: URL?
    
    init(versionInformation: AppVersionInformation) {
        image = UIImage(named: "Onboarding2")!
        message = versionInformation.minimumVersionMessage ?? .updateAppContent
        updateURL = versionInformation.appStoreURL
    }
}

protocol AppUpdateViewControllerDelegate: class {
    func appUpdateViewController(_ controller: AppUpdateViewController, wantsToOpen url: URL)
}

/// Fullscreen alert forcing the user to update the app to the latest version
///
/// # See also:
/// [AppCoordinator.showRequiredUpdate](x-source-tag://AppCoordinator.showRequiredUpdate)
///
/// - Tag: AppUpdateViewController
class AppUpdateViewController: ViewController {
    private let viewModel: AppUpdateViewModel
    
    weak var delegate: AppUpdateViewControllerDelegate?
    
    init(viewModel: AppUpdateViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        
        modalPresentationStyle = .overFullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.backgroundColor = .white
        
        let textContainerView =
            VStack(spacing: 32,
                   VStack(spacing: 16,
                          UILabel(title2: .updateAppTitle).multiline(),
                          UILabel(body: viewModel.message, textColor: Theme.colors.captionGray).multiline()),
                   Button(title: .updateAppButton, style: .primary)
                       .touchUpInside(self, action: #selector(update)))
        
        textContainerView.snap(to: .bottom,
                               of: view.readableContentGuide,
                               insets: .bottom(8))
        
        let imageView = UIImageView(image: viewModel.image)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.setContentHuggingPriority(.required, for: .vertical)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        
        view.addSubview(imageView)
        
        imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        let imageCenterYConstraint = imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        imageCenterYConstraint.priority = .defaultLow
        imageCenterYConstraint.isActive = true
        
        imageView.bottomAnchor.constraint(lessThanOrEqualTo: textContainerView.topAnchor, constant: -32).isActive = true
        
        let imageTextSpacingConstraint = imageView.bottomAnchor.constraint(lessThanOrEqualTo: textContainerView.topAnchor, constant: -105)
        imageTextSpacingConstraint.priority = .defaultLow
        imageTextSpacingConstraint.isActive = true
        
        imageView.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor, constant: 16).isActive = true
    }
    
    @objc private func update() {
        guard let url = viewModel.updateURL else {
            showCannotOpenAppStoreAlert()
            return
        }
        
        delegate?.appUpdateViewController(self, wantsToOpen: url)
    }
    
    private func showCannotOpenAppStoreAlert() {
        let alertController = UIAlertController(title: .errorTitle,
                                                message: .updateAppErrorMessage,
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: .ok, style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }

}
