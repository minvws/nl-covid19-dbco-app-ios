//
//  ContactQuestionnaireViewModelTests.swift
//  DBCOTests
//
//  Created by Thom Hoekstra on 11/05/2021.
//  Copyright © 2021 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport. All rights reserved.
//

import XCTest
@testable import GGD_Contact
import Contacts

class ContactQuestionnaireViewModelTests: XCTestCase {
    
    let fullQuestionnaire: Questionnaire = {
        let decoder = JSONDecoder()
        let data = questionnaireJSON.data(using: .utf8)!
        var questionnaire = try! decoder.decode(Questionnaire.self, from: data) // swiftlint:disable:this force_try
        
        return CaseManager.prepareQuestionnaire(questionnaire)
    }()
    
    let simpleQuestionnaire: Questionnaire = {
        let decoder = JSONDecoder()
        let data = simpleQuestionnaireJSON.data(using: .utf8)!
        var questionnaire = try! decoder.decode(Questionnaire.self, from: data) // swiftlint:disable:this force_try
        
        return CaseManager.prepareQuestionnaire(questionnaire)
    }()
    
    let guidelines: Guidelines = {
        let decoder = JSONDecoder()
        let data = guidelinesJSON.data(using: .utf8)!
        return try! decoder.decode(Guidelines.self, from: data) // swiftlint:disable:this force_try
    }()
    
    func testNewTaskSetup() {
        let input = ContactQuestionnaireViewModel.Input(
            caseReference: nil,
            guidelines: guidelines,
            featureFlags: FeatureFlags(enableContactCalling: true, enablePerspectiveCopy: true, enableSelfBCO: true),
            isCaseWindowExpired: false,
            task: nil,
            questionnaire: fullQuestionnaire,
            contact: nil)
        
        let viewModel = ContactQuestionnaireViewModel(input)
        
        XCTAssertTrue(viewModel.didCreateNewTask)
        XCTAssertTrue(viewModel.canSafelyCancel)
        XCTAssertTrue(viewModel.contactShouldBeDeleted)
        
        XCTAssertFalse(viewModel.isDisabled)
        XCTAssertFalse(viewModel.showDeleteButton)
        
        XCTAssertEqual(viewModel.title, .contactFallbackTitle)
    }
    
    func testClassifiedAppTaskSetup() {
        let testCategories: [Task.Contact.Category] = [.category1, .category2a, .category2b, .category3a, .category3b]
        
        for category in testCategories {
            let input = ContactQuestionnaireViewModel.Input(
                caseReference: nil,
                guidelines: guidelines,
                featureFlags: FeatureFlags(enableContactCalling: true, enablePerspectiveCopy: true, enableSelfBCO: true),
                isCaseWindowExpired: false,
                task: createContactTask(category: category, source: .app),
                questionnaire: fullQuestionnaire,
                contact: nil)
            
            let viewModel = ContactQuestionnaireViewModel(input)
            
            XCTAssertFalse(viewModel.contactShouldBeDeleted)
            XCTAssertFalse(viewModel.didCreateNewTask)
            XCTAssertFalse(viewModel.canSafelyCancel)
            XCTAssertFalse(viewModel.isDisabled)
            
            XCTAssertTrue(viewModel.showDeleteButton)
            
            XCTAssertEqual(viewModel.title, .contactFallbackTitle)
        }
    }
    
    func testClassifiedPortalTaskSetup() {
        let testCategories: [Task.Contact.Category] = [.category1, .category2a, .category2b, .category3a, .category3b]
        
        for category in testCategories {
            let input = ContactQuestionnaireViewModel.Input(
                caseReference: nil,
                guidelines: guidelines,
                featureFlags: FeatureFlags(enableContactCalling: true, enablePerspectiveCopy: true, enableSelfBCO: true),
                isCaseWindowExpired: false,
                task: createContactTask(category: category, source: .portal),
                questionnaire: fullQuestionnaire,
                contact: nil)
            
            let viewModel = ContactQuestionnaireViewModel(input)
            
            XCTAssertFalse(viewModel.contactShouldBeDeleted)
            XCTAssertFalse(viewModel.didCreateNewTask)
            XCTAssertFalse(viewModel.canSafelyCancel)
            XCTAssertFalse(viewModel.isDisabled)
            
            XCTAssertFalse(viewModel.showDeleteButton)
            
            XCTAssertEqual(viewModel.title, .contactFallbackTitle)
        }
    }
    
