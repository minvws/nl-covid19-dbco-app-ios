/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import XCTest
@testable import GGD_Contact

class TaskSortingTests: XCTestCase {

    func testRoommatesOnTop() {
        let tasks = [
            createContactTask(category: .category1, label: "AA"),
            createContactTask(category: .category1, label: "BB"),
            createContactTask(category: .category2b, label: "CC"),
            createContactTask(category: .category2a, label: "DD"),
            createContactTask(category: .category3a, label: "EE"),
            createContactTask(category: .category3b, label: "FF"),
            createContactTask(category: .category1, label: "GG")
        ]
        
        let sortedTasks = tasks.sorted()
        let labels = sortedTasks.compactMap(\.label)
        
        XCTAssertEqual(labels, ["AA", "BB", "GG", "CC", "DD", "EE", "FF"])
    }
    
    func testSortedByLastExposure() {
        let tasks = [
            createContactTask(category: .category2a, label: "AA", dateOfLastExposure: Date.now.dateByAddingDays(-3)),
            createContactTask(category: .category2a, label: "BB", dateOfLastExposure: Date.now.dateByAddingDays(-6)),
            createContactTask(category: .category2a, label: "CC", dateOfLastExposure: Date.now.dateByAddingDays(-1)),
            createContactTask(category: .category2a, label: "DD", dateOfLastExposure: Date.now.dateByAddingDays(-7)),
            createContactTask(category: .category2a, label: "EE"),
            createContactTask(category: .category2a, label: "FF", dateOfLastExposure: Date.now.dateByAddingDays(-4)),
            createContactTask(category: .category2a, label: "GG", dateOfLastExposure: Date.now.dateByAddingDays(-5))
        ]
        
        let sortedTasks = tasks.sorted()
        let labels = sortedTasks.compactMap(\.label)
        
        XCTAssertEqual(labels, ["EE", "CC", "AA", "FF", "GG", "BB", "DD"])
    }
    
    func testSortedAlphabetically() {
        let tasks = [
            createContactTask(category: .category2a, label: "Daniel Higgins"),
            createContactTask(category: .category2a, label: "Anna Haro"),
            createContactTask(category: .category2a, label: "Hank Zakroff"),
            createContactTask(category: .category2a, label: "John Appleseed"),
            createContactTask(category: .category2a, label: "Kate Bell"),
            createContactTask(category: .category2a, label: "David Taylor"),
            createContactTask(category: .category2a, label: "David"),
            createContactTask(category: .category2a, label: "Thom")
        ]
        
        let sortedTasks = tasks.sorted()
        let labels = sortedTasks.compactMap(\.label)
        
        XCTAssertEqual(labels, ["Anna Haro", "Daniel Higgins", "David", "David Taylor", "Hank Zakroff", "John Appleseed", "Kate Bell", "Thom"])
    }
    
    func testMixedSorting() {
        let tasks = [
            createContactTask(category: .category2a, label: "Daniel Higgins"),
            createContactTask(category: .category1, label: "Daniel Higgins"),
            createContactTask(category: .category2a, label: "Anna Haro"),
            createContactTask(category: .category1, label: "Anna Haro", dateOfLastExposure: Date.now.dateByAddingDays(-5)),
            createContactTask(category: .category2a, label: "Hank Zakroff"),
            createContactTask(category: .category1, label: "Hank Zakroff"),
            createContactTask(category: .category2a, label: "John Appleseed"),
            createContactTask(category: .category1, label: "John Appleseed"),
            createContactTask(category: .category2a, label: "Kate Bell", dateOfLastExposure: .now.dateByAddingDays(-3)),
            createContactTask(category: .category2a, label: "Ivo Bell", dateOfLastExposure: Date.now.dateByAddingDays(-5)),
            createContactTask(category: .category1, label: "Kate Bell"),
            createContactTask(category: .category2a, label: "David Taylor"),
            createContactTask(category: .category1, label: "David Taylor"),
            createContactTask(category: .category2a, label: "David"),
            createContactTask(category: .category1, label: "David"),
            createContactTask(category: .category1, label: "Thom"),
            createContactTask(category: .category2a, label: "Thom")
        ]
        
        let sortedTasks = tasks.sorted()
        let category1Tasks = sortedTasks.filter { $0.contact.category == .category1 }
        let otherTasks = sortedTasks.filter { $0.contact.category != .category1 }
        
        XCTAssertTrue(sortedTasks.prefix(category1Tasks.count).allSatisfy { $0.contact.category == .category1 })
        XCTAssertTrue(sortedTasks.suffix(otherTasks.count).allSatisfy { $0.contact.category != .category1 })
        
        let category1Labels = category1Tasks.compactMap(\.label)
        let otherLabels = otherTasks.compactMap(\.label)
        
        XCTAssertEqual(category1Labels, ["Daniel Higgins", "David", "David Taylor", "Hank Zakroff", "John Appleseed", "Kate Bell", "Thom", "Anna Haro"])
        XCTAssertEqual(otherLabels, ["Anna Haro", "Daniel Higgins", "David", "David Taylor", "Hank Zakroff", "John Appleseed", "Thom", "Kate Bell", "Ivo Bell"])
    }

}

private let lastExposureDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar.current
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy-MM-dd"
    
    return formatter
}()

private func createContactTask(category: Task.Contact.Category, label: String, dateOfLastExposure: Date? = .now) -> Task {
    let exposureDateString = dateOfLastExposure.map(lastExposureDateFormatter.string)
    var task = Task(type: .contact, label: label, source: .app)
    task.contact = .init(category: category, communication: .staff, informedByIndexAt: nil, dateOfLastExposure: exposureDateString)
    return task
}
