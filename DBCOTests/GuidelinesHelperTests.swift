/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import XCTest
@testable import GGD_Contact

class GuidelinesHelperTests: XCTestCase {
    
    func testExposureDateParsing() {
        let text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Duis tempor, nunc vitae viverra volutpat, dolor arcu feugiat arcu, ut commodo lectus nibh sit amet mi. Aenean arcu magna, pellentesque et nisl eu, convallis suscipit velit. Quisque condimentum, ipsum vel ultrices {ExposureDate+2} porttitor, turpis metus sagittis sapien, ac feugiat tellus dui imperdiet ipsum. Etiam blandit orci urna. Aenean id velit tellus. {ExposureDate} Maecenas ac nibh eget velit finibus ultricies nec id nulla. Sed non lorem tristique, fermentum nulla ut, imperdiet sapien. Ut pulvinar eu nunc vitae dictum.\n{ExposureDate+0}\nUt faucibus hendrerit tellus quis efficitur. Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae; Proin fringilla, eros id sodales sagittis, lorem dui dignissim erat, eget semper nunc {ExposureDate+20} tellus sit amet dolor. Curabitur tincidunt quam quis ante molestie, non sagittis erat ultricies. Praesent consectetur mauris vitae est varius, ut mollis leo convallis. Mauris vehicula urna porta, aliquet nisl et, aliquet nisi. Proin congue urna a nunc laoreet sollicitudin. Nunc {ExposureDate+35} facilisis sed lacus nec egestas. Cras feugiat quis tortor et euismod. Suspendisse potenti."
        
        let expextedText = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Duis tempor, nunc vitae viverra volutpat, dolor arcu feugiat arcu, ut commodo lectus nibh sit amet mi. Aenean arcu magna, pellentesque et nisl eu, convallis suscipit velit. Quisque condimentum, ipsum vel ultrices woensdag 19 mei porttitor, turpis metus sagittis sapien, ac feugiat tellus dui imperdiet ipsum. Etiam blandit orci urna. Aenean id velit tellus. maandag 17 mei Maecenas ac nibh eget velit finibus ultricies nec id nulla. Sed non lorem tristique, fermentum nulla ut, imperdiet sapien. Ut pulvinar eu nunc vitae dictum.\nmaandag 17 mei\nUt faucibus hendrerit tellus quis efficitur. Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae; Proin fringilla, eros id sodales sagittis, lorem dui dignissim erat, eget semper nunc zondag 6 juni tellus sit amet dolor. Curabitur tincidunt quam quis ante molestie, non sagittis erat ultricies. Praesent consectetur mauris vitae est varius, ut mollis leo convallis. Mauris vehicula urna porta, aliquet nisl et, aliquet nisi. Proin congue urna a nunc laoreet sollicitudin. Nunc maandag 21 juni facilisis sed lacus nec egestas. Cras feugiat quis tortor et euismod. Suspendisse potenti."
        
        let parsedText = GuidelinesHelper.parseGuidelines(text, exposureDate: Date(timeIntervalSinceReferenceDate: 642937745), referenceNumber: nil, referenceNumberItem: nil)
        
        XCTAssertEqual(parsedText, expextedText)
    }
    
    func testReferenceNumberParsing() {
        let text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Duis {ReferenceNumber} tempor, nunc vitae viverra volutpat, dolor arcu feugiat arcu, ut commodo lectus nibh sit amet mi. Aenean arcu magna, pellentesque et nisl eu, convallis suscipit velit. {ReferenceNumber} Quisque condimentum, ipsum vel ultrices porttitor, turpis metus sagittis sapien, ac feugiat tellus dui imperdiet ipsum. Etiam blandit orci urna. Aenean id velit tellus. Maecenas ac nibh eget velit finibus ultricies nec id nulla. Sed non lorem tristique, fermentum nulla ut, imperdiet sapien. Ut pulvinar eu nunc vitae {ReferenceNumber} dictum."
        
        let expextedText = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Duis 58493827 tempor, nunc vitae viverra volutpat, dolor arcu feugiat arcu, ut commodo lectus nibh sit amet mi. Aenean arcu magna, pellentesque et nisl eu, convallis suscipit velit. 58493827 Quisque condimentum, ipsum vel ultrices porttitor, turpis metus sagittis sapien, ac feugiat tellus dui imperdiet ipsum. Etiam blandit orci urna. Aenean id velit tellus. Maecenas ac nibh eget velit finibus ultricies nec id nulla. Sed non lorem tristique, fermentum nulla ut, imperdiet sapien. Ut pulvinar eu nunc vitae 58493827 dictum."
        
        let parsedText = GuidelinesHelper.parseGuidelines(text, exposureDate: nil, referenceNumber: "58493827", referenceNumberItem: nil)
        
        XCTAssertEqual(parsedText, expextedText)
    }
    
