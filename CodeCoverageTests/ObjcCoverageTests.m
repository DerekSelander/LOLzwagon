//
//  ObjcCoverageTests.m
//  CodeCoverageTests
//
//  Created by Derek Selander on 1/27/19.
//  Copyright © 2019 Derek Selander. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface ObjcCoverageTests : XCTestCase
@end

@implementation ObjcCoverageTests

- (void)testAssertNil {
    XCTAssertNil([UIViewController new], @"UIViewController should be nil");
}

- (void)testAssertFail {
    XCTFail(@"womp womp. I spilled my ice cream");
}

- (void)testAssertNotNil {
    XCTAssertNotNil(nil, "This clearly should be nil");
}

- (void)testAssert {
    XCTAssert(3==6, @"3 should equal 6");
}

- (void)testAssertTrue {
    XCTAssertTrue(NO, "No should equal YES");
}

- (void)testAssertFalse {
    XCTAssertFalse(YES, "YES should equal NO");
}

- (void)testAssertEqualObjects {
    XCTAssertEqualObjects(@"Yep", @"Nope", @"\"Yep\" and \"Nope\" should be equal");
}

- (void)testAssertNotEqualObjects {
    XCTAssertNotEqualObjects(@55, @55, @"55 should not equal 55");
}

- (void)testAssertEqual {
    XCTAssertEqual(23, 45, @"23 == 45");
}

- (void)testAssertNotEqual {
    XCTAssertNotEqual(420, 420, @"whoah brooo.... where am I?");
}

- (void)testAssertEqualWithAccuracy {
    XCTAssertEqualWithAccuracy(23, 54, 0, @"23 == 54");
}

- (void)testAssertNotEqualWithAccuracy {
    XCTAssertEqualWithAccuracy(-54, 54, 0, @"54 != 54");
}

- (void)testExpectation {
    XCTestExpectation *exp = [self expectationWithDescription:@"Some expectation here"];
    [self waitForExpectations:@[exp] timeout:0];
}

- (void)testOverfulfill {
    XCTestExpectation *exp = [self expectationWithDescription:@"Some expectation here"];
    [exp fulfill];
    [exp fulfill];
}

@end
