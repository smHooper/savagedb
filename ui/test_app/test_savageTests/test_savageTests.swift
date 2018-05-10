//
//  test_savageTests.swift
//  test_savageTests
//
//  Created by Sam Hooper on 5/5/18.
//  Copyright © 2018 Sam Hooper. All rights reserved.
//

import XCTest
@testable import test_savage

class test_savageTests: XCTestCase {
    
    //MARK: Observation class test
    func testObservationInitializationSucceeds(){
        
        // Zero rating
        let zeroRatingObservaton = Observation.init(name: "Zero", image: nil, rating: 0)
        XCTAssertNotNil(zeroRatingObservaton)
        
        //Highest postive rating
        let positiveRatingObservaton = Observation.init(name: "Zero", image: nil, rating: 5)
        XCTAssertNotNil(positiveRatingObservaton)
    }
    
    // Test class initialization
    func testObservationInitializationFails(){
        
        // Negative rating
        let negativeRatingMeal = Observation.init(name: "Negative", image: nil, rating: -1)
        XCTAssertNil(negativeRatingMeal)
        
        // Empty String
        let emptyStringMeal = Observation.init(name: "", image: nil, rating: 0)
        XCTAssertNil(emptyStringMeal)
        
    }
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    

    
}