    func testClassifiedPortalTaskSection1Hidden() {
        let testCategories: [Task.Contact.Category] = [.category1, .category2a, .category2b, .category3a, .category3b]
        
        for category in testCategories {
            let input = ContactQuestionnaireViewModel.Input(
                caseReference: nil,
                guidelines: guidelines,
                featureFlags: FeatureFlags(enableContactCalling: true, enablePerspectiveCopy: true, enableSelfBCO: true),
                isCaseWindowExpired: false,
                task: createContactTask(category: category, source: .portal),
                questionnaire: fullQuestionnaire,
                contact: nil)
            
            let viewModel = ContactQuestionnaireViewModel(input)
            let sectionViews = setupSectionViews(for: viewModel)
            
            XCTAssertTrue(sectionViews[0].isHidden)
        }
    }
    
    func testClassifiedAppTaskSection1Visibile() {
        let testCategories: [Task.Contact.Category] = [.category1, .category2a, .category2b, .category3a, .category3b]
        
        for category in testCategories {
            let input = ContactQuestionnaireViewModel.Input(
                caseReference: nil,
                guidelines: guidelines,
                featureFlags: FeatureFlags(enableContactCalling: true, enablePerspectiveCopy: true, enableSelfBCO: true),
                isCaseWindowExpired: false,
                task: createContactTask(category: category, source: .app),
                questionnaire: fullQuestionnaire,
                contact: nil)
            
            let viewModel = ContactQuestionnaireViewModel(input)
            let sectionViews = setupSectionViews(for: viewModel)
            
            XCTAssertFalse(sectionViews[0].isHidden)
        }
    }
    
    func testClassifiedAppTaskSection1Collapsed() {
        let testCategories: [Task.Contact.Category] = [.category1, .category2a, .category2b, .category3a, .category3b]
        
        for category in testCategories {
            let input = ContactQuestionnaireViewModel.Input(
                caseReference: nil,
                guidelines: guidelines,
                featureFlags: FeatureFlags(enableContactCalling: true, enablePerspectiveCopy: true, enableSelfBCO: true),
                isCaseWindowExpired: false,
                task: createContactTask(category: category, source: .app),
                questionnaire: fullQuestionnaire,
                contact: nil)
            
            let viewModel = ContactQuestionnaireViewModel(input)
            let sectionViews = setupSectionViews(for: viewModel)
            
            XCTAssertTrue(sectionViews[0].isCollapsed)
        }
    }
    
    func testClassifiedAppTaskWithoutLastExposureSection1Expanded() {
        let testCategories: [Task.Contact.Category] = [.category1, .category2a, .category2b, .category3a, .category3b]
        
        for category in testCategories {
            let input = ContactQuestionnaireViewModel.Input(
                caseReference: nil,
                guidelines: guidelines,
                featureFlags: FeatureFlags(enableContactCalling: true, enablePerspectiveCopy: true, enableSelfBCO: true),
                isCaseWindowExpired: false,
                task: createContactTask(category: category, source: .app, dateOfLastExposure: nil),
                questionnaire: fullQuestionnaire,
                contact: nil)
            
            let viewModel = ContactQuestionnaireViewModel(input)
            let sectionViews = setupSectionViews(for: viewModel)
            
            XCTAssertFalse(sectionViews[0].isCollapsed)
            XCTAssertFalse(sectionViews[1].isEnabled)
            XCTAssertFalse(sectionViews[2].isEnabled)
        }
    }
    
    func testUpdateCategory() {
        let input = ContactQuestionnaireViewModel.Input(
            caseReference: nil,
            guidelines: guidelines,
            featureFlags: FeatureFlags(enableContactCalling: true, enablePerspectiveCopy: true, enableSelfBCO: true),
            isCaseWindowExpired: false,
            task: createContactTask(category: .category2b, source: .app, dateOfLastExposure: .now),
            questionnaire: fullQuestionnaire,
            contact: nil)
        
        let viewModel = ContactQuestionnaireViewModel(input)
        let sectionViews = setupSectionViews(for: viewModel)
        
        XCTAssertEqual(viewModel.updatedTask.contact.category, .category2b)
        
        let toggleButtons = sectionViews[0].contentView.subviewsOfType() as [ToggleButton]
        toggleButtons
            .first { $0.currentTitle == .physicalContactRiskQuestionAnswerNegative }?
            .sendActions(for: .touchUpInside)
        
        XCTAssertEqual(viewModel.updatedTask.contact.category, .category3a)
    }
    
