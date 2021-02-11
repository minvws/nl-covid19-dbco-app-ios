/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import XCTest
import Contacts
@testable import GGD_Contact

class ContactQuestionnaireCommunicationTests: XCTestCase {
    
    let communicationQuestion = Question(uuid: UUID(),
                                         group: .contactDetails,
                                         questionType: .multipleChoice,
                                         label: "",
                                         description: nil,
                                         relevantForCategories: [.category1, .category2a, .category2b, .category3a, .category3b],
                                         answerOptions: [
                                            AnswerOption(label: "Ja", value: "Ja", trigger: .setCommunicationToStaff),
                                            AnswerOption(label: "Nee", value: "Nee", trigger: .setCommunicationToIndex)],
                                         disabledForSources: [])
    
    func viewModelFor(taskSource: Task.Source, initialCommunication: Task.Contact.Communication, selectedOptionIndex: Int) -> ContactQuestionnaireViewModel {
        
        var portalTask = Task(type: .contact, source: taskSource)
        portalTask.contact = Task.Contact(category: .category1,
                                          communication: initialCommunication,
                                          didInform: false,
                                          dateOfLastExposure: nil)
        let questionnaire = Questionnaire(uuid: UUID(), taskType: .contact, questions: [communicationQuestion])
        let viewModel = ContactQuestionnaireViewModel(task: portalTask, questionnaire: questionnaire)
        
        (viewModel.answerManagers.first as? MultipleChoiceAnswerManager)?.applyOption(at: selectedOptionIndex)
        
        return viewModel
    }

    func testPortalTaskStaffToIndex() {
        let viewModel = viewModelFor(taskSource: .portal, initialCommunication: .staff, selectedOptionIndex: 1)
        
        XCTAssertEqual(viewModel.updatedTask.contact.communication, .staff, "Should remain staff")
    }
    
    func testPortalTaskStaffToStaff() {
        let viewModel = viewModelFor(taskSource: .portal, initialCommunication: .staff, selectedOptionIndex: 0)
        
        XCTAssertEqual(viewModel.updatedTask.contact.communication, .staff, "Should remain staff")
    }
    
    func testPortalTaskIndexToStaff() {
        let viewModel = viewModelFor(taskSource: .portal, initialCommunication: .index, selectedOptionIndex: 0)
        
        XCTAssertEqual(viewModel.updatedTask.contact.communication, .staff, "Should change to staff")
    }
    
    func testPortalTaskIndexToIndex() {
        let viewModel = viewModelFor(taskSource: .portal, initialCommunication: .index, selectedOptionIndex: 1)
        
        XCTAssertEqual(viewModel.updatedTask.contact.communication, .index, "Should remain index")
    }

    func testAppTaskStaffToIndex() {
        let viewModel = viewModelFor(taskSource: .app, initialCommunication: .staff, selectedOptionIndex: 1)
        
        XCTAssertEqual(viewModel.updatedTask.contact.communication, .index, "Any change should be possible")
    }
    
    func testAppTaskStaffToStaff() {
        let viewModel = viewModelFor(taskSource: .app, initialCommunication: .staff, selectedOptionIndex: 0)
        
        XCTAssertEqual(viewModel.updatedTask.contact.communication, .staff, "Any change should be possible")
    }
    
    func testAppTaskIndexToStaff() {
        let viewModel = viewModelFor(taskSource: .app, initialCommunication: .index, selectedOptionIndex: 0)
        
        XCTAssertEqual(viewModel.updatedTask.contact.communication, .staff, "Any change should be possible")
    }
    
    func testAppTaskIndexToIndex() {
        let viewModel = viewModelFor(taskSource: .app, initialCommunication: .index, selectedOptionIndex: 1)
        
        XCTAssertEqual(viewModel.updatedTask.contact.communication, .index, "Any change should be possible")
    }

}
