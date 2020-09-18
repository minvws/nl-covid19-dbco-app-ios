/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import Combine
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
    private(set) lazy var title: AnyPublisher<String?, Never> = $status
        .map { _ in return "Contacten delen gaat sneller als we toestemming hebben" }
        .eraseToAnyPublisher()
    
    private(set) lazy var body: AnyPublisher<String?, Never> = $status
        .map {
            switch $0 {
            case .authorized, .notDetermined:
                return "Je beslist zelf welke contactgegevens je deelt met de GGD."
            case .denied, .restricted:
                return "Ga naar instellingen om toestemming te geven."
            }
        }
        .eraseToAnyPublisher()
    
    private(set) lazy var hideAuthorizeButton: AnyPublisher<Bool, Never> = hideSettingsButton.map(!).eraseToAnyPublisher()
    
    private(set) lazy var hideSettingsButton: AnyPublisher<Bool, Never> = $status
        .map {
            switch $0 {
            case .authorized, .notDetermined:
                return true
            case .denied, .restricted:
                return false
            }
        }
        .eraseToAnyPublisher()
    
    @Published private var status: AuthorizationStatus
    
    init(currentStatus: AuthorizationStatusConvertible) {
        self.status = currentStatus.status
    }
    
    func configure(for status: AuthorizationStatusConvertible) {
        self.status = status.status
    }
    
}
