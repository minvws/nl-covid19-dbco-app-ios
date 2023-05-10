/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import XCTest
@testable import GGD_Contact

class ClassificationHelperTests: XCTestCase {
    
    func visibleRisks(sameHousehold: Bool?, distance: Answer.Value.Distance?, physicalContact: Bool?, sameRoom: Bool?) -> [ClassificationHelper.Risk] {
        return ClassificationHelper.visibleRisks(for: .init(sameHousehold: sameHousehold,
                                                            distance: distance,
                                                            physicalContact: physicalContact,
                                                            sameRoom: sameRoom))
    }
    
    func result(sameHousehold: Bool?, distance: Answer.Value.Distance?, physicalContact: Bool?, sameRoom: Bool?) -> ClassificationHelper.Result {
        return ClassificationHelper.classificationResult(for: .init(sameHousehold: sameHousehold,
                                                            distance: distance,
                                                            physicalContact: physicalContact,
                                                            sameRoom: sameRoom))
    }
    
    func testEmptyClassification() throws {
        XCTAssertEqual(result(sameHousehold: nil, distance: nil, physicalContact: nil, sameRoom: nil), .needsAssessmentFor(.sameHousehold))
        XCTAssertEqual(visibleRisks(sameHousehold: nil, distance: nil, physicalContact: nil, sameRoom: nil), [.sameHousehold])
        
        XCTAssertEqual(result(sameHousehold: nil, distance: .no, physicalContact: nil, sameRoom: nil), .needsAssessmentFor(.sameHousehold))
        XCTAssertEqual(visibleRisks(sameHousehold: nil, distance: .no, physicalContact: nil, sameRoom: nil), [.sameHousehold])
        
        XCTAssertEqual(result(sameHousehold: nil, distance: .yesMoreThan15min, physicalContact: nil, sameRoom: nil), .needsAssessmentFor(.sameHousehold))
        XCTAssertEqual(visibleRisks(sameHousehold: nil, distance: .yesMoreThan15min, physicalContact: nil, sameRoom: nil), [.sameHousehold])
        
        XCTAssertEqual(result(sameHousehold: nil, distance: .yesLessThan15min, physicalContact: nil, sameRoom: nil), .needsAssessmentFor(.sameHousehold))
        XCTAssertEqual(visibleRisks(sameHousehold: nil, distance: .yesLessThan15min, physicalContact: nil, sameRoom: nil), [.sameHousehold])
        
        XCTAssertEqual(result(sameHousehold: nil, distance: .yesMoreThan15min, physicalContact: true, sameRoom: nil), .needsAssessmentFor(.sameHousehold))
        XCTAssertEqual(visibleRisks(sameHousehold: nil, distance: .yesMoreThan15min, physicalContact: true, sameRoom: nil), [.sameHousehold])
        
        XCTAssertEqual(result(sameHousehold: nil, distance: .yesMoreThan15min, physicalContact: nil, sameRoom: true), .needsAssessmentFor(.sameHousehold))
        XCTAssertEqual(visibleRisks(sameHousehold: nil, distance: .yesMoreThan15min, physicalContact: nil, sameRoom: true), [.sameHousehold])
    }
    
    func testCategory1Classification() throws {
        XCTAssertEqual(result(sameHousehold: true, distance: nil, physicalContact: nil, sameRoom: nil), .success(.category1))
        XCTAssertEqual(visibleRisks(sameHousehold: true, distance: nil, physicalContact: nil, sameRoom: nil), [.sameHousehold])
        
        XCTAssertEqual(result(sameHousehold: false, distance: nil, physicalContact: nil, sameRoom: nil), .needsAssessmentFor(.distance))
        XCTAssertEqual(visibleRisks(sameHousehold: false, distance: nil, physicalContact: nil, sameRoom: nil), [.sameHousehold, .distance])
        
        XCTAssertEqual(result(sameHousehold: true, distance: nil, physicalContact: true, sameRoom: nil), .success(.category1))
        XCTAssertEqual(visibleRisks(sameHousehold: true, distance: nil, physicalContact: true, sameRoom: nil), [.sameHousehold])
        
        XCTAssertEqual(result(sameHousehold: false, distance: nil, physicalContact: nil, sameRoom: false), .needsAssessmentFor(.distance))
        XCTAssertEqual(visibleRisks(sameHousehold: false, distance: nil, physicalContact: nil, sameRoom: false), [.sameHousehold, .distance])
    }
    
