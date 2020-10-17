/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit
import Contacts

protocol AnswerManaging {
    var question: Question { get }
    var answer: Answer { get }
    var view: UIView { get }
}

class ClassificationDetailsAnswerManager: AnswerManaging {
    private var baseAnswer: Answer
    
    private var livedTogetherRisk: Bool? { didSet { determineGroupVisibility() } }
    private var durationRisk: Bool? { didSet { determineGroupVisibility() } }
    private var distanceRisk: Bool? { didSet { determineGroupVisibility() } }
    private var otherRisk: Bool? { didSet { determineGroupVisibility() } }
    
    private var classification: ClassificationHelper.Result
    
    init(question: Question, answer: Answer, contactCategory: Task.Contact.Category?) {
        self.baseAnswer = answer
        self.question = question
        
        if let contactCategory = contactCategory {
            baseAnswer.value = .classificationDetails(contactCategory: contactCategory)
        }
        
        guard case .classificationDetails(let livedTogetherRisk, let durationRisk, let distanceRisk, let otherRisk) = baseAnswer.value else {
            fatalError()
        }
        
        self.livedTogetherRisk = livedTogetherRisk
        self.durationRisk = durationRisk
        self.distanceRisk = distanceRisk
        self.otherRisk = otherRisk
        
        classification = .needsAssessmentFor(.livedTogether)
        
        determineClassification()
        determineGroupVisibility()
    }
    
    private func determineClassification() {
        classification = ClassificationHelper.classification(for: livedTogetherRisk,
                                                             durationRisk: durationRisk,
                                                             distanceRisk: distanceRisk,
                                                             otherRisk: otherRisk)
    }
    
    private func determineGroupVisibility() {
        
        let risks: [ClassificationHelper.Risk]
        
        switch classification {
        case .success(let category):
            risks = ClassificationHelper.classifiedRisks(for: category)
        case .needsAssessmentFor(let risk):
            risks = ClassificationHelper.classifiedRisks(forUnassessedRisk: risk) + [risk]
        }
        
        livedTogetherRiskGroup.isHidden = !risks.contains(.livedTogether)
        durationRiskGroup.isHidden = !risks.contains(.duration)
        distanceRiskGroup.isHidden = !risks.contains(.distance)
        otherRiskGroup.isHidden = !risks.contains(.other)
    }
    
    let question: Question
    
    var answer: Answer {
        determineClassification()
        
        var answer = baseAnswer
        
        switch classification {
        case .success(let category):
            answer.value = .classificationDetails(contactCategory: category)
        case .needsAssessmentFor(_):
            answer.value = .classificationDetails(livedTogetherRisk: livedTogetherRisk,
                                                  durationRisk: durationRisk,
                                                  distanceRisk: distanceRisk,
                                                  otherRisk: otherRisk)
        }
        
        return answer
    }
    
    private lazy var livedTogetherRiskGroup =
        ToggleGroup(label: "Woon je in hetzelfde huis of ben je langer dan 12 uur op dezelfde plek geweest?",
                    ToggleButton(title: "Nee", selected: livedTogetherRisk == false),
                    ToggleButton(title: "Ja", selected: livedTogetherRisk == true))
        .didSelect { [unowned self] in self.livedTogetherRisk = $0 == 1 }
    
    private lazy var durationRiskGroup =
        ToggleGroup(label: "Hoe lang waren jullie waarschijnlijk bij elkaar in de buurt?",
                    ToggleButton(title: "Langer dan 15 minuten", selected: durationRisk == true),
                    ToggleButton(title: "Korter dan 15 minuten", selected: durationRisk == false))
        .didSelect { [unowned self] in self.durationRisk = $0 == 0 }
    
    private lazy var distanceRiskGroup =
        ToggleGroup(label: "Zijn jullie binnen 1,5 meter van elkaar geweest?",
                    ToggleButton(title: "Ja, denk het wel", selected: distanceRisk == true),
                    ToggleButton(title: "Nee, denk het niet", selected: distanceRisk == false))
        .didSelect { [unowned self] in self.distanceRisk = $0 == 0 }
    
    private lazy var otherRiskGroup =
        ToggleGroup(label: "Is een of meerdere van deze dingen tijdens jullie ontmoeting gebeurd?",
                    ToggleButton(title: "Ja, één of meer", selected: otherRisk == true),
                    ToggleButton(title: "Nee, denk het niet", selected: otherRisk == false))
        .didSelect { [unowned self] in self.otherRisk = $0 == 0 }
        .decorateWithDescriptionIfNeeded(description: "* In je gezicht geniesd\n* Geknuffeld of gezoend\n* Ander lichamelijk contact")
    
