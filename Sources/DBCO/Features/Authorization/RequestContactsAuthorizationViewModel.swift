/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import Contacts

extension CNAuthorizationStatus: AuthorizationStatusConvertible {
    var status: AuthorizationStatus {
        switch self {
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        @unknown default:
            return .restricted
        }
    }
}

class RequestContactsAuthorizationViewModel: RequestAuthorizationViewModel {
    
    let authorizeButtonTitle = String.requestPermissionContactsAllowButtonTitle
    let continueButtonTitle = String.requestPermissionContactsContinueButtonTitle
    let settingsButtonTitle = String.requestPermissionContactsSettingsButtonTitle
    
    init(currentStatus: AuthorizationStatusConvertible) {
        
    }
    
    func configure(for status: AuthorizationStatusConvertible) -> RequestAuthorizationViewConfiguration {
        
        switch status.status {
        case .authorized, .notDetermined:
            return .init(
                title: .requestPermissionContactsTitle,
                body: .requestPermissionContactsBody,
                hideAuthorizeButton: false,
                hideSettingsButton: true)
        case .denied, .restricted:
            return .init(
                title: .requestPermissionContactsTitle,
                body: .requestPermissionContactsBodyDenied,
                hideAuthorizeButton: true,
                hideSettingsButton: false)
        }
    }
    
}