    func testOtherCategoryState() {
        let input = ContactQuestionnaireViewModel.Input(
            caseReference: nil,
            guidelines: guidelines,
            featureFlags: FeatureFlags(enableContactCalling: true, enablePerspectiveCopy: true, enableSelfBCO: true),
            isCaseWindowExpired: false,
            task: createContactTask(category: .other, source: .app, dateOfLastExposure: .now),
            questionnaire: fullQuestionnaire,
            contact: nil)
        
        let viewModel = ContactQuestionnaireViewModel(input)
        let sectionViews = setupSectionViews(for: viewModel)
        
        XCTAssertTrue(viewModel.contactShouldBeDeleted)
        XCTAssertTrue(viewModel.showDeleteButton)
        
        XCTAssertFalse(viewModel.didCreateNewTask)
        XCTAssertFalse(viewModel.canSafelyCancel)
        XCTAssertFalse(viewModel.isDisabled)
        
        XCTAssertFalse(sectionViews[0].isCollapsed)
        XCTAssertFalse(sectionViews[1].isEnabled)
        XCTAssertFalse(sectionViews[2].isEnabled)
    }
    
    func testContactDetailsPrefilling() {
        let testCategories: [Task.Contact.Category] = [.category1, .category2a, .category2b, .category3a, .category3b]
        
        for category in testCategories {
            let input = ContactQuestionnaireViewModel.Input(
                caseReference: nil,
                guidelines: guidelines,
                featureFlags: FeatureFlags(enableContactCalling: true, enablePerspectiveCopy: true, enableSelfBCO: true),
                isCaseWindowExpired: false,
                task: createContactTask(category: category, source: .app, dateOfLastExposure: .now),
                questionnaire: simpleQuestionnaire,
                contact: fullContact)
            
            let viewModel = ContactQuestionnaireViewModel(input)
            let sectionViews = setupSectionViews(for: viewModel)
            
            XCTAssertEqual(viewModel.updatedTask.contactPhoneNumber, "0612345678")
            XCTAssertEqual(viewModel.updatedTask.contactEmail, "anna@haro.com")
            XCTAssertEqual(viewModel.updatedTask.contactName, "Anna Haro")
            
            XCTAssertTrue(sectionViews[0].isCollapsed)
            XCTAssertTrue(sectionViews[1].isCollapsed)
            XCTAssertFalse(sectionViews[2].isCollapsed)
            
            XCTAssertTrue(sectionViews[0].isEnabled)
            XCTAssertTrue(sectionViews[1].isEnabled)
            XCTAssertTrue(sectionViews[2].isEnabled)
        }
    }
    
    func testDisabledCopyNewTask() {
        let input = ContactQuestionnaireViewModel.Input(
            caseReference: nil,
            guidelines: guidelines,
            featureFlags: FeatureFlags(enableContactCalling: true, enablePerspectiveCopy: false, enableSelfBCO: true),
            isCaseWindowExpired: false,
            task: nil,
            questionnaire: fullQuestionnaire,
            contact: nil)
        
        let viewModel = ContactQuestionnaireViewModel(input)
        
        XCTAssertTrue(viewModel.copyButtonHidden)
    }
    
    func testVisibleCallButton() {
        let input = ContactQuestionnaireViewModel.Input(
            caseReference: nil,
            guidelines: guidelines,
            featureFlags: FeatureFlags(enableContactCalling: true, enablePerspectiveCopy: true, enableSelfBCO: true),
            isCaseWindowExpired: false,
            task: createContactTask(category: .category1, source: .app, dateOfLastExposure: .now),
            questionnaire: simpleQuestionnaire,
            contact: fullContact)
        
        let viewModel = ContactQuestionnaireViewModel(input)
        
        XCTAssertFalse(viewModel.informButtonHidden)
    }
    
    func testHiddenCallButtonForMissingNumber() {
        let input = ContactQuestionnaireViewModel.Input(
            caseReference: nil,
            guidelines: guidelines,
            featureFlags: FeatureFlags(enableContactCalling: true, enablePerspectiveCopy: true, enableSelfBCO: true),
            isCaseWindowExpired: false,
            task: createContactTask(category: .category1, source: .app, dateOfLastExposure: .now),
            questionnaire: simpleQuestionnaire,
            contact: contactMissingNumber)
        
        let viewModel = ContactQuestionnaireViewModel(input)
        
        XCTAssertTrue(viewModel.informButtonHidden)
    }
    