    private(set) lazy var view: UIView =
        VStack(spacing: 24,
               livedTogetherRiskGroup,
               durationRiskGroup,
               distanceRiskGroup,
               otherRiskGroup)
}

class ContactDetailsAnswerManager: AnswerManaging {
    private(set) var firstName = FirstName()
    private(set) var lastName = LastName()
    private(set) var email = EmailAddress()
    private(set) var phoneNumber = PhoneNumber()
    
    private var baseAnswer: Answer
    
    init(question: Question, answer: Answer, contact: CNContact?) {
        self.baseAnswer = answer
        self.question = question
        
        if let contact = contact {
            baseAnswer.value = .contactDetails(contact: contact)
        }
        
        switch baseAnswer.value {
        case .contactDetails(let firstName, let lastName, let email, let phoneNumber),
             .contactDetailsFull(let firstName, let lastName, let email, let phoneNumber):
            self.firstName.value = firstName
            self.lastName.value = lastName
            self.email.value = email
            self.phoneNumber.value = phoneNumber
        default:
            fatalError()
        }
    }
    
    let question: Question
    
    private(set) lazy var view: UIView =
        VStack(spacing: 16,
               HStack(spacing: 15,
                      InputField(for: self, path: \.firstName),
                      InputField(for: self, path: \.lastName)).distribution(.fillEqually),
               InputField(for: self, path: \.phoneNumber),
               InputField(for: self, path: \.email))
    
    var answer: Answer {
        var answer = baseAnswer
        answer.value = .contactDetails(firstName: firstName.value, lastName: lastName.value, email: email.value, phoneNumber: phoneNumber.value)
        return answer
    }
}

class DateAnswerManager: AnswerManaging {
    private(set) var date: GeneralDate
    
    private var baseAnswer: Answer
    
    init(question: Question, answer: Answer) {
        self.baseAnswer = answer
        self.question = question
        
        guard case .date(let date) = baseAnswer.value else {
            fatalError()
        }
            
        self.date = GeneralDate(label: question.label, date: date)
    }
    
    let question: Question
    
    private(set) lazy var view: UIView = InputField(for: self, path: \.date)
        .decorateWithDescriptionIfNeeded(description: question.description)
    
    var answer: Answer {
        var answer = baseAnswer
        answer.value = .date(date.dateValue)
        return answer
    }
}

class OpenAnswerManager: AnswerManaging {
    private(set) var text: Text
    
    private var baseAnswer: Answer
    
    init(question: Question, answer: Answer) {
        self.baseAnswer = answer
        self.question = question
        
        guard case .open(let text) = baseAnswer.value else {
            fatalError()
        }
            
        self.text = Text(label: question.label, value: text)
    }
    
    let question: Question
    
    private(set) lazy var view: UIView = InputTextView(for: self, path: \.text)
        .decorateWithDescriptionIfNeeded(description: question.description)
    
    var answer: Answer {
        var answer = baseAnswer
        answer.value = .open(text.value)
        return answer
    }
}

class MultipleChoiceAnswerManager: AnswerManaging {
    
    private var baseAnswer: Answer
    
    private var options: Options!
    private var buttons: ToggleGroup!
    private var selectedButtonIndex: Int?
 
    init(question: Question, answer: Answer) {
        self.baseAnswer = answer
        self.question = question
        
        guard case .multipleChoice(let option) = baseAnswer.value else {
            fatalError()
        }
        
        let answerOptions = question.answerOptions ?? []
        
        if answerOptions.count > 4 {
            self.options = Options(label: question.label,
                                    value: option?.value,
                                    options: answerOptions.map { ($0.value, $0.label) })
        } else {
            self.selectedButtonIndex = question.answerOptions?.firstIndex { $0.value == option?.value }
            
            self.buttons = ToggleGroup(label: question.label, answerOptions.map { ToggleButton(title: $0.label, selected: $0.value == option?.value) } )
                .didSelect { [unowned self] in selectedButtonIndex = $0 }
        }
    }
    
    let question: Question
    
    private(set) lazy var view: UIView = {
        if options != nil {
            return InputField(for: self, path: \.options)
                .decorateWithDescriptionIfNeeded(description: question.description)
        } else {
            return buttons
                .decorateWithDescriptionIfNeeded(description: question.description)
        }
    }()
    
    var answer: Answer {
        if options != nil {
            let selectedOption = question.answerOptions?
                .first { $0.value == options.value }
            var answer = baseAnswer
            answer.value = .multipleChoice(selectedOption)
            return answer
        } else if let index = selectedButtonIndex {
            var answer = baseAnswer
            answer.value = .multipleChoice(question.answerOptions?[index])
            return answer
        } else {
            var answer = baseAnswer
            answer.value = .multipleChoice(nil)
            return answer
        }
    }
}