    func testReferenceNumberItemParsing() {
        let item = "Nulla volutpat ultrices felis, vel posuere purus sagittis id. Nulla ut leo ac orci placerat semper. Praesent sit amet dapibus ipsum. Integer ullamcorper neque nunc, vitae dictum nisi auctor at. Donec vitae leo commodo, imperdiet quam sed, vestibulum metus. Suspendisse potenti. Duis semper turpis eu sodales ultricies. Phasellus a nisi semper augue bibendum ultrices. Mauris risus tellus, facilisis ac diam ac, efficitur aliquet ex. In consectetur massa est, non aliquet magna sodales ac. Nulla et est mollis, tincidunt tortor eu, auctor nisl. Nullam mollis mi justo. Proin in massa pulvinar, dignissim tellus eget, faucibus libero. Mauris non est eget ligula scelerisque congue id et enim. Phasellus eleifend congue semper. Lorem ipsum dolor sit amet, consectetur adipiscing elit."
        let text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Duis tempor, nunc vitae viverra volutpat, dolor arcu feugiat arcu, ut commodo lectus nibh sit amet mi. Aenean arcu magna, pellentesque et nisl eu, convallis suscipit velit. Quisque condimentum, ipsum vel ultrices porttitor, turpis metus sagittis sapien, ac feugiat tellus dui imperdiet ipsum. Etiam blandit orci urna. Aenean id velit tellus. Maecenas ac nibh eget velit finibus ultricies nec id nulla. Sed non lorem tristique, fermentum nulla ut, imperdiet sapien. Ut pulvinar eu nunc vitae dictum.\n{ReferenceNumberItem}"
        
        let expextedText = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Duis tempor, nunc vitae viverra volutpat, dolor arcu feugiat arcu, ut commodo lectus nibh sit amet mi. Aenean arcu magna, pellentesque et nisl eu, convallis suscipit velit. Quisque condimentum, ipsum vel ultrices porttitor, turpis metus sagittis sapien, ac feugiat tellus dui imperdiet ipsum. Etiam blandit orci urna. Aenean id velit tellus. Maecenas ac nibh eget velit finibus ultricies nec id nulla. Sed non lorem tristique, fermentum nulla ut, imperdiet sapien. Ut pulvinar eu nunc vitae dictum.\nNulla volutpat ultrices felis, vel posuere purus sagittis id. Nulla ut leo ac orci placerat semper. Praesent sit amet dapibus ipsum. Integer ullamcorper neque nunc, vitae dictum nisi auctor at. Donec vitae leo commodo, imperdiet quam sed, vestibulum metus. Suspendisse potenti. Duis semper turpis eu sodales ultricies. Phasellus a nisi semper augue bibendum ultrices. Mauris risus tellus, facilisis ac diam ac, efficitur aliquet ex. In consectetur massa est, non aliquet magna sodales ac. Nulla et est mollis, tincidunt tortor eu, auctor nisl. Nullam mollis mi justo. Proin in massa pulvinar, dignissim tellus eget, faucibus libero. Mauris non est eget ligula scelerisque congue id et enim. Phasellus eleifend congue semper. Lorem ipsum dolor sit amet, consectetur adipiscing elit."
        
        let parsedText = GuidelinesHelper.parseGuidelines(text, exposureDate: nil, referenceNumber: nil, referenceNumberItem: item)
        
        XCTAssertEqual(parsedText, expextedText)
    }
    