    func testCallButtonDisabledForFeatureFlag() {
        let input = ContactQuestionnaireViewModel.Input(
            caseReference: nil,
            guidelines: guidelines,
            featureFlags: FeatureFlags(enableContactCalling: false, enablePerspectiveCopy: true, enableSelfBCO: true),
            isCaseWindowExpired: false,
            task: createContactTask(category: .category1, source: .app, dateOfLastExposure: .now),
            questionnaire: simpleQuestionnaire,
            contact: fullContact)
        
        let viewModel = ContactQuestionnaireViewModel(input)
        
        XCTAssertTrue(viewModel.informButtonHidden)
    }

}

private let lastExposureDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar.current
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy-MM-dd"
    
    return formatter
}()

private func createSectionView(with views: [UIView]) -> SectionView {
    let sectionView = SectionView(title: "section view", caption: "section", index: 0)
    sectionView.collapse(animated: false)
    
    VStack(spacing: 16, views)
        .embed(in: sectionView.contentView.readableWidth)
    
    return sectionView
}

private func createContactTask(category: Task.Contact.Category, source: Task.Source, dateOfLastExposure: Date? = .now) -> Task {
    let exposureDateString = dateOfLastExposure.map(lastExposureDateFormatter.string)
    var task = Task(type: .contact, label: nil, source: source)
    task.contact = .init(category: category, communication: .unknown, informedByIndexAt: nil, dateOfLastExposure: exposureDateString)
    return task
}

private func setupSectionViews(for viewModel: ContactQuestionnaireViewModel) -> [SectionView] {
    let sectionViews: [SectionView] = [
        createSectionView(with: viewModel.classificationViews),
        createSectionView(with: viewModel.contactDetailViews),
        createSectionView(with: [])
    ]
    
    viewModel.classificationSectionView = sectionViews[0]
    viewModel.detailsSectionView = sectionViews[1]
    viewModel.informSectionView = sectionViews[2]
    
    return sectionViews
}

private let fullContact: CNContact = {
    let contact = CNMutableContact()
    contact.givenName = "Anna"
    contact.familyName = "Haro"
    contact.phoneNumbers = [.init(label: "home", value: .init(stringValue: "0612345678"))]
    contact.emailAddresses = [.init(label: "home", value: .init(string: "anna@haro.com"))]
    
    return contact
}()

private let contactMissingNumber: CNContact = {
    let contact = CNMutableContact()
    contact.givenName = "Anna"
    contact.familyName = "Haro"
    contact.emailAddresses = [.init(label: "home", value: .init(string: "anna@haro.com"))]
    
    return contact
}()

private let contactMissingEmail: CNContact = {
    let contact = CNMutableContact()
    contact.givenName = "Anna"
    contact.familyName = "Haro"
    contact.phoneNumbers = [.init(label: "home", value: .init(stringValue: "0612345678"))]
    
    return contact
}()

