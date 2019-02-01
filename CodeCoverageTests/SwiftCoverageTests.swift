//
//  SwiftCoverageTests.swift
//  CodeCoverageTests
//
//  Created by Derek Selander on 1/27/19.
//  Copyright © 2019 Derek Selander. All rights reserved.
//

import XCTest
@testable import CodeCoverage

class SwiftCoverageTests: XCTestCase {

    func testAssert() {
//        let vc = ViewController()
//        vc.v = nil
//        XCTAssert(vc.v != nil, "ViewController's view shouldn't be nil")
    }
    
    func testAssertEqual() {
        XCTAssertEqual(10, 11, "10 should equal 11")
    }
    
    func testAssertNotEqual() {
        XCTAssertNotEqual(44, 44, "44 should not equal itself")
    }
    
    func testAssertFalse() {
//        let vc = ViewController()
//        vc.v = nil
//        XCTAssertFalse(true, "True should be false")
    }
    
    func testAssertGreaterThan() {
        XCTAssertGreaterThan(0, 0, "0 should be greater than 0")
    }
    
    func testAssertLessThan() {
        XCTAssertLessThan(0, 0, "0 should be less than 0")
    }
    
    func testAssertGreaterThanOrEqual() {
        XCTAssertGreaterThanOrEqual(0, 1, "1 should be greater than 0")
    }
    
    func testAssertLessThanOrEqual() {
        XCTAssertLessThanOrEqual(1, 0, "0 should be greater than 1")
    }
    
    func testAssertNil() {
        XCTAssertNil(UIView(), "Some message where we should be nil here")
    }
    
    func testAssertNotNil() {
        XCTAssertNotNil(nil, "nil should not be nil")
    }
    
    func testAssertTrue() {
        XCTAssertTrue(false, "False should be true")
    }
    
    func testFail() {
        XCTFail("Screw it, let's die")
    }
    
    func testExpectation() {
        let exp = expectation(description: "Expectation should complete")
        self.wait(for: [exp], timeout: 0)
    }

}
