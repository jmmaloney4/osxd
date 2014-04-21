//
//  package.h
//  xpkg
//
//  Created by Jack Maloney on 4/13/14.
//  Copyright (c) 2014 Jack Maloney. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XPRepository.h"

@interface XPPackage : NSObject

-(instancetype) initWithpath:(NSString*)path;
-(instancetype) initWithpath:(NSString*)path andRepo:(NSString*)repon;
@property NSString* url;
@property NSString* package;
@property NSString* description;
@property NSString* maintainer;
@property NSString* version;
@property NSString* path;
@property NSString* name;
@property NSString* homepage;
@property NSString* sha256;
@property NSString* rmd160;
@property NSArray* mirrors;
@property NSArray* depends;
@property NSArray* dependers;
@property NSArray* recomended;
@property NSString* repo_name;
@property NSInteger* pkgid;

-(BOOL) install;
-(BOOL) remove;
@end