private let guidelinesJSON = """
{
  "introExposureDateKnown": {
    "category1": "Je bent een huisgenoot van iemand die corona heeft. Je bent hierdoor misschien besmet geraakt of kan dat nog worden.<br/><br/>Als je inderdaad besmet bent, kun je het virus aan anderen doorgeven. Ook als je je nu niet ziek voelt. Daarom vraagt de GGD je om je aan deze leefregels te houden:",
    "category2": "Je bent (op {ExposureDate}) in nauw contact geweest met iemand die corona heeft. Je bent hierdoor misschien besmet geraakt.<br/><br/>Als je inderdaad besmet bent, kun je het virus aan anderen doorgeven. Ook als je je nu niet ziek voelt. Daarom vraagt de GGD je om je aan deze leefregels te houden:",
    "category3": "Je bent (op {ExposureDate}) in de buurt geweest van iemand die corona heeft. De kans dat je hierdoor misschien besmet geraakt is klein.<br/><br/>Als je wel besmet bent, kun je het virus aan anderen doorgeven. Ook als je je nu niet ziek voelt."
  },
  "introExposureDateUnknown": {
    "category1": "Je bent een huisgenoot van iemand die corona heeft. Je bent hierdoor misschien besmet geraakt of kan dat nog worden.<br/><br/>Als je inderdaad besmet bent, kun je het virus aan anderen doorgeven. Ook als je je nu niet ziek voelt. Daarom vraagt de GGD je om je aan deze leefregels te houden:",
    "category2": "Je bent in nauw contact geweest met iemand die corona heeft. Je bent hierdoor misschien besmet geraakt.<br/><br/>Als je inderdaad besmet bent, kun je het virus aan anderen doorgeven. Ook als je je nu niet ziek voelt. Daarom vraagt de GGD je om je aan deze leefregels te houden:",
    "category3": "Je bent in de buurt geweest van iemand die corona heeft. De kans dat je hierdoor misschien besmet geraakt is klein.<br/><br/>Als je wel besmet bent, kun je het virus aan anderen doorgeven. Ook als je je nu niet ziek voelt."
  },
  "guidelinesExposureDateKnown": {
    "category1": "<ul><li>Blijf thuis, vermijd contact met je besmette huisgenoot en ontvang geen bezoek.</li><li>Doe zo snel mogelijk een coronatest. Als je besmet blijkt, kun je samen met de GGD meteen maatregelen nemen.</li><li>Doe <b>5 dagen</b> na het laatste contact met je besmette huisgenoot nog een coronatest. Ook als je geen klachten hebt gekregen. Blijkt uit die test dat je geen corona hebt? Dan mag je weer naar buiten.</li><li>De afspraak voor een coronatest maak je via <a href=\\"tel:0800-2035\\">0800-2035</a>.</li><li>Doe je geen coronatest? Dan blijf je thuis tot en met <b>10 dagen</b> na het laatste contact. Je mag op z’n vroegst weer naar buiten op {ExposureDate+11}</li><li>Let op gezondheidsklachten die passen bij COVID-19 en laat je direct testen als je klachten krijgt.</li><li>Was regelmatig je handen met water en zeep, hoest en nies in je elleboog.</li>{ReferenceNumberItem}</ul>",
    "category2": {
      "withinRange": "<ul><li>Blijf thuis en ontvang geen bezoek.</li><li>Doe zo snel mogelijk een coronatest. Als je besmet blijkt, kun je samen met de GGD meteen maatregelen nemen.</li><li>De afspraak voor een coronatest maak je via <a href=\\"tel:0800-2035\\">0800-2035</a>.</li><li>Maak ook meteen een afspraak om je op of na <b>{ExposureDate+5}</b> nog een keer te laten testen. Het kan soms namelijk een aantal dagen duren voordat een test kan meten dat je bent besmet.</li><li>Blijf dus thuis tot uit de test op of na <b>{ExposureDate+5}</b> blijkt dat je geen corona hebt.</li><li>Doe je geen coronatest? Dan blijf je thuis tot en met <b>{ExposureDate+10}</b></li><li>Let op gezondheidsklachten die passen bij COVID-19 en laat je direct testen als je klachten krijgt.</li><li>Was regelmatig je handen met water en zeep, hoest en nies in je elleboog</li>{ReferenceNumberItem}</ul>",
      "outsideRange": "<ul><li>Blijf thuis en ontvang geen bezoek.</li><li>Maak een afspraak voor een coronatest op of na <b>{ExposureDate+5}</b>. Blijkt uit de test dat je geen corona hebt? Dan mag je weer naar buiten.</li><li>De afspraak voor een coronatest maak je via <a href=\\"tel:0800-2035\\">0800-2035</a>.</li><li>Doe je geen coronatest? Dan blijf je thuis tot en met <b>{ExposureDate+10}</b></li><li>Let op gezondheidsklachten die passen bij COVID-19 en laat je direct testen als je klachten krijgt.</li><li>Was regelmatig je handen met water en zeep, hoest en nies in je elleboog</li>{ReferenceNumberItem}</ul>"
    },
    "category3": "<ul><li>Doe een coronatest op of na <b>{ExposureDate+5}</b>. Ook als je geen klachten hebt.</li><li>De afspraak voor een coronatest maak je via <a href=\\"tel:0800-2035\\">0800-2035</a>.</li><li>Let op gezondheidsklachten die passen bij COVID-19 en laat je direct testen als je klachten krijgt.</li><li>Was regelmatig je handen met water en zeep, hoest en nies in je elleboog</li>{ReferenceNumberItem}</ul>"
  },
  "guidelinesExposureDateUnknown": {
    "category1": "<ul><li>Blijf thuis, vermijd contact met je besmette huisgenoot en ontvang geen bezoek.</li><li>Doe zo snel mogelijk een coronatest. Als je besmet blijkt, kun je samen met de GGD meteen maatregelen nemen.</li><li>Doe <b>5 dagen</b> na het laatste contact met je besmette huisgenoot nog een coronatest. Ook als je geen klachten hebt gekregen. Blijkt uit die test dat je geen corona hebt? Dan mag je weer naar buiten.</li><li>De afspraak voor een coronatest maak je via <a href=\\"tel:0800-2035\\">0800-2035</a>.</li><li>Doe je geen coronatest? Dan blijf je thuis tot en met <b>10 dagen</b> na het laatste contact.</li><li>Let op gezondheidsklachten die passen bij COVID-19 en laat je direct testen als je klachten krijgt</li><li>Was regelmatig je handen met water en zeep, hoest en nies in je elleboog</li>{ReferenceNumberItem}</ul>",
    "category2": "<ul><li>Blijf thuis en ontvang geen bezoek.</li><li>Doe zo snel mogelijk een coronatest. En ook <b>5 dagen</b> na het laatste contact. Als uit beide tests blijkt dat je niet besmet bent, mag je weer naar buiten.</li><li>De afspraak voor een coronatest maak je via <a href=\\"tel:0800-2035\\">0800-2035</a>.</li><li>Doe je geen coronatest? Dan blijf je thuis tot en met <b>10 dagen</b> na het laatste contact.</li><li>Let op gezondheidsklachten die passen bij COVID-19 en laat je direct testen als je klachten krijgt</li><li>Was regelmatig je handen met water en zeep, hoest en nies in je elleboog</li>{ReferenceNumberItem}</ul>",
    "category3": "<ul><li>Doe een coronatest <b>5 dagen</b> na het laatste contact. Ook als je geen klachten hebt.</li><li>De afspraak voor een coronatest maak je via <a href=\\"tel:0800-2035\\">0800-2035</a>.</li><li>Let op gezondheidsklachten die passen bij COVID-19 en laat je direct testen als je klachten krijgt</li><li>Was regelmatig je handen met water en zeep, hoest en nies in je elleboog</li>{ReferenceNumberItem}</ul>"
  },
  "referenceNumberItem": "<li>Blijkt uit de test dat je corona hebt? Geef dan dit casenummer door aan de GGD: <b>{ReferenceNumber}</b></li>",
  "outro": {
    "category1": "Meer informatie over omgaan met een besmette huisgenoot en algemene regels als je met iemand woont die corona heeft, lees je op: <a href=\\"https://lci.rivm.nl/covid-19-huisgenoten\\">lci.rivm.nl/covid-19-huisgenoten</a>",
    "category2": "Alle leefregels staan op <a href=\\"https://lci.rivm.nl/covid-19-nauwe-contacten\\">lci.rivm.nl/covid-19-nauwe-contacten</a>",
    "category3": "Alle leefregels staan op <a href=\\"https://lci.rivm.nl/covid-19-overige-contacten\\">lci.rivm.nl/covid-19-overige-contacten</a>"
  }
}
"""

