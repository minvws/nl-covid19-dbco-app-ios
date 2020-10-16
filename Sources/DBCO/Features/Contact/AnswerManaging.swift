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

class ContactDetailsAnswerManager: AnswerManaging {
    private(set) var firstName = FirstName()
    private(set) var lastName = LastName()
    private(set) var email = EmailAddress()
    private(set) var phoneNumber = PhoneNumber()
    
    private var baseAnswer: Answer
    
    let question: Question
    
    init(question: Question, answer: Answer, contact: CNContact?) {
        self.baseAnswer = answer
        self.question = question
        
        if let contact = contact {
            baseAnswer.value = .contactDetails(contact: contact)
        }
        
        guard case .contactDetails(let firstName, let lastName, let email, let phoneNumber) = baseAnswer.value else {
            fatalError()
        }
            
        self.firstName.value = firstName
        self.lastName.value = lastName
        self.email.value = email
        self.phoneNumber.value = phoneNumber
    }
    
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
    
    private(set) lazy var view: UIView = InputField(for: self, path: \.date)
        .decorateWithDescriptionIfNeeded(description: question.description)
    
    let question: Question
    
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
    
    private(set) lazy var view: UIView = InputTextView(for: self, path: \.text)
        .decorateWithDescriptionIfNeeded(description: question.description)
    
    let question: Question
    
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
    
    private(set) lazy var view: UIView = {
        if options != nil {
            return InputField(for: self, path: \.options)
                .decorateWithDescriptionIfNeeded(description: question.description)
        } else {
            return buttons
                .decorateWithDescriptionIfNeeded(description: question.description)
        }
    }()
    
    let question: Question
    
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
