//
//  main.m
//  xpkg
//
//  Created by Jack Maloney on 3/31/14.
//  Copyright (c) 2014 IV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "xpkg.h"

int main(int argc, const char * argv[])
{

    @autoreleasepool {
        [xpkg checkForArgs:argc];
        NSString* arg1 = [NSString stringWithUTF8String:argv[1]];
        [xpkg parseArg1:arg1];
        
    }
    return 0;
}

