/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

/// - Tag: ConfigManager
class ConfigManager: ConfigManaging, Logging {
    
    let loggingCategory = "ConfigManager"
    
    required init() {}
    
    // swiftlint:disable:next force_cast
    let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    
    var featureFlags: FeatureFlags = .empty
    var symptoms: [Symptom] = fallbackSymptoms
    var supportedZipCodeRanges: [ZipRange] = fallbackZipRanges
    
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
                
                self.supportedZipCodeRanges = configuration.supportedZipCodeRanges ?? Self.fallbackZipRanges
                
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

private extension ConfigManager {
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
        Symptom(label: "Duizeligheid", value: "dizziness"),
        Symptom(label: "Prikkelbaar/verwardheid", value: "irritable-confused"),
        Symptom(label: "Verlies van eetlust", value: "loss-of-appetite"),
        Symptom(label: "Misselijkheid", value: "nausea"),
        Symptom(label: "Overgeven", value: "vomiting"),
        Symptom(label: "Diarree", value: "diarrhea"),
        Symptom(label: "Buikpijn", value: "stomach-ache"),
        Symptom(label: "Rode prikkende ogen (oogontsteking)", value: "pink-eye"),
        Symptom(label: "Huidafwijkingen", value: "skin-condition")
    ]
    
    static var fallbackZipRanges: [ZipRange] = [
        ZipRange(start: 1211, end: 1218), ZipRange(start: 1221, end: 1223), ZipRange(start: 1231, end: 1231), ZipRange(start: 1241, end: 1241),
        ZipRange(start: 1243, end: 1244), ZipRange(start: 1251, end: 1252), ZipRange(start: 1261, end: 1262), ZipRange(start: 1271, end: 1277),
        ZipRange(start: 1381, end: 1384), ZipRange(start: 1398, end: 1399), ZipRange(start: 1401, end: 1406), ZipRange(start: 1411, end: 1412),
        ZipRange(start: 2651, end: 2652), ZipRange(start: 2661, end: 2662), ZipRange(start: 2665, end: 2665), ZipRange(start: 2901, end: 2909),
        ZipRange(start: 2921, end: 2926), ZipRange(start: 2981, end: 2989), ZipRange(start: 2991, end: 2994), ZipRange(start: 3011, end: 3016),
        ZipRange(start: 3021, end: 3029), ZipRange(start: 3031, end: 3039), ZipRange(start: 3041, end: 3047), ZipRange(start: 3051, end: 3056),
        ZipRange(start: 3059, end: 3059), ZipRange(start: 3061, end: 3069), ZipRange(start: 3071, end: 3079), ZipRange(start: 3081, end: 3089),
        ZipRange(start: 3111, end: 3119), ZipRange(start: 3121, end: 3125), ZipRange(start: 3131, end: 3138), ZipRange(start: 3141, end: 3147),
        ZipRange(start: 3161, end: 3162), ZipRange(start: 3165, end: 3165), ZipRange(start: 3171, end: 3172), ZipRange(start: 3176, end: 3176),
        ZipRange(start: 3201, end: 3209), ZipRange(start: 3211, end: 3212), ZipRange(start: 3214, end: 3214), ZipRange(start: 3216, end: 3216),
        ZipRange(start: 3218, end: 3218), ZipRange(start: 3221, end: 3225), ZipRange(start: 3227, end: 3227), ZipRange(start: 3231, end: 3235),
        ZipRange(start: 3241, end: 3241), ZipRange(start: 3243, end: 3245), ZipRange(start: 3247, end: 3249), ZipRange(start: 3251, end: 3253),
        ZipRange(start: 3255, end: 3258), ZipRange(start: 4251, end: 4251), ZipRange(start: 4254, end: 4255), ZipRange(start: 4261, end: 4261),
        ZipRange(start: 4264, end: 4269), ZipRange(start: 4271, end: 4271), ZipRange(start: 4273, end: 4273), ZipRange(start: 4281, end: 4281),
        ZipRange(start: 4283, end: 4288), ZipRange(start: 4611, end: 4617), ZipRange(start: 4621, end: 4625), ZipRange(start: 4631, end: 4631),
        ZipRange(start: 4634, end: 4635), ZipRange(start: 4641, end: 4641), ZipRange(start: 4645, end: 4645), ZipRange(start: 4651, end: 4652),
        ZipRange(start: 4655, end: 4655), ZipRange(start: 4701, end: 4709), ZipRange(start: 4711, end: 4711), ZipRange(start: 4714, end: 4715),
        ZipRange(start: 4721, end: 4722), ZipRange(start: 4731, end: 4731), ZipRange(start: 4758, end: 4759), ZipRange(start: 4761, end: 4762),
        ZipRange(start: 4765, end: 4766), ZipRange(start: 4811, end: 4819), ZipRange(start: 4822, end: 4827), ZipRange(start: 4834, end: 4839),
        ZipRange(start: 4841, end: 4841), ZipRange(start: 4849, end: 4849), ZipRange(start: 4855, end: 4856), ZipRange(start: 4858, end: 4859),
        ZipRange(start: 4861, end: 4861), ZipRange(start: 4871, end: 4879), ZipRange(start: 4881, end: 4882), ZipRange(start: 4884, end: 4885),
        ZipRange(start: 4891, end: 4891), ZipRange(start: 4931, end: 4931), ZipRange(start: 4941, end: 4942), ZipRange(start: 4944, end: 4944),
        ZipRange(start: 5111, end: 5111), ZipRange(start: 5113, end: 5114), ZipRange(start: 6121, end: 6125), ZipRange(start: 6127, end: 6127),
        ZipRange(start: 6129, end: 6129), ZipRange(start: 6155, end: 6155), ZipRange(start: 6176, end: 6176), ZipRange(start: 6211, end: 6219),
        ZipRange(start: 6221, end: 6229), ZipRange(start: 6231, end: 6231), ZipRange(start: 6235, end: 6235), ZipRange(start: 6237, end: 6237),
        ZipRange(start: 6241, end: 6241), ZipRange(start: 6243, end: 6243), ZipRange(start: 6245, end: 6245), ZipRange(start: 6247, end: 6247),
        ZipRange(start: 6251, end: 6252), ZipRange(start: 6255, end: 6255), ZipRange(start: 6261, end: 6262), ZipRange(start: 6265, end: 6265),
        ZipRange(start: 6267, end: 6269), ZipRange(start: 6271, end: 6271), ZipRange(start: 6273, end: 6274), ZipRange(start: 6276, end: 6278),
        ZipRange(start: 6281, end: 6281), ZipRange(start: 6285, end: 6287), ZipRange(start: 6289, end: 6289), ZipRange(start: 6291, end: 6291),
        ZipRange(start: 6294, end: 6295), ZipRange(start: 6301, end: 6301), ZipRange(start: 6305, end: 6305), ZipRange(start: 6311, end: 6312),
        ZipRange(start: 6351, end: 6351), ZipRange(start: 6353, end: 6353), ZipRange(start: 6371, end: 6374), ZipRange(start: 6411, end: 6419),
        ZipRange(start: 6421, end: 6422), ZipRange(start: 6431, end: 6433), ZipRange(start: 6441, end: 6446), ZipRange(start: 6461, end: 6469),
        ZipRange(start: 6471, end: 6471), ZipRange(start: 7441, end: 7443), ZipRange(start: 7447, end: 7448), ZipRange(start: 7451, end: 7451),
        ZipRange(start: 7461, end: 7463), ZipRange(start: 7466, end: 7468), ZipRange(start: 7471, end: 7472), ZipRange(start: 7475, end: 7475),
        ZipRange(start: 7478, end: 7478), ZipRange(start: 7481, end: 7483), ZipRange(start: 7511, end: 7514), ZipRange(start: 7521, end: 7525),
        ZipRange(start: 7531, end: 7536), ZipRange(start: 7541, end: 7548), ZipRange(start: 7551, end: 7559), ZipRange(start: 7561, end: 7562),
        ZipRange(start: 7571, end: 7577), ZipRange(start: 7581, end: 7582), ZipRange(start: 7585, end: 7588), ZipRange(start: 7601, end: 7611),
        ZipRange(start: 7614, end: 7615), ZipRange(start: 7621, end: 7623), ZipRange(start: 7625, end: 7626), ZipRange(start: 7671, end: 7672),
        ZipRange(start: 7675, end: 7676), ZipRange(start: 8388, end: 8389), ZipRange(start: 8391, end: 8398), ZipRange(start: 8401, end: 8401),
        ZipRange(start: 8403, end: 8409), ZipRange(start: 8411, end: 8415), ZipRange(start: 8421, end: 8428), ZipRange(start: 8431, end: 8435),
        ZipRange(start: 8461, end: 8467), ZipRange(start: 8497, end: 8497), ZipRange(start: 8529, end: 8529), ZipRange(start: 8801, end: 8802),
        ZipRange(start: 8804, end: 8809), ZipRange(start: 8811, end: 8814), ZipRange(start: 8816, end: 8816), ZipRange(start: 8832, end: 8835),
        ZipRange(start: 8857, end: 8857), ZipRange(start: 8861, end: 8862), ZipRange(start: 8871, end: 8872), ZipRange(start: 8881, end: 8885),
        ZipRange(start: 8891, end: 8897), ZipRange(start: 8899, end: 8899), ZipRange(start: 9061, end: 9064), ZipRange(start: 9067, end: 9067),
        ZipRange(start: 9073, end: 9074), ZipRange(start: 9161, end: 9164), ZipRange(start: 9166, end: 9166), ZipRange(start: 9231, end: 9231),
        ZipRange(start: 9233, end: 9233)
    ]
}
