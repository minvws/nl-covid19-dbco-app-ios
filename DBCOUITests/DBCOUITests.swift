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

extension Cucumber: StepImplementation {
    public var bundle: Bundle {
        class ThisBundle { }
        return Bundle(for: ThisBundle.self)
    }

    public func setupSteps() {
        BeforeFeature { _ in
            app = XCUIApplication()
            app.launch()
        }
        
        Then("I see a button saying '(.*)'") { matches, _ in
            let text = matches[1]
            let button = app.buttons[text]
            XCTAssertTrue(button.exists)
        }
        
        When("I tap (?:the )?(?:first )?'(.*)' button$") { matches, _ in
            let text = matches[1]
            let button = app.buttons[text].firstMatch
            button.tap()
        }
    }
}
