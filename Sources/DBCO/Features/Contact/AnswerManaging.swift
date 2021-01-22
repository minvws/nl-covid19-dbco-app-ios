/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit
import Contacts

extension AnswerOption {
    static let lastExposureDateEarlierOption = AnswerOption(label: .contactInformationLastExposureEarlier,
                                                            value: "earlier",
                                                            trigger: nil)
}

/// - Tag: AnswerManaging
protocol AnswerManaging: class {
    var question: Question { get }
    var answer: Answer { get }
    var view: UIView { get }
    
    var isEnabled: Bool { get set }
    
    var hasValidAnswer: Bool { get }
    
    var updateHandler: ((AnswerManaging) -> Void)? { get set }
}

/// AnswerManager for the .classificationDetails question.
/// Uses [ClassificationHelper](x-source-tag://ClassificationHelper) to determine the resulting category and which of the four (risk) questions should be displayed.
/// The risk questions are displayed as [ToggleGroup](x-source-tag://ToggleGroup)
class ClassificationDetailsAnswerManager: AnswerManaging {
    private var baseAnswer: Answer
    
    // swiftlint:disable opening_brace
    private var category1Risk: Bool?    { didSet { determineGroupVisibility() } }
    private var category2aRisk: Bool?   { didSet { determineGroupVisibility() } }
    private var category2bRisk: Bool?   { didSet { determineGroupVisibility() } }
    private var category3Risk: Bool?    { didSet { determineGroupVisibility() } }
    // swiftlint:enable opening_brace
    
    private(set) var classification: ClassificationHelper.Result
    
    var updateHandler: ((AnswerManaging) -> Void)?
    
    init(question: Question, answer: Answer, contactCategory: Task.Contact.Category?) {
        self.baseAnswer = answer
        self.question = question
        
        if let contactCategory = contactCategory, contactCategory != .other {
            baseAnswer.value = .classificationDetails(contactCategory: contactCategory)
        }
        
        guard case .classificationDetails(let category1Risk, let category2aRisk, let category2bRisk, let category3Risk) = baseAnswer.value else {
            fatalError()
        }
        
        self.category1Risk = category1Risk
        self.category2aRisk = category2aRisk
        self.category2bRisk = category2bRisk
        self.category3Risk = category3Risk
        
        classification = .needsAssessmentFor(.category1)
        determineGroupVisibility()
    }
    
    private func determineClassification() {
        classification = ClassificationHelper.classificationResult(for: category1Risk,
                                                                   category2aRisk: category2aRisk,
                                                                   category2bRisk: category2bRisk,
                                                                   category3Risk: category3Risk)
        
        updateHandler?(self)
    }
    
    private func determineGroupVisibility() {
        determineClassification()
        
        let risks = ClassificationHelper.visibleRisks(for: category1Risk,
                                                      category2aRisk: category2aRisk,
                                                      category2bRisk: category2bRisk,
                                                      category3Risk: category3Risk)
        
        category1RiskGroup.isHidden = !risks.contains(.category1)
        category2aRiskGroup.isHidden = !risks.contains(.category2a)
        category2bRiskGroup.isHidden = !risks.contains(.category2b)
        category3RiskGroup.isHidden = !risks.contains(.category3)
        otherCategoryView.isHidden = classification.category != .other
    }
    
    let question: Question
    
    var answer: Answer {
        var answer = baseAnswer
        
        switch classification {
        case .success(let category):
            answer.value = .classificationDetails(contactCategory: category)
        case .needsAssessmentFor:
            answer.value = .classificationDetails(category1Risk: category1Risk,
                                                  category2aRisk: category2aRisk,
                                                  category2bRisk: category2bRisk,
                                                  category3Risk: category3Risk)
        }
        
        return answer
    }
    
    var isEnabled: Bool = true {
        didSet {
            category1RiskGroup.isEnabled = isEnabled
            category2aRiskGroup.isEnabled = isEnabled
            category2bRiskGroupUndecorated.isEnabled = isEnabled
            category3RiskGroup.isEnabled = isEnabled
        }
    }
    
    var hasValidAnswer: Bool {
        switch classification {
        case .success(let category) where category != .other:
            return true
        default:
            return false
        }
    }
    
    private lazy var category1RiskGroup =
        ToggleGroup(label: .category1RiskQuestion,
                    ToggleButton(title: .category1RiskQuestionAnswerNegative, selected: category1Risk == false),
                    ToggleButton(title: .category1RiskQuestionAnswerPositive, selected: category1Risk == true))
        .didSelect { [unowned self] in self.category1Risk = $0 == 1 }
    
    private lazy var category2aRiskGroup =
        ToggleGroup(label: .category2aRiskQuestion,
                    ToggleButton(title: .category2aRiskQuestionAnswerPositive, selected: category2aRisk == true),
                    ToggleButton(title: .category2aRiskQuestionAnswerNegative, selected: category2aRisk == false))
        .didSelect { [unowned self] in self.category2aRisk = $0 == 0 }
    