    func testMixedParsing() {
        let exposureDate = Date(timeIntervalSinceReferenceDate: 642937745)
        let referenceNumber = "4583749"
        
        let referenceNumberItem = "Nulla volutpat ultrices felis, vel posuere purus sagittis id. Nulla ut leo ac orci placerat semper. Praesent sit amet dapibus ipsum. Integer ullamcorper neque nunc, vitae dictum nisi auctor at. Donec vitae leo commodo, imperdiet quam sed, vestibulum metus. Suspendisse potenti. Duis semper turpis eu sodales ultricies. Phasellus a nisi {ExposureDate} semper augue bibendum ultrices. Mauris risus tellus, facilisis ac diam ac, efficitur aliquet ex. In consectetur massa est, non aliquet magna sodales ac. Nulla et est mollis, tincidunt {ExposureDate+2} tortor eu, auctor nisl. Nullam mollis mi justo. Proin in massa pulvinar, dignissim tellus eget, faucibus libero. Mauris non est eget ligula scelerisque congue id et enim. Phasellus eleifend congue semper. Lorem ipsum dolor sit amet, consectetur adipiscing elit. {ReferenceNumber}"
        
        let text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Duis tempor, nunc vitae viverra volutpat, dolor arcu feugiat {ExposureDate} arcu, ut commodo lectus nibh sit amet mi. Aenean arcu magna, pellentesque et nisl eu, convallis suscipit velit. {ExposureDate+2} Quisque condimentum, ipsum vel ultrices porttitor, turpis metus sagittis sapien, ac feugiat tellus dui imperdiet ipsum. Etiam blandit orci urna. Aenean id velit tellus. Maecenas ac nibh eget velit finibus ultricies nec id nulla. Sed non lorem tristique, fermentum nulla ut, imperdiet sapien. Ut pulvinar eu nunc vitae dictum.\n{ReferenceNumberItem}"
        
        print(Date.now.timeIntervalSinceReferenceDate)
        let parsedReferenceNumberItem = GuidelinesHelper.parseGuidelines(referenceNumberItem, exposureDate: exposureDate, referenceNumber: referenceNumber, referenceNumberItem: "")
        
        let parsedText = GuidelinesHelper.parseGuidelines(text, exposureDate: exposureDate, referenceNumber: referenceNumber, referenceNumberItem: parsedReferenceNumberItem)
        
        let expectedText = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Duis tempor, nunc vitae viverra volutpat, dolor arcu feugiat maandag 17 mei arcu, ut commodo lectus nibh sit amet mi. Aenean arcu magna, pellentesque et nisl eu, convallis suscipit velit. woensdag 19 mei Quisque condimentum, ipsum vel ultrices porttitor, turpis metus sagittis sapien, ac feugiat tellus dui imperdiet ipsum. Etiam blandit orci urna. Aenean id velit tellus. Maecenas ac nibh eget velit finibus ultricies nec id nulla. Sed non lorem tristique, fermentum nulla ut, imperdiet sapien. Ut pulvinar eu nunc vitae dictum.\nNulla volutpat ultrices felis, vel posuere purus sagittis id. Nulla ut leo ac orci placerat semper. Praesent sit amet dapibus ipsum. Integer ullamcorper neque nunc, vitae dictum nisi auctor at. Donec vitae leo commodo, imperdiet quam sed, vestibulum metus. Suspendisse potenti. Duis semper turpis eu sodales ultricies. Phasellus a nisi maandag 17 mei semper augue bibendum ultrices. Mauris risus tellus, facilisis ac diam ac, efficitur aliquet ex. In consectetur massa est, non aliquet magna sodales ac. Nulla et est mollis, tincidunt woensdag 19 mei tortor eu, auctor nisl. Nullam mollis mi justo. Proin in massa pulvinar, dignissim tellus eget, faucibus libero. Mauris non est eget ligula scelerisque congue id et enim. Phasellus eleifend congue semper. Lorem ipsum dolor sit amet, consectetur adipiscing elit. 4583749"
        
        XCTAssertEqual(parsedText, expectedText)
    }

}
