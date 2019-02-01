
//  TestView.m
//  CodeCoverage
//
//  Created by Derek Selander on 1/27/19.
//  Copyright © 2019 Derek Selander. All rights reserved.
//

#import "TestView.h"

@implementation TestView


bool shouldDoStuff = NO;
// load will work, loads should not ever execute
//+ (void)load {
//    NSLog(@"woot woot loaded");
//    [self test];
//    shouldDoStuff = YES;
//    [self test];
//}

//void aSimpleFunc(int a, int b) {
//
//}

+ (void)test {
    int f = 0;
    if (shouldDoStuff) {
        f = 5;
    } else {
        f = 6;
    }
    printf("%d\n", f);
    
}

+ (void)dammit {
    if (shouldDoStuff) {
        printf("how did I get here!?\n");
    } else {
        printf("wooooooooooooooooooooot\n");
    }
}


- (int)codecovClosure {
    int (^blockTest)(int) = ^int(int a) {
        if (a == 2) {
            return a;
        }
        return a * a;
    };
    
    
    
    return blockTest(4);
}
@end