private let questionnaireJSON = """
{
  "uuid": "f8477eb7-07e5-4079-816b-b8f248a94f92",
  "taskType": "contact",
  "version": 6,
  "questions": [
    {
      "uuid": "a6e00a18-7a27-4314-b6d9-b1c92cac137e",
      "group": "classification",
      "questionType": "classificationdetails",
      "label": "Vragen over jullie ontmoeting",
      "description": null,
      "relevantForCategories": [
        {
          "category": "1"
        },
        {
          "category": "2a"
        },
        {
          "category": "2b"
        },
        {
          "category": "3a"
        },
        {
          "category": "3b"
        }
      ]
    },
    {
      "uuid": "6b9501f0-c69c-43b1-a268-4f34a83715ee",
      "group": "contactdetails",
      "questionType": "contactdetails",
      "label": "Contactgegevens",
      "description": null,
      "relevantForCategories": [
        {
          "category": "1"
        },
        {
          "category": "2a"
        },
        {
          "category": "2b"
        },
        {
          "category": "3a"
        },
        {
          "category": "3b"
        }
      ]
    },
    {
      "uuid": "a28df29d-3ee0-4956-ba2b-0fe75f6ff9bd",
      "group": "contactdetails",
      "questionType": "date",
      "label": "Geboortedatum",
      "description": null,
      "relevantForCategories": [
        {
          "category": "1"
        }
      ]
    },
    {
      "uuid": "119e2136-d2ca-44de-8961-172c8a0085bb",
      "group": "contactdetails",
      "questionType": "multiplechoice",
      "label": "Wat is deze persoon van je?",
      "description": null,
      "relevantForCategories": [
        {
          "category": "1"
        },
        {
          "category": "2a"
        },
        {
          "category": "2b"
        },
        {
          "category": "3a"
        },
        {
          "category": "3b"
        }
      ],
      "answerOptions": [
        {
          "label": "Ouder",
          "value": "parent"
        },
        {
          "label": "Kind",
          "value": "child"
        },
        {
          "label": "Broer of zus",
          "value": "sibling"
        },
        {
          "label": "Partner",
          "value": "partner"
        },
        {
          "label": "Familielid (overig)",
          "value": "family"
        },
        {
          "label": "Huisgenoot",
          "value": "roommate"
        },
        {
          "label": "Vriend of kennis",
          "value": "friend"
        },
        {
          "label": "Medestudent of leerling",
          "value": "student"
        },
        {
          "label": "Collega",
          "value": "colleague"
        },
        {
          "label": "Gezondheidszorg medewerker",
          "value": "health"
        },
        {
          "label": "Ex-partner",
          "value": "ex"
        },
        {
          "label": "Overig",
          "value": "other"
        }
      ]
    },
    {
      "uuid": "a92fc06e-9ac9-48c1-8710-5d232cec883a",
      "group": "contactdetails",
      "questionType": "open",
      "label": "Moet de GGD nog iets weten?",
      "description": "Bijvoorbeeld: omschrijving van het contact moment",
      "relevantForCategories": [
        {
          "category": "1"
        },
        {
          "category": "2a"
        },
        {
          "category": "2b"
        },
        {
          "category": "3a"
        },
        {
          "category": "3b"
        }
      ]
    }
  ]
}
"""