    private lazy var category2bRiskGroupUndecorated =
        ToggleGroup(label: .category2bRiskQuestion,
                    ToggleButton(title: .category2bRiskQuestionAnswerPositive, selected: category2bRisk == true),
                    ToggleButton(title: .category2bRiskQuestionAnswerNegative, selected: category2bRisk == false))
        .didSelect { [unowned self] in self.category2bRisk = $0 == 0 }
    
    private lazy var category2bRiskGroup =
        category2bRiskGroupUndecorated
            .decorateWithDescriptionIfNeeded(description: .category2bRiskQuestionDescription)
    
    private lazy var category3RiskGroup =
        ToggleGroup(label: .category3RiskQuestion,
                    ToggleButton(title: .category3RiskQuestionAnswerPositive, selected: category3Risk == true),
                    ToggleButton(title: .category3RiskQuestionAnswerNegative, selected: category3Risk == false))
        .didSelect { [unowned self] in self.category3Risk = $0 == 0 }
    
    private lazy var otherCategoryView: UIView = {
        let containerView = UIView()
        containerView.backgroundColor = Theme.colors.tertiary
        containerView.layer.cornerRadius = 8
        
        VStack(spacing: 16,
               Label(bodyBold: .otherCategoryTitle).multiline(),
               Label(body: .otherCategoryMessage, textColor: Theme.colors.captionGray).multiline())
            .embed(in: containerView, insets: .leftRight(16) + .topBottom(24))
        
        return containerView
    }()
    
    private(set) lazy var view: UIView =
        VStack(spacing: 24,
               category1RiskGroup,
               category2aRiskGroup,
               category2bRiskGroup,
               category3RiskGroup,
               otherCategoryView)
}

/// AnswerManager for the .contactDetails question.
/// Uses [InputField](x-source-tag://InputField) to question the firstName, lastName, email and phoneNumber of the index
class ContactDetailsAnswerManager: AnswerManaging {
    // swiftlint:disable opening_brace
    private(set) var firstName = FirstName()        { didSet { updateHandler?(self) } }
    private(set) var lastName = LastName()          { didSet { updateHandler?(self) } }
    private(set) var email = EmailAddress()         { didSet { updateHandler?(self) } }
    private(set) var phoneNumber = PhoneNumber()    { didSet { updateHandler?(self) } }
    // swiftlint:enable opening_brace
    
    private var baseAnswer: Answer
    
    var updateHandler: ((AnswerManaging) -> Void)?
    
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
        answer.value = .contactDetails(firstName: firstName.value,
                                       lastName: lastName.value,
                                       email: email.value,
                                       phoneNumber: phoneNumber.value)
        return answer
    }
    
    var isEnabled: Bool = true
    
    var hasValidAnswer: Bool {
        return answer.progressElements.contains(true)
    }
}

/// AnswerManager for the .date question.
/// Uses [InputField](x-source-tag://InputField) to display an editable date.
class DateAnswerManager: AnswerManaging {
    private(set) var date: GeneralDate { didSet { updateHandler?(self) } }
    
    private var baseAnswer: Answer
    
    var updateHandler: ((AnswerManaging) -> Void)?
    
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
    
    var isEnabled: Bool = true
    
    var hasValidAnswer: Bool {
        return date.value != nil
    }
}

/// AnswerManager for the .lastExposureDate question.
/// Uses [InputField](x-source-tag://InputField) to display an editable date.
///
/// # See also
/// [lastExposureDate](x-source-tag://lastExposureDate)
class LastExposureDateAnswerManager: AnswerManaging {
    
    private var baseAnswer: Answer
    
    var updateHandler: ((AnswerManaging) -> Void)?
    
    private(set) var options: Options {
        didSet { update() }
    }
    
    init(question: Question, answer: Answer, lastExposureDate: String?) {
        self.baseAnswer = answer
        self.question = question
        
        // Dates should range from 2 days before symptom onset to today
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -2, to: Services.caseManager.dateOfSymptomOnset) ?? endDate
        
        let numberOfDays = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        
        let dateOptions = (0...numberOfDays)
            .compactMap { Calendar.current.date(byAdding: .day, value: $0, to: startDate) }
            .map { AnswerOption(label: Self.displayDateFormatter.string(from: $0),
                                value: Self.valueDateFormatter.string(from: $0),
                                trigger: nil) }
        
        var answerOptions = [.lastExposureDateEarlierOption] + dateOptions
        
        if let lastExposureDate = lastExposureDate {
            if let option = answerOptions.first(where: { $0.value == lastExposureDate }) {
                baseAnswer.value = .lastExposureDate(option)
            } else if let date = Self.valueDateFormatter.date(from: lastExposureDate) {
                // If we got a different valid date, create an option for it
                let option = AnswerOption(label: Self.displayDateFormatter.string(from: date),
                                          value: lastExposureDate,
                                          trigger: nil)
                answerOptions.append(option)
                baseAnswer.value = .lastExposureDate(option)
            }
        }
        
