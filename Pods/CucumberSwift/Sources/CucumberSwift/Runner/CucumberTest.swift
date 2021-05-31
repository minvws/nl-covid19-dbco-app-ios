//
//  CucumberTestCase.swift
//  CucumberSwift
//
//  Created by Tyler Thompson on 8/25/18.
//  Copyright © 2018 Tyler Thompson. All rights reserved.
//

import Foundation
import XCTest

class CucumberTest: XCTestCase {
    override class var defaultTestSuite: XCTestSuite { // swiftlint:disable:this empty_xctest_method
        (Cucumber.shared as? CucumberTestObservable)?.observers.forEach { $0.testSuiteStarted(at: Date()) }

        let suite = XCTestSuite(forTestCaseClass: CucumberTest.self)

        Reporter.shared.reset()
        Cucumber.shared.features.removeAll()
        if let bundle = (Cucumber.shared as? StepImplementation)?.bundle {
            Cucumber.shared.readFromFeaturesFolder(in: bundle)
        }
        (Cucumber.shared as? StepImplementation)?.setupSteps()
        allGeneratedTests.forEach { suite.addTest($0) }
        return suite
    }

    static var allGeneratedTests: [XCTestCase] {
        var tests = [XCTestCase]()
        createTestCaseForStubs(&tests)
        for feature in Cucumber.shared.features.taggedElements(with: Cucumber.shared.environment, askImplementor: false) {
            let className = feature.title.toClassString() + readFeatureScenarioDelimiter()
            for scenario in feature.scenarios.taggedElements(with: Cucumber.shared.environment, askImplementor: true) {
                createTestCaseFor(className: className, scenario: scenario, tests: &tests)
            }
        }
        return tests
    }

    private static func createTestCaseForStubs(_ tests:inout [XCTestCase]) {
        let generatedSwift = Cucumber.shared.generateUnimplementedStepDefinitions()
        guard !generatedSwift.isEmpty else { return }
        if let (testCaseClass, methodSelector) = TestCaseGenerator.initWith(className: "Generated Steps", method: TestCaseMethod(withName: "GenerateStepsStubsIfNecessary", closure: {
            XCTContext.runActivity(named: "Pending Steps") { activity in
                let attachment = XCTAttachment(uniformTypeIdentifier: "swift",
                                               name: "GENERATED_Unimplemented_Step_Definitions.swift",
                                               payload: generatedSwift.data(using: .utf8),
                                               userInfo: nil)
                attachment.lifetime = .keepAlways
                activity.add(attachment)
            }
        })) {
            objc_registerClassPair(testCaseClass)
            tests.append(testCaseClass.init(selector: methodSelector))
        }
    }

    private static func createTestCaseFor(className: String, scenario: Scenario, tests:inout [XCTestCase]) {
        scenario.steps.compactMap { step -> (step: Step, XCTestCase.Type, Selector)? in
            if let (testCase, methodSelector) = TestCaseGenerator.initWith(className: className.appending(scenario.title.toClassString()),
                                                                           method: step.method) {
                return (step, testCase, methodSelector)
            }
            return nil
        }
        .map { step, testCaseClass, methodSelector -> (Step, XCTestCase) in
            objc_registerClassPair(testCaseClass)
            return (step, testCaseClass.init(selector: methodSelector))
        }
        .forEach { step, testCase in
            testCase.addTeardownBlock {
                (step.executeInstance as? XCTestCase)?.tearDown()
                Cucumber.shared.afterStepHooks.forEach { $0.hook(step) }
                Cucumber.shared.setupAfterHooksFor(step)
                step.endTime = Date()
            }
            step.continueAfterFailure ?= (Cucumber.shared as? StepImplementation)?.continueTestingAfterFailure ?? testCase.continueAfterFailure
            step.testCase = testCase
            testCase.continueAfterFailure = step.continueAfterFailure
            tests.append(testCase)
        }
    }

    // A test case needs at least one test to trigger the observer
    final func testGherkin() {
        XCTAssert(Gherkin.errors.isEmpty, "Gherkin language errors found:\n\(Gherkin.errors.joined(separator: "\n"))")
        Gherkin.errors.forEach {
            XCTFail($0)
        }
    }
}

extension CucumberTest {
    private static let defaultDelimiter = "|"

    private static func readFeatureScenarioDelimiter() -> String {
        guard let testBundle = (Cucumber.shared as? StepImplementation)?.bundle else { return defaultDelimiter }
        return (testBundle.infoDictionary?["FeatureScenarioDelimiter"] as? String) ?? defaultDelimiter
    }
}

extension Step {
    fileprivate var method: TestCaseMethod? {
        TestCaseMethod(withName: "\(keyword.toString()) \(match)".toClassString()) {
            guard !Cucumber.shared.failedScenarios.contains(where: { $0 === self.scenario }) else { return }
            let startTime = Date()
            self.startTime = startTime
            Cucumber.shared.currentStep = self
            Cucumber.shared.setupBeforeHooksFor(self)
            Cucumber.shared.beforeStepHooks.forEach { $0.hook(self) }

            func runAndReport() {
                (Cucumber.shared as? CucumberTestObservable)?.observers.forEach { $0.didStart(step: self, at: startTime) }
                self.run()
                self.endTime = Date()
                Reporter.shared.writeStep(self)
                (Cucumber.shared as? CucumberTestObservable)?.observers.forEach { $0.didFinish(step: self, result: self.result, duration: self.executionDuration) }
            }

            #if compiler(>=5)
            XCTContext.runActivity(named: "\(self.keyword.toString()) \(self.match)") { _ in
                runAndReport()
            }
            #else
            _ = XCTContext.runActivity(named: "\(self.keyword.toString()) \(self.match)") { _ in
                runAndReport()
            }
            #endif
        }
    }

    fileprivate func run() {
        if let `class` = executeClass, let selector = executeSelector {
            executeInstance = (`class` as? NSObject.Type)?.init()
            if let instance = executeInstance,
                instance.responds(to: selector) {
                    (executeInstance as? XCTestCase)?.setUp()
                    instance.perform(selector)
            }
        } else {
            execute?(match.matches(for: regex), self)
        }
        if execute != nil && result != .failed {
            result = .passed
        }
    }
}

extension String {
    fileprivate func toClassString() -> String {
        camelCasingString().capitalizingFirstLetter()
    }
}
