//
//  xpkg.h
//  xpkg
//
//  Created by Jack Maloney on 3/31/14.
//  Copyright (c) 2014 IV. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString* USAGE = @"\nxpkg [options] command [options] <arguments> \ntype xpkg -h  for more help\n";

static NSString* PREFIX = @"/opt/xpkg";

static NSString* VERSION = @"1.0.0";

static NSString* HELP_TEXT = @"";

static NSString* VERSION_ARG = @"-V";
static NSString* INSTALL = @"install";
static NSString* UPDATE = @"update";
static NSString* UPGRADE = @"upgrade";
static NSString* REINSTALL = @"reinstall";
static NSString* REMOVE = @"remove";
static NSString* BUILD = @"build";
static NSString* LIST = @"list";
static NSString* SEARCH = @"search";
static NSString* ADD = @"add";
static NSString* CREATE = @"create";
static NSString* EXTRACT = @"extract";

// Colors for terminal output
static NSString* RESET = @"\033[0m";
static NSString* RED = @"\033[31m";      /* Red */
static NSString* GREEN = @"\033[32m";      /* Green */
static NSString* BLUE = @"\033[34m";      /* Blue */
static NSString* MAGENTA  = @"\033[35m";      /* Magenta */
static NSString* CYAN = @"\033[36m";      /* Cyan */
static NSString* BOLDRED = @"\033[1m\033[31m";      /* Bold Red */
static NSString* BOLDGREEN = @"\033[1m\033[32m";      /* Bold Green */

@interface xpkg : NSObject
+(void) print:(NSString*)x;
+(void) printError:(NSString*)x;
+(BOOL) checkForArgs:(int)argc;
+(NSString*) executeCommand:(NSString*)command withArgs:(NSArray*)args andPath:(NSString*)path;
+(BOOL) checkHashes:(NSString*)sha rmd160:(NSString*)rmd atPath:(NSString*) path;
+(void) updateProgram;
+(void) downloadFile:(NSString*)URL place:(NSString*)path;
+(void) exitIfNotRoot;
+(BOOL) installPackage:(NSString*)path;
+(NSFileHandle*) getFileAtPath:(NSString*)path;
+(NSString*) getStringFromData:(NSData*) data;
+(NSData*) getDataFromFile:(NSFileHandle*) file;
+(NSString*) getPathWithPrefix:(NSString*)path;
@end

void Xlog(BOOL tofile, NSString* format, ...) {
    va_list argList;
    va_start(argList, format);
    NSString* formattedMessage = [[NSString alloc] initWithFormat: format arguments: argList];
    va_end(argList);
    NSLog(@"%@", formattedMessage);
    fprintf(fopen([[xpkg getPathWithPrefix:@"/log/xpkg.log"] UTF8String], "a"), "%s\n", [formattedMessage UTF8String]);
}
