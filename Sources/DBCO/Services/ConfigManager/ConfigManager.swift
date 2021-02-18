/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

class ConfigManager: ConfigManaging, Logging {
    
    let loggingCategory = "ConfigManager"
    
    required init() {}
    
    // swiftlint:disable:next force_cast
    let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    
    var featureFlags: FeatureFlags = AppConfiguration.Flags(enableContactCalling: false,
                                                            enablePerspectiveSharing: false,
                                                            enablePerspectiveCopy: false)
    var symptoms: [Symptom] = fallbackSymptoms
    
    func update(completion: @escaping (UpdateState, FeatureFlags) -> Void) {
        func fullVersionString(_ version: String) -> String {
            var components = version.split(separator: ".")
            let missingComponents = max(0, 3 - components.count)
            components.append(contentsOf: Array(repeating: "0", count: missingComponents))
            
            return components.joined(separator: ".")
        }
        
        Services.networkManager.getAppConfiguration { result in
            switch result {
            case .success(let configuration):
                let requiredVersion = fullVersionString(configuration.minimumVersion)
                let currentVersion = fullVersionString(self.appVersion)
                
                self.logDebug("Updated feature flags: \(configuration.featureFlags)")
                self.featureFlags = configuration.featureFlags
                self.symptoms = configuration.symptoms
                
                if requiredVersion.compare(currentVersion, options: .numeric) == .orderedDescending {
                    completion(.updateRequired(configuration), self.featureFlags)
                } else {
                    completion(.noActionNeeded, self.featureFlags)
                }
            case .failure:
                completion(.noActionNeeded, self.featureFlags)
            }
        }
    }
}

extension ConfigManager {
    static var fallbackSymptoms: [Symptom] = [
        Symptom(label: "Neusverkoudheid", value: "nasal-cold"),
        Symptom(label: "Schorre stem", value: "hoarse-voice"),
        Symptom(label: "Keelpijn", value: "sore-throat"),
        Symptom(label: "(licht) hoesten", value: "cough"),
        Symptom(label: "Kortademigheid/benauwdheid", value: "shortness-of-breath"),
        Symptom(label: "Pijn bij de ademhaling", value: "painful-breathing"),
        Symptom(label: "Koorts (= boven 38 graden Celsius)", value: "fever"),
        Symptom(label: "Koude rillingen", value: "cold-shivers"),
        Symptom(label: "Verlies van of verminderde reuk", value: "loss-of-smell"),
        Symptom(label: "Verlies van of verminderde smaak", value: "loss-of-taste"),
        Symptom(label: "Algehele malaise", value: "malaise"),
        Symptom(label: "Vermoeidheid", value: "fatigue"),
        Symptom(label: "Hoofdpijn", value: "headache"),
        Symptom(label: "Spierpijn", value: "muscle-strain"),
        Symptom(label: "Pijn achter de ogen", value: "pain-behind-the-eyes"),
        Symptom(label: "Algehele pijnklachten", value: "pain"),
        Symptom(label: "Duizeligheid", value: "dizziness "),
        Symptom(label: "Prikkelbaar/verwardheid", value: "irritable-confused"),
        Symptom(label: "Verlies van eetlust", value: "loss-of-appetite"),
        Symptom(label: "Misselijkheid", value: "nausea"),
        Symptom(label: "Overgeven", value: "vomiting"),
        Symptom(label: "Diarree", value: "diarrhea"),
        Symptom(label: "Buikpijn", value: "stomach-ache"),
        Symptom(label: "Rode prikkende ogen (oogontsteking)", value: "pink-eye"),
        Symptom(label: "Huidafwijkingen", value: "skin-condition")
    ]
}
