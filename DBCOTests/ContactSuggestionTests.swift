/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import XCTest
import Contacts
@testable import GGD_Contact

class ContactSuggestionTests: XCTestCase {
    
    let contacts = [
        "Kate Bell",
        "Daniel Higgins Jr.",
        "John Appleseed",
        "Anna Haro",
        "Anna Appleseed",
        "David",
        "David Taylor",
        "Hank M. Zakroff",
        "Thom",
        "Aziz",
        "Mom"
    ]
    
    func suggestions(for name: String) -> [String] {
        ContactSuggestionHelper.suggestions(for: name, in: contacts)
    }
    
    func testInitials() throws {
        XCTAssertEqual(suggestions(for: "K. B."), ["Kate Bell"])
        XCTAssertEqual(suggestions(for: "k. B."), ["Kate Bell"])
        XCTAssertEqual(suggestions(for: "K B"), ["Kate Bell"])
        XCTAssertEqual(suggestions(for: "K. B"), ["Kate Bell"])
        XCTAssertEqual(suggestions(for: "KB"), [])
        
        XCTAssertEqual(suggestions(for: "A"), [])
        XCTAssertEqual(suggestions(for: "A H"), ["Anna Haro"])
        XCTAssertEqual(suggestions(for: "H A"), ["Anna Haro"])
        XCTAssertEqual(suggestions(for: "H. A."), ["Anna Haro"])
        
        XCTAssertEqual(suggestions(for: "t."), [])
    }
    
    func testSingleNamePart() throws {
        XCTAssertEqual(suggestions(for: "John"), ["John Appleseed"])
        XCTAssertEqual(suggestions(for: "David"), ["David", "David Taylor"])
        XCTAssertEqual(suggestions(for: "tho"), ["Thom"])
        XCTAssertEqual(suggestions(for: "thom"), ["Thom"])
        XCTAssertEqual(suggestions(for: "Higgins"), ["Daniel Higgins Jr."])
        XCTAssertEqual(suggestions(for: "Appleseed"), ["John Appleseed", "Anna Appleseed"])
        XCTAssertEqual(suggestions(for: "Anna"), ["Anna Haro", "Anna Appleseed"])
    }
    
    func testFullName() throws {
        XCTAssertEqual(suggestions(for: "Aziz F."), ["Aziz"])
        XCTAssertEqual(suggestions(for: "Aziz Firat"), ["Aziz"])
        XCTAssertEqual(suggestions(for: "Kate Bell"), ["Kate Bell"])
        XCTAssertEqual(suggestions(for: "Anna Haro"), ["Anna Haro"])
        XCTAssertEqual(suggestions(for: "John Appleseed"), ["John Appleseed"])
        XCTAssertEqual(suggestions(for: "J. Appleseed"), ["John Appleseed"])
        XCTAssertEqual(suggestions(for: "John A"), ["John Appleseed"])
        XCTAssertEqual(suggestions(for: "Appleseed, J"), ["John Appleseed"])
        XCTAssertEqual(suggestions(for: "Jon Appleseed"), ["John Appleseed", "Anna Appleseed"])
    }

}

extension String: NameRepresentable {
    
    public var fullName: String {
        return self
    }
    
}
