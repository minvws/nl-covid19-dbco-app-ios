/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import XCTest
import CucumberSwift

private var app: XCUIApplication!

func wait(forCondition condition: @escaping () -> Bool, timeout: TimeInterval = 10) {
//    XCTAssertTrue(WaitForConditionWithTimeout(timeout, condition))
}

extension XCUIElement {
    var visible: Bool {
        return (exists || waitForExistence(timeout: 1)) && isHittable
    }
}

extension Cucumber: StepImplementation {
    public var bundle: Bundle {
        class ThisBundle { }
        return Bundle(for: ThisBundle.self)
    }
    public var continueTestingAfterFailure: Bool {
        return false
    }
    
    func ThenAnd(_ regex: String, callback: @escaping ([String], Step) -> Void) {
        Then(regex, callback: callback)
        And(regex, callback: callback)
    }
    
    func GivenAnd(_ regex: String, callback: @escaping ([String], Step) -> Void) {
        Given(regex, callback: callback)
        And(regex, callback: callback)
    }
    
    func WhenAnd(_ regex: String, callback: @escaping ([String], Step) -> Void) {
        When(regex, callback: callback)
        And(regex, callback: callback)
    }

    public func setupSteps() {
        Given("the app launched") { _, _ in
            app = XCUIApplication()
            app.launchArguments += ["UI-Testing"]
            app.launch()
        }
        
        ThenAnd("I see a button with '(.*)'") { matches, _ in
            let text = matches[1]
            let button = app.buttons[text].firstMatch
            XCTAssertTrue(button.visible)
        }
        
        ThenAnd("I see a swich with '(.*)'") { matches, _ in
            let text = matches[1]
            let button = app.switches[text].firstMatch
            XCTAssertTrue(button.visible)
        }
        
        ThenAnd("I see a button with '(.*)' or '(.*)'") { matches, _ in
            let button1 = matches[1]
            let button2 = matches[2]
            let firstButton = app.buttons[button1].firstMatch
            let alternativeButton = app.buttons[button2].firstMatch
            
            XCTAssertTrue(firstButton.visible || alternativeButton.visible)
        }
        
        ThenAnd("I see a disabled button with '(.*)'") { matches, _ in
            let text = matches[1]
            let button = app.buttons[text].firstMatch
            XCTAssertTrue(button.visible)
            XCTAssertFalse(button.isEnabled)
        }
        
        ThenAnd("the '(.*)' button becomes enabled$") { matches, _ in
            let text = matches[1]
            let button = app.buttons[text].firstMatch
            XCTAssertTrue(button.visible)
            XCTAssertTrue(button.isEnabled)
        }

        ThenAnd("I see a label with '(.*)'") { matches, _ in
            let text = matches[1]
            let label = app.staticTexts[text].firstMatch
            XCTAssertTrue(label.visible)
        }
        
        ThenAnd("I see a text field with '(.*)'") { matches, _ in
            let text = matches[1]
            let textField = app.textFields.matching(.init(format: "placeholderValue == %@", text)).firstMatch
            XCTAssertTrue(textField.visible)
        }
        
        WhenAnd("I tap (?:the )?(?:first )?'(.*)' button$") { matches, _ in
            let text = matches[1]
            let button = app.buttons[text].firstMatch
            button.tap()
        }
        
        WhenAnd("I tap (?:the )?(?:first )?'(.*)' switch$") { matches, _ in
            let text = matches[1]
            let button = app.switches[text].firstMatch
            button.tap()
        }
        
        WhenAnd("I tap (?:the )?(?:first )?'(.*)' or (?:the )?(?:first )?'(.*)' button$") { matches, _ in
            let button1 = matches[1]
            let button2 = matches[2]
            let firstButton = app.buttons[button1].firstMatch
            let alternativeButton = app.buttons[button2].firstMatch
            
            if firstButton.exists {
                firstButton.tap()
            } else {
                alternativeButton.tap()
            }
        }
        
        WhenAnd("I type '(.*)' into the '(.*)' text field$") { matches, _ in
            let text = matches[1]
            let name = matches[2]
            let textField = app.textFields.matching(.init(format: "placeholderValue == %@", name)).firstMatch
            
            textField.tap()
            textField.typeText(text)
        }
        
        WhenAnd("I swipe down$") { matches, _ in
            app.swipeDown()
        }
        
        WhenAnd("I swipe up$") { matches, _ in
            app.swipeUp()
        }
    }
}
