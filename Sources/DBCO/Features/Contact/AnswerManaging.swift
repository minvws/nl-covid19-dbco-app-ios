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
                                                            value: "earlier")
}

/// - Tag: AnswerManaging
protocol AnswerManaging: AnyObject {
    var question: Question { get }
    var answer: Answer { get }
    var view: UIView { get }
    
    var isEnabled: Bool { get set }
    
    var hasValidAnswer: Bool { get }
    
    var updateHandler: ((AnswerManaging) -> Void)? { get set }
    
    var inputFieldDelegate: InputFieldDelegate? { get set }
}

extension Array where Element == AnswerManaging {
    
    var isFullyCompleted: Bool {
        return map(\.answer)
            .allSatisfy(\.isCompleted)
    }
    
    var essentialsAreCompleted: Bool {
        return map(\.answer)
            .filter(\.isEssential)
            .allSatisfy(\.isCompleted)
    }
    
    var hasValidAnswers: Bool {
        return allSatisfy(\.hasValidAnswer)
    }
}

/// AnswerManager for the .classificationDetails question.
/// Uses [ClassificationHelper](x-source-tag://ClassificationHelper) to determine the resulting category and which of the four (risk) questions should be displayed.
/// The risk questions are displayed as [ToggleGroup](x-source-tag://ToggleGroup)
class ClassificationDetailsAnswerManager: AnswerManaging {
    private var baseAnswer: Answer
    
    private var risks: ClassificationHelper.Risks { didSet { determineGroupVisibility() } }
    
    private(set) var classification: ClassificationHelper.Result
    
    var updateHandler: ((AnswerManaging) -> Void)?
    
    init(question: Question, answer: Answer, contactCategory: Task.Contact.Category?) {
        self.baseAnswer = answer
        self.question = question
        
        if let contactCategory = contactCategory, contactCategory != .other {
            baseAnswer.value = .classificationDetails(contactCategory: contactCategory)
        }
        
        guard case .classificationDetails(let category) = baseAnswer.value else {
            fatalError()
        }
        
        self.risks = .init(sameHousehold: nil, distance: nil, physicalContact: nil, sameRoom: nil)
        
        if let category = category {
            ClassificationHelper.setRisks(for: category, risks: &risks)
        }
        
        classification = .needsAssessmentFor(.sameHousehold)
        determineGroupVisibility()
    }
    
    private func determineClassification() {
        classification = ClassificationHelper.classificationResult(for: risks)
        
        updateHandler?(self)
    }
    
    private func determineGroupVisibility() {
        determineClassification()
        
        let visibleRisks = ClassificationHelper.visibleRisks(for: risks)
        
        sameHouseholdRiskGroup.isHidden = !visibleRisks.contains(.sameHousehold)
        distanceRiskGroup.isHidden = !visibleRisks.contains(.distance)
        physicalContactRiskGroup.isHidden = !visibleRisks.contains(.physicalContact)
        sameRoomRiskGroup.isHidden = !visibleRisks.contains(.sameRoom)
        otherCategoryView.isHidden = classification.category != .other
    }
    
    let question: Question
    
    var answer: Answer {
        var answer = baseAnswer
        
        switch classification {
        case .success(let category):
            answer.value = .classificationDetails(category)
        case .needsAssessmentFor:
            answer.value = .classificationDetails(nil)
        }
        
        return answer
    }
    