    func testCategory2aClassification() throws {
        XCTAssertEqual(result(sameHousehold: false, distance: nil, physicalContact: nil, sameRoom: nil), .needsAssessmentFor(.distance))
        XCTAssertEqual(visibleRisks(sameHousehold: false, distance: nil, physicalContact: nil, sameRoom: nil), [.sameHousehold, .distance])
        
        XCTAssertEqual(result(sameHousehold: false, distance: .yesMoreThan15min, physicalContact: nil, sameRoom: nil), .success(.category2a))
        XCTAssertEqual(visibleRisks(sameHousehold: false, distance: .yesMoreThan15min, physicalContact: nil, sameRoom: nil), [.sameHousehold, .distance])
        
        XCTAssertEqual(result(sameHousehold: false, distance: .yesLessThan15min, physicalContact: nil, sameRoom: nil), .needsAssessmentFor(.physicalContact))
        XCTAssertEqual(visibleRisks(sameHousehold: false, distance: .yesLessThan15min, physicalContact: nil, sameRoom: nil), [.sameHousehold, .distance, .physicalContact])
    }
    
    func testCategory2bClassification() throws {
        XCTAssertEqual(result(sameHousehold: false, distance: .yesLessThan15min, physicalContact: nil, sameRoom: nil), .needsAssessmentFor(.physicalContact))
        XCTAssertEqual(visibleRisks(sameHousehold: false, distance: .yesLessThan15min, physicalContact: nil, sameRoom: nil), [.sameHousehold, .distance, .physicalContact])
        
        XCTAssertEqual(result(sameHousehold: false, distance: .yesLessThan15min, physicalContact: true, sameRoom: true), .success(.category2b))
        XCTAssertEqual(visibleRisks(sameHousehold: false, distance: .yesLessThan15min, physicalContact: true, sameRoom: true), [.sameHousehold, .distance, .physicalContact])
        
        XCTAssertEqual(result(sameHousehold: false, distance: .yesLessThan15min, physicalContact: true, sameRoom: nil), .success(.category2b))
        XCTAssertEqual(visibleRisks(sameHousehold: false, distance: .yesLessThan15min, physicalContact: true, sameRoom: nil), [.sameHousehold, .distance, .physicalContact])
    }
    
    func testCategory3aClassification() throws {
        XCTAssertEqual(result(sameHousehold: false, distance: .no, physicalContact: nil, sameRoom: false), .success(.other))
        XCTAssertEqual(visibleRisks(sameHousehold: false, distance: .no, physicalContact: nil, sameRoom: false), [.sameHousehold, .distance])
        
        XCTAssertEqual(result(sameHousehold: false, distance: .no, physicalContact: true, sameRoom: false), .success(.other))
        XCTAssertEqual(visibleRisks(sameHousehold: false, distance: .no, physicalContact: true, sameRoom: nil), [.sameHousehold, .distance])
        
        XCTAssertEqual(result(sameHousehold: false, distance: .no, physicalContact: nil, sameRoom: false), .success(.other))
        XCTAssertEqual(visibleRisks(sameHousehold: false, distance: .no, physicalContact: nil, sameRoom: true), [.sameHousehold, .distance])
    }
    
    func testCategory3bClassification() throws {
        XCTAssertEqual(result(sameHousehold: false, distance: .no, physicalContact: nil, sameRoom: false), .success(.other))
        XCTAssertEqual(visibleRisks(sameHousehold: false, distance: .no, physicalContact: nil, sameRoom: false), [.sameHousehold, .distance])
        
        XCTAssertEqual(result(sameHousehold: false, distance: .no, physicalContact: true, sameRoom: false), .success(.other))
        XCTAssertEqual(visibleRisks(sameHousehold: false, distance: .no, physicalContact: true, sameRoom: nil), [.sameHousehold, .distance])
        
        XCTAssertEqual(result(sameHousehold: false, distance: .no, physicalContact: nil, sameRoom: false), .success(.other))
        XCTAssertEqual(visibleRisks(sameHousehold: false, distance: .no, physicalContact: nil, sameRoom: true), [.sameHousehold, .distance])
    }
    