        guard case .lastExposureDate(let option) = baseAnswer.value else {
            fatalError()
        }
        
        self.answerOptions = answerOptions
        self.options = Options(label: question.label,
                                value: option?.value,
                                options: answerOptions.map { ($0.value, $0.label) })
        self.options.labelFont = Theme.fonts.bodyBold
    }
    
    let question: Question
    private let answerOptions: [AnswerOption]
    
    private let disabledIndicatorView: UIView = {
        let iconView = UIImageView(image: UIImage(named: "Warning"))
        iconView.contentMode = .center
        iconView.setContentHuggingPriority(.required, for: .horizontal)
        iconView.tintColor = Theme.colors.primary
        
        let stack = HStack(spacing: 6,
                           iconView,
                           Label(subhead: .contactQuestionDisabledMessage,
                                 textColor: Theme.colors.primary).multiline())
        
        stack.isHidden = true
        
        return stack
    }()
    
    private let earlierIndicatorView: UIView = {
        let containerView = UIView()
        containerView.backgroundColor = Theme.colors.tertiary
        containerView.layer.cornerRadius = 8
        containerView.isHidden = true
        
        VStack(spacing: 16,
               Label(bodyBold: .earlierExposureDateTitle).multiline(),
               Label(body: .earlierExposureDateMessage, textColor: Theme.colors.captionGray).multiline())
            .embed(in: containerView, insets: .leftRight(16) + .topBottom(24))
        
        return containerView
    }()
    
    private lazy var inputField = InputField(for: self, path: \.options)
    
    private(set) lazy var view: UIView = {
        VStack(spacing: 8,
               inputField.decorateWithDescriptionIfNeeded(description: question.description),
               disabledIndicatorView,
               earlierIndicatorView)
    }()
    
    private func update() {
        updateHandler?(self)
        
        if case .lastExposureDate(let option) = answer.value {
            earlierIndicatorView.isHidden = option != .lastExposureDateEarlierOption
        }
    }
    
    var answer: Answer {
        let selectedOption = answerOptions.first { $0.value == options.value }
        var answer = baseAnswer
        answer.value = .lastExposureDate(selectedOption)
        return answer
    }
    
    var isEnabled: Bool = true {
        didSet {
            inputField.isEnabled = isEnabled
            disabledIndicatorView.isHidden = isEnabled
        }
    }
    
    var hasValidAnswer: Bool {
        guard case .lastExposureDate(let value) = answer.value else {
            return false
        }
        
        return value != nil
    }
    
    static let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        formatter.calendar = Calendar.current
        formatter.locale = Locale.current
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        return formatter
    }()
    
    static let valueDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale.current
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        
        return formatter
    }()
}

/// AnswerManager for the .open question.
/// Uses [InputTextView](x-source-tag://InputTextView) to display an editable text view
class OpenAnswerManager: AnswerManaging {
    private(set) var text: Text { didSet { updateHandler?(self) } }
    
    private var baseAnswer: Answer
    
    var updateHandler: ((AnswerManaging) -> Void)?
    
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
    
    var isEnabled: Bool = true
    
    var hasValidAnswer: Bool {
        return text.value != nil
    }
}

/// AnswerManager for the .multipleChoice question.
/// When dealing with more than 4 options it will use a UIPickerView via [InputField](x-source-tag://InputField). When dealing with up to 4 options it will display the options using a [ToggleGroup](x-source-tag://ToggleGroup)
class MultipleChoiceAnswerManager: AnswerManaging {
    
    private var baseAnswer: Answer
    
    var updateHandler: ((AnswerManaging) -> Void)?
    
    private var options: Options! { didSet { updateHandler?(self) } }
    private var buttons: ToggleGroup!
    private var selectedButtonIndex: Int?
 
    init(question: Question, answer: Answer, contact: Task.Contact) {
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
            
            self.buttons = ToggleGroup(label: question.label, answerOptions.map { ToggleButton(title: $0.label, selected: $0.value == option?.value) })
                .didSelect { [unowned self] in
                    selectedButtonIndex = $0
                    updateHandler?(self)
                }
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
    
    var isEnabled: Bool = true {
        didSet {
            buttons?.isEnabled = isEnabled
        }
    }
    
    var hasValidAnswer: Bool {
        guard case .multipleChoice(let value) = answer.value else {
            return false
        }
        
        return value != nil
    }
    
    func applyOption(at index: Int) {
        if options != nil {
            guard question.answerOptions?.indices.contains(index) == true else { return }
            options.value = question.answerOptions?[index].value
        } else {
            selectedButtonIndex = index
            updateHandler?(self)
        }
    }
}
