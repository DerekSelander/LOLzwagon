//
//  TestView.m
//  CodeCoverage
//
//  Created by Derek Selander on 1/27/19.
//  Copyright © 2019 Derek Selander. All rights reserved.
//

#import "TestView.h"

@implementation TestView


+ (void)load {
    for(int i = 0; i < 20; i++) {
        [TestView test];
    }
}

+ (void)test {
    if (arc4random_uniform(2) != 0) {
        NSLog(@"woot");
    } else {
        NSLog(@"loot");
    }
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