    func testOtherClassification() throws {
        XCTAssertEqual(result(sameHousehold: false, distance: .no, physicalContact: nil, sameRoom: false), .success(.other))
        XCTAssertEqual(visibleRisks(sameHousehold: false, distance: .no, physicalContact: nil, sameRoom: false), [.sameHousehold, .distance])
        
        XCTAssertEqual(result(sameHousehold: false, distance: .no, physicalContact: true, sameRoom: false), .success(.other))
        XCTAssertEqual(visibleRisks(sameHousehold: false, distance: .no, physicalContact: true, sameRoom: nil), [.sameHousehold, .distance])
        
        XCTAssertEqual(result(sameHousehold: false, distance: .no, physicalContact: nil, sameRoom: false), .success(.other))
        XCTAssertEqual(visibleRisks(sameHousehold: false, distance: .no, physicalContact: nil, sameRoom: true), [.sameHousehold, .distance])
    }
    
    func testSetCategory1Risks() throws {
        var risks: ClassificationHelper.Risks = .init()
        ClassificationHelper.setRisks(for: .category1, risks: &risks)
        XCTAssertEqual(risks, .init(sameHousehold: true, distance: nil, physicalContact: nil, sameRoom: nil))
    }
        
    func testSetCategory2aRisks() throws {
        var risks: ClassificationHelper.Risks = .init()
        ClassificationHelper.setRisks(for: .category2a, risks: &risks)
        XCTAssertEqual(risks, .init(sameHousehold: false, distance: .yesMoreThan15min, physicalContact: nil, sameRoom: nil))
    }
        
    func testSetCategory2bRisks() throws {
        var risks: ClassificationHelper.Risks = .init()
        ClassificationHelper.setRisks(for: .category2b, risks: &risks)
        XCTAssertEqual(risks, .init(sameHousehold: false, distance: .yesLessThan15min, physicalContact: true, sameRoom: nil))
    }
    
    func testSetCategory3aRisks() throws {
        var risks: ClassificationHelper.Risks = .init()
        ClassificationHelper.setRisks(for: .category3a, risks: &risks)
        XCTAssertEqual(risks, .init(sameHousehold: false, distance: .no, physicalContact: nil, sameRoom: false))
    }
    
    func testSetCategory3bRisks() throws {
        var risks: ClassificationHelper.Risks = .init()
        ClassificationHelper.setRisks(for: .category3b, risks: &risks)
        XCTAssertEqual(risks, .init(sameHousehold: false, distance: .no, physicalContact: nil, sameRoom: false))
    }
    
    func testSetOtherRisks() throws {
        var risks: ClassificationHelper.Risks = .init()
        ClassificationHelper.setRisks(for: .other, risks: &risks)
        XCTAssertEqual(risks, .init(sameHousehold: false, distance: .no, physicalContact: nil, sameRoom: false))
    }
    
    func testResultCategories() throws {
        XCTAssertEqual(result(sameHousehold: true, distance: nil, physicalContact: nil, sameRoom: nil).category, .category1)
        XCTAssertEqual(result(sameHousehold: false, distance: .yesMoreThan15min, physicalContact: nil, sameRoom: nil).category, .category2a)
        XCTAssertEqual(result(sameHousehold: false, distance: .yesLessThan15min, physicalContact: true, sameRoom: nil).category, .category2b)
        XCTAssertEqual(result(sameHousehold: false, distance: .yesLessThan15min, physicalContact: false, sameRoom: nil).category, .other)
        XCTAssertEqual(result(sameHousehold: false, distance: .no, physicalContact: false, sameRoom: true).category, .other)
        XCTAssertEqual(result(sameHousehold: false, distance: .no, physicalContact: nil, sameRoom: false).category, .other)
        
        XCTAssertEqual(result(sameHousehold: nil, distance: nil, physicalContact: nil, sameRoom: nil).category, nil)
    }

}