private let simpleQuestionnaireJSON = """
{
  "uuid": "f8477eb7-07e5-4079-816b-b8f248a94f92",
  "taskType": "contact",
  "version": 6,
  "questions": [
    {
      "uuid": "a6e00a18-7a27-4314-b6d9-b1c92cac137e",
      "group": "classification",
      "questionType": "classificationdetails",
      "label": "Vragen over jullie ontmoeting",
      "description": null,
      "relevantForCategories": [
        {
          "category": "1"
        },
        {
          "category": "2a"
        },
        {
          "category": "2b"
        },
        {
          "category": "3a"
        },
        {
          "category": "3b"
        }
      ]
    },
    {
      "uuid": "6b9501f0-c69c-43b1-a268-4f34a83715ee",
      "group": "contactdetails",
      "questionType": "contactdetails",
      "label": "Contactgegevens",
      "description": null,
      "relevantForCategories": [
        {
          "category": "1"
        },
        {
          "category": "2a"
        },
        {
          "category": "2b"
        },
        {
          "category": "3a"
        },
        {
          "category": "3b"
        }
      ]
    }
  ]
}
"""

private extension Question {
    static var lastExposureDateQuestion: Question {
        return Question(uuid: UUID(),
                        group: .classification,
                        questionType: .lastExposureDate,
                        label: .contactInformationLastExposure,
                        description: nil,
                        relevantForCategories: [.category1, .category2a, .category2b, .category3a, .category3b, .other],
                        answerOptions: nil,
                        disabledForSources: [.portal])
    }
    
    var disabledForPortal: Question {
        return Question(uuid: uuid,
                        group: group,
                        questionType: questionType,
                        label: label,
                        description: description,
                        relevantForCategories: relevantForCategories,
                        answerOptions: answerOptions,
                        disabledForSources: [.portal])
    }
}

private extension UIView {
    
    func subviewsOfType<T: UIView>() -> [T] {
        var subviews = [T]()
        self.subviews.forEach { subview in
            subviews += subview.subviewsOfType() as [T]
            if let subview = subview as? T {
                subviews.append(subview)
            }
        }
        return subviews
    }
}