    var isEnabled: Bool = true {
        didSet {
            sameHouseholdRiskGroup.isEnabled = isEnabled
            distanceRiskGroup.isEnabled = isEnabled
            physicalContactRiskGroupUndecorated.isEnabled = isEnabled
            sameRoomRiskGroup.isEnabled = isEnabled
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
    
    private lazy var sameHouseholdRiskGroup =
        ToggleGroup(label: .sameHouseholdRiskQuestion,
                    ToggleButton(title: .sameHouseholdRiskQuestionAnswerNegative, selected: risks.sameHousehold == false),
                    ToggleButton(title: .sameHouseholdRiskQuestionAnswerPositive, selected: risks.sameHousehold == true))
        .didSelect { [unowned self] in self.risks.sameHousehold = $0 == 1 }
    
    private lazy var distanceRiskGroup =
        ToggleGroup(label: .distanceRiskQuestion,
                    ToggleButton(title: .distanceRiskQuestionAnswerMoreThan15Min, selected: risks.distance == .yesMoreThan15min),
                    ToggleButton(title: .distanceRiskQuestionAnswerLessThan15Min, selected: risks.distance == .yesLessThan15min),
                    ToggleButton(title: .distanceRiskQuestionAnswerNegative, selected: risks.distance == .no))
        .didSelect { [unowned self] in
            switch $0 {
            case 0:
                self.risks.distance = .yesMoreThan15min
            case 1:
                self.risks.distance = .yesLessThan15min
            default:
                self.risks.distance = .no
            }
        }
    
    private lazy var physicalContactRiskGroupUndecorated =
        ToggleGroup(label: .physicalContactRiskQuestion,
                    ToggleButton(title: .physicalContactRiskQuestionAnswerPositive, selected: risks.physicalContact == true),
                    ToggleButton(title: .physicalContactRiskQuestionAnswerNegative, selected: risks.physicalContact == false))
        .didSelect { [unowned self] in self.risks.physicalContact = $0 == 0 }
    
    private lazy var physicalContactRiskGroup =
        physicalContactRiskGroupUndecorated
            .decorateWithDescriptionIfNeeded(description: .physicalContactRiskQuestionDescription)
    
    private lazy var sameRoomRiskGroup =
        ToggleGroup(label: .sameRoomRiskQuestion,
                    ToggleButton(title: .sameRoomRiskQuestionAnswerPositive, selected: risks.sameRoom == true),
                    ToggleButton(title: .sameRoomRiskQuestionAnswerNegative, selected: risks.sameRoom == false))
        .didSelect { [unowned self] in self.risks.sameRoom = $0 == 0 }
    
    private lazy var otherCategoryView: UIView = {
        let containerView = UIView()
        containerView.backgroundColor = Theme.colors.tertiary
        containerView.layer.cornerRadius = 8
        
        VStack(spacing: 16,
               UILabel(bodyBold: .otherCategoryTitle).multiline(),
               UILabel(body: .otherCategoryMessage, textColor: Theme.colors.captionGray).multiline())
            .embed(in: containerView, insets: .leftRight(16) + .topBottom(24))
        
        return containerView
    }()
    
    private(set) lazy var view: UIView =
        VStack(spacing: 24,
               sameHouseholdRiskGroup,
               distanceRiskGroup,
               physicalContactRiskGroup,
               sameRoomRiskGroup,
               otherCategoryView)
    
    weak var inputFieldDelegate: InputFieldDelegate?
}

/// AnswerManager for the .contactDetails question.
/// Uses [InputField](x-source-tag://InputField) to question the firstName, lastName, email and phoneNumber of the index
class ContactDetailsAnswerManager: AnswerManaging, InputFieldDelegate {
    // swiftlint:disable opening_brace
    private(set) var firstName = FirstName()        { didSet { updateHandler?(self) } }
    private(set) var lastName = LastName()          { didSet { updateHandler?(self) } }
    private(set) var email = EmailAddress()         { didSet { updateHandler?(self) } }
    private(set) var phoneNumber = PhoneNumber()    { didSet { updateHandler?(self) } }
    // swiftlint:enable opening_brace
    
    private var baseAnswer: Answer
    private var didHaveValidPhoneOrEmail: Bool = false
    
    var updateHandler: ((AnswerManaging) -> Void)?
    
    init(question: Question, answer: Answer, contact: CNContact?) {
        self.baseAnswer = answer
        self.question = question
        
        if let contact = contact {
            baseAnswer.value = .contactDetails(contact: contact)
            
            let phoneNumberOptions = contact.contactPhoneNumbers.compactMap(\.value)
            self.phoneNumber.valueOptions = phoneNumberOptions
            self.phoneNumber.placeholder = phoneNumberOptions.isEmpty ? nil : .contactInformationPhoneNumberPlaceholder
            
            let emailOptions = contact.contactEmailAddresses.compactMap(\.value)
            self.email.valueOptions = emailOptions
            self.email.placeholder = emailOptions.isEmpty ? nil : .contactInformationEmailAddressPlaceholder
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
        
        didHaveValidPhoneOrEmail = (email.value ?? phoneNumber.value) != nil
    }
    
    let question: Question
    
    private(set) lazy var firstNameField = InputField(for: self, path: \.firstName).delegate(self)
    private(set) lazy var lastNameField = InputField(for: self, path: \.lastName).delegate(self)
    private(set) lazy var phoneNumberField = InputField(for: self, path: \.phoneNumber).delegate(self)
    private(set) lazy var emailField = InputField(for: self, path: \.email).delegate(self)
    
    private(set) lazy var view: UIView =
        VStack(spacing: 16,
               HStack(spacing: 15,
                      firstNameField,
                      lastNameField).distribution(.fillEqually),
               phoneNumberField,
               emailField)
    
    var answer: Answer {
        var answer = baseAnswer
        answer.value = .contactDetails(firstName: firstName.value,
                                       lastName: lastName.value,
                                       email: email.value,
                                       phoneNumber: phoneNumber.value)
        return answer
    }
    
    var isEnabled: Bool = true {
        didSet {
            firstNameField.isEnabled = isEnabled
            lastNameField.isEnabled = isEnabled
            phoneNumberField.isEnabled = isEnabled
            emailField.isEnabled = isEnabled
        }
    }
    
    var hasValidAnswer: Bool {
        return answer.progressElements.contains(true)
    }
    
    weak var inputFieldDelegate: InputFieldDelegate? {
        didSet {
            firstNameField.updateValidationStateIfNeeded()
            lastNameField.updateValidationStateIfNeeded()
            phoneNumberField.updateValidationStateIfNeeded()
            emailField.updateValidationStateIfNeeded()
        }
    }
    
    func promptOptionsForInputField(_ options: [String], selectOption: @escaping (String?) -> Void) {
        inputFieldDelegate?.promptOptionsForInputField(options, selectOption: selectOption)
    }
    
    func shouldShowValidationResult(_ result: ValidationResult, for sender: AnyObject) -> Bool {
        guard inputFieldDelegate?.shouldShowValidationResult(result, for: sender) == true else { return false }
        
        switch result {
        case .empty:
            if sender === phoneNumberField || sender === emailField {
                // Only allow the empty warning for these if we did not have a value for either one of them
                return !didHaveValidPhoneOrEmail
            } else {
                return true
            }
        default:
            return true
        }
    }
    
}

/// AnswerManager for the .date question.
/// Uses [InputField](x-source-tag://InputField) to display an editable date.
class DateAnswerManager: AnswerManaging {
    private(set) var date: GeneralDate { didSet { updateHandler?(self) } }
    
    private var baseAnswer: Answer
    
    var updateHandler: ((AnswerManaging) -> Void)?
    weak var inputFieldDelegate: InputFieldDelegate?
    
    init(question: Question, answer: Answer) {
        self.baseAnswer = answer
        self.question = question
        
        guard case .date(let date) = baseAnswer.value else {
            fatalError()
        }
            
        self.date = GeneralDate(label: question.label, date: date)
    }
    
    let question: Question
    
    private lazy var inputField = InputField(for: self, path: \.date)
    private(set) lazy var view: UIView = inputField
        .decorateWithDescriptionIfNeeded(description: question.description)
    
    var answer: Answer {
        var answer = baseAnswer
        answer.value = .date(date.dateValue)
        return answer
    }
    
    var isEnabled: Bool = true {
        didSet { inputField.isEnabled = isEnabled }
    }
    
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
    weak var inputFieldDelegate: InputFieldDelegate?
    
    private(set) var options: Options {
        didSet { update() }
    }
    
    init(question: Question, answer: Answer, lastExposureDate: String?) {
        self.baseAnswer = answer
        self.question = question
        
        let endDate = Date()
        let startDate = Services.caseManager.startOfContagiousPeriod ?? endDate
        
        let numberOfDays = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        
        let dateOptions = (0...numberOfDays)
            .compactMap { Calendar.current.date(byAdding: .day, value: $0, to: startDate) }
            .map { AnswerOption(label: Self.displayDateFormatter.string(from: $0),
                                value: Self.valueDateFormatter.string(from: $0)) }
        
        let everyDayOption = AnswerOption(label: .contactInformationLastExposureEveryDay,
                                          value: Self.valueDateFormatter.string(from: endDate))
        
        var answerOptions = [.lastExposureDateEarlierOption] + dateOptions + [everyDayOption]
        
        if let lastExposureDate = lastExposureDate {
            if let option = answerOptions.first(where: { $0.value == lastExposureDate }) {
                baseAnswer.value = .lastExposureDate(option)
            } else if let date = Self.valueDateFormatter.date(from: lastExposureDate) {
                // If we got a different valid date, create an option for it
                let option = AnswerOption(label: Self.displayDateFormatter.string(from: date),
                                          value: lastExposureDate)
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
    
    private let earlierIndicatorView: UIView = {
        let containerView = UIView()
        containerView.backgroundColor = Theme.colors.tertiary
        containerView.layer.cornerRadius = 8
        containerView.isHidden = true
        
        VStack(spacing: 16,
               UILabel(bodyBold: .earlierExposureDateTitle).multiline(),
               UILabel(body: .earlierExposureDateMessage, textColor: Theme.colors.captionGray).multiline())
            .embed(in: containerView, insets: .leftRight(16) + .topBottom(24))
        
        return containerView
    }()
    
    private lazy var inputField = InputField(for: self, path: \.options)
    
    private(set) lazy var view: UIView = {
        VStack(spacing: 8,
               inputField
                .emphasized()
                .decorateWithDescriptionIfNeeded(description: question.description),
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
        formatter.locale = .display
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        return formatter
    }()
    
    static let valueDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
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
    weak var inputFieldDelegate: InputFieldDelegate?
    
    init(question: Question, answer: Answer) {
        self.baseAnswer = answer
        self.question = question
        
        guard case .open(let text) = baseAnswer.value else {
            fatalError()
        }
            
        self.text = Text(label: question.label, value: text)
    }
    
    let question: Question
    
    private lazy var inputTextView = InputTextView(for: self, path: \.text)
    private(set) lazy var view: UIView = inputTextView
        .decorateWithDescriptionIfNeeded(description: question.description)
    
    var answer: Answer {
        var answer = baseAnswer
        answer.value = .open(text.value)
        return answer
    }
    
    var isEnabled: Bool = true {
        didSet { inputTextView.isEnabled = isEnabled }
    }
    
    var hasValidAnswer: Bool {
        return text.value != nil
    }
}

/// AnswerManager for the .multipleChoice question.
/// When dealing with more than 4 options it will use a UIPickerView via [InputField](x-source-tag://InputField). When dealing with up to 4 options it will display the options using a [ToggleGroup](x-source-tag://ToggleGroup)
class MultipleChoiceAnswerManager: AnswerManaging {
    
    private var baseAnswer: Answer
    
    var updateHandler: ((AnswerManaging) -> Void)?
    weak var inputFieldDelegate: InputFieldDelegate?
    
    private var options: Options! { didSet { updateHandler?(self) } }
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
            
            self.buttons = ToggleGroup(label: question.label, answerOptions.map { ToggleButton(title: $0.label, selected: $0.value == option?.value) })
                .didSelect { [unowned self] in
                    selectedButtonIndex = $0
                    updateHandler?(self)
                }
        }
    }
    
    let question: Question
    
    private(set) lazy var inputField = InputField(for: self, path: \.options)
    private(set) lazy var view: UIView = {
        if options != nil {
            return inputField.decorateWithDescriptionIfNeeded(description: question.description)
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
            inputField.isEnabled = isEnabled
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
