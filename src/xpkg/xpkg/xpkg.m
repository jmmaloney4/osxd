//
//  xpkg.m
//  xpkg
//
//  Created by Jack Maloney on 3/31/14.
//  Copyright (c) 2014 IV. All rights reserved.
//

#import "xpkg.h"

@implementation xpkg

+(void) print:(NSString*) x {
    printf("%s\n", [x UTF8String]);
    [xpkg log:[NSString stringWithFormat:@"INFO: %@\n", x]];
}

+(void) printError:(NSString *)x {
    printf("%sERROR: %s%s\n", [BOLDRED  UTF8String], [RESET UTF8String], [x UTF8String]);
    [xpkg log:[NSString stringWithFormat:@"ERROR: %@\n", x]];
}

+(void) printWarn:(NSString *)x {
    printf("%sWARNING: %s%s\n", [BOLDYELLOW UTF8String], [RESET UTF8String], [x UTF8String]);
    [xpkg log:[NSString stringWithFormat:@"WARNING: %@\n", x]];
}

+(void) log:(NSString *)x {
    NSString* date = [xpkg getTimestamp];

    NSString* pre = @"[ ";

    pre = [pre stringByAppendingString:date];
    pre = [pre stringByAppendingString:@" ] "];
    pre = [pre stringByAppendingString:x];

    NSData* data = [pre dataUsingEncoding:NSUTF8StringEncoding];

    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:LOG_FILE];
    [fileHandle seekToEndOfFile];
    [fileHandle writeData:data];
    [fileHandle closeFile];
}

+(NSString*) getTimestamp {
    NSDate *myDate = [[NSDate alloc] init];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"cccc, MMMM dd, YYYY, HH:mm:ss.SSS aa"];
    NSString* date = [dateFormat stringFromDate:myDate];
    return date;
}

+(BOOL) checkForArgs:(int)argc {
    BOOL rv = NO;
    if (argc < 2) {
        [xpkg print:USAGE];
        exit(1);
        rv = NO;
    } else {
        rv = YES;
        return rv;
    }
    return rv;
}

/**
 * Uses an NSTask to execute a shell command
 **/
+(NSString*)executeCommand:(NSString*)command withArgs:(NSArray*)args andPath:(NSString*)path printErr:(BOOL)er printOut:(BOOL)ot {
    NSString* rv;
    NSTask* task = [[NSTask alloc] init];

    [task setLaunchPath:command];
    [task setArguments:args];
    [task setCurrentDirectoryPath:path];

    NSPipe* pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];

    NSPipe* err = [NSPipe pipe];
    [task setStandardError:err];

    [task launch];

    NSFileHandle* file = [pipe fileHandleForReading];
    NSData* data = [file readDataToEndOfFile];

    NSFileHandle* errfile = [err fileHandleForReading];
    NSData* errdata = [errfile readDataToEndOfFile];

    // prints the error of the command to stderr if 'er' is true
    if (er) {
        fprintf(stderr, "%s", [[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding] UTF8String]);
    }

    if (![[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding] isEqualToString:@""]) {
        [xpkg log:[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding]];
    }

    if (![[[NSString alloc] initWithData: errdata encoding: NSUTF8StringEncoding] isEqualToString:@""]) {
        [xpkg log:[[NSString alloc] initWithData: errdata encoding: NSUTF8StringEncoding]];
    }

    // prints the standard out of the command to stdout if 'ot' is true
    if (ot) {
        fprintf(stdout, "%s", [[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding] UTF8String]);
    }

    return rv;
}

/*
 * Other Variants of the executeCommand method above, just with some default values in place
 */

/**
 * Uses an NSTask to execute a shell command
 **/
+(NSString*)executeCommand:(NSString*)command withArgs:(NSArray*)args andPath:(NSString*)path printErr:(BOOL)er {
    return [xpkg executeCommand:command withArgs:args andPath:path printErr:er printOut:true];
}

/**
 * Uses an NSTask to execute a shell command
 **/
+(NSString*)executeCommand:(NSString*)command withArgs:(NSArray*)args andPath:(NSString*)path printOut:(BOOL) ot {
    return [xpkg executeCommand:command withArgs:args andPath:path printErr:true printOut:ot];
}

/**
 * Uses an NSTask to execute a shell command
 **/
+(NSString*)executeCommand:(NSString*)command withArgs:(NSArray*)args andPath:(NSString*)path {
    return [xpkg executeCommand:command withArgs:args andPath:path printErr:true printOut:false];
}

/*
 * a few utility methods
 */
+(NSFileHandle*) getFileAtPath:(NSString*) path {
    NSFileHandle* file = [NSFileHandle fileHandleForReadingAtPath:path];
    return file;
}

+(NSData*) getDataFromFile:(NSFileHandle*) file {
    return [file readDataToEndOfFile];
}

+(NSString*) getStringFromData:(NSData*) data {
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

+(NSString*) getPathWithPrefix:(NSString*)path {
    NSMutableString* rv = [PREFIX mutableCopy];
    [rv appendString:path];
    return rv;
}

/**
 * Exits the program if it is not run as root
 **/
+(void) exitIfNotRoot {
    if (getuid() != 0) {
        [xpkg printError:@"Not Root, Exiting...\n"];
        exit(-1);
    }
}

/**
 * Checks the SHA256 and RIPEMD-160 hashes for the tarball downloaded by the program
 **/

+(BOOL) checkHashes:(NSString*)sha rmd160:(NSString*)rmd atPath:(NSString*)path {
    BOOL rv = NO;
    NSString* shar = [xpkg executeCommand:@"/usr/bin/shasum" withArgs:@[@"-a 256", path] andPath:@"/"];
    NSString* rmdr = [xpkg executeCommand:@"/usr/bin/openssl" withArgs:@[@"rmd160", path] andPath:@"/"];

    NSArray* shas = [shar componentsSeparatedByString:@" "];
    NSArray* rmds = [rmdr componentsSeparatedByString:@" "];

    for (int i = 0; i < [shar length]; i++) {
        if (shas[i] == sha) {
            for (int i = 0; i < [rmdr length]; i++) {
                if (rmds[i] == rmd) {
                    rv = YES;
                    return rv;
                }
            }
        }
    }

    return rv;
}

/**
 * updates Xpkg itself
 **/

+(void) updateProgram {
    [xpkg executeCommand:@"/opt/xpkg/bin/git" withArgs:@[@"pull"] andPath:[xpkg getPathWithPrefix:@""]];
    [xpkg executeCommand:@"/usr/bin/xcodebuild" withArgs:@[] andPath:[xpkg getPathWithPrefix:@"/src/xpkg"]];
    [xpkg executeCommand:@"/bin/cp" withArgs:@[[xpkg getPathWithPrefix:@"/src/xpkg/build/Release/xpkg"], [xpkg getPathWithPrefix:@"/core/"]] andPath:[xpkg getPathWithPrefix:@""]];
    [xpkg executeCommand:@"/bin/ln" withArgs:@[@"-fF", [xpkg getPathWithPrefix:@"/core/xpkg"], @"/usr/bin/xpkg"] andPath:[xpkg getPathWithPrefix:@""]];
}

/**
 * Downloads the fie at URL and saves it at the path provided
 **/
+(void) downloadFile:(NSString*)URL place:(NSString*)path {
    NSData* data = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:URL]];
    [data writeToFile:path atomically:YES];
}

/**
 * installs a package from the package file at path
 **/
+(BOOL) installPackage:(NSString*)path {
    BOOL s = NO;

    NSString* package;
    NSString* name;
    NSString* version;
    NSString* sha256;
    NSString* rmd160;
    NSString* description;
    NSString* url;
    NSString* homepage;
    NSString* maintainer;
    NSArray* depends;
    NSArray* recomended;

    NSFileHandle* file = [xpkg getFileAtPath:path];
    NSString* filestr = [xpkg getStringFromData:[xpkg getDataFromFile:file]];

    NSArray* filecmps = [filestr componentsSeparatedByString:@"\n"];

    if (!filecmps) {
        return NO;
    }

    for (int x = 0; x < [filecmps count]; x++) {
        if ([filecmps[x] hasPrefix:@"@"]) {
            //parse attribute
            NSArray* f = [filecmps[x] componentsSeparatedByString:@":"];

            if ([[f[0] componentsSeparatedByString:@"@"][1] isEqualToString:@"Package"]) {
                package = f[1];
                if ([package hasPrefix:@" "]) {
                    package = [package substringWithRange:NSMakeRange(1, [package length]-1)];
                }
            } else if ([[f[0] componentsSeparatedByString:@"@"][1] isEqualToString:@"Version"]) {
                version = f[1];
                if ([version hasPrefix:@" "]) {
                    version = [version substringWithRange:NSMakeRange(1, [version length]-1)];
                }
            } else if ([[f[0] componentsSeparatedByString:@"@"][1] isEqualToString:@"Name"]) {
                name = f[1];
                if ([name hasPrefix:@" "]) {
                    name = [name substringWithRange:NSMakeRange(1, [name length]-1)];
                    [xpkg print:name];
                }
            } else if ([[f[0] componentsSeparatedByString:@"@"][1] isEqualToString:@"SHA256"]) {
                sha256 = f[1];
                if ([sha256 hasPrefix:@" "]) {
                    sha256 = [sha256 substringWithRange:NSMakeRange(1, [sha256 length]-1)];
                    [xpkg print:sha256];
                }
            } else if ([[f[0] componentsSeparatedByString:@"@"][1] isEqualToString:@"RMD160"]) {
                rmd160 = f[1];
                if ([rmd160 hasPrefix:@" "]) {
                    rmd160 = [rmd160 substringWithRange:NSMakeRange(1, [rmd160 length]-1)];
                    [xpkg print:rmd160];
                }
            } else if ([[f[0] componentsSeparatedByString:@"@"][1] isEqualToString:@"Description"]) {
                description = f[1];
                if ([description hasPrefix:@" "]) {
                    description = [description substringWithRange:NSMakeRange(1, [description length]-1)];
                    [xpkg print:description];
                }
            } else if ([[f[0] componentsSeparatedByString:@"@"][1] isEqualToString:@"URL"]) {
                url = f[1];
                url = [url stringByAppendingString:@":"];
                url = [url stringByAppendingString:f[2]];
                if ([url hasPrefix:@" "]) {
                    url = [url substringWithRange:NSMakeRange(1, [url length]-1)];
                    [xpkg print:url];
                }
            } else if ([[f[0] componentsSeparatedByString:@"@"][1] isEqualToString:@"Maintainer"]) {
                maintainer = f[1];
                if ([maintainer hasPrefix:@" "]) {
                    maintainer = [maintainer substringWithRange:NSMakeRange(1, [maintainer length]-1)];
                    [xpkg print:maintainer];
                }
            } else if ([[f[0] componentsSeparatedByString:@"@"][1] isEqualToString:@"Homepage"]) {
                homepage = f[1];
                homepage = [homepage stringByAppendingString:@":"];
                homepage = [homepage stringByAppendingString:f[2]];
                if ([homepage hasPrefix:@" "]) {
                    homepage = [homepage substringWithRange:NSMakeRange(1, [homepage length]-1)];
                    [xpkg print:homepage];
                }
            } else if ([[f[0] componentsSeparatedByString:@"@"][1] isEqualToString:@"Depends"]) {
                NSString* str = f[1];
                depends = [str componentsSeparatedByString:@","];
                NSMutableArray* md = [depends mutableCopy];
                for (int a = 0; a < [md count]; a++) {
                    if ([md[a] hasPrefix:@" "]) {
                        md[a] = [md[a] substringWithRange:NSMakeRange(1, [md[a] length] - 1)];
                        [xpkg print:md[a]];
                    }
                }
                depends = md;
            }  else if ([[f[0] componentsSeparatedByString:@"@"][1] isEqualToString:@"Recomended"]) {
                NSString* str = f[1];
                recomended = [str componentsSeparatedByString:@","];
                NSMutableArray* md = [recomended mutableCopy];
                for (int a = 0; a < [md count]; a++) {
                    if ([md[a] hasPrefix:@" "]) {
                        md[a] = [md[a] substringWithRange:NSMakeRange(1, [md[a] length] - 1)];
                        [xpkg print:md[a]];
                    }
                }
                recomended = md;
            }


        } else if ([filecmps[x] hasPrefix:@"&"]) {
            if ([[filecmps[x] componentsSeparatedByString:@" "][0] isEqualToString:@"&build"]) {
                for (int d = 0; ![filecmps[x] isEqualToString:@"}"]; d++) {
                    x++;
                    if ([filecmps[x] hasPrefix:@"$"] || [filecmps[x] hasPrefix:@"\t$"]) {
                        // SHELL COMMAND
                    } else if ([filecmps[x] hasPrefix:@"%"] || [filecmps[x] hasPrefix:@"\t%"]) {
                        // SPECIAL COMMAND
                    }
                }
            } else if ([[filecmps[x] componentsSeparatedByString:@" "][0] isEqualToString:@"&install"]) {
                [xpkg print:@"\nINSTALL METHOD\n"];
            }
        } else if ([filecmps[x] hasPrefix:@"#"]) {
            //comment, ignore
        }
    }
    return s;
}

/**
 * clears the Xpkg log file
 **/
+(void) clearLog {
    [xpkg executeCommand:@"/bin/rm" withArgs:@[@"/opt/xpkg/log/xpkg.log"] andPath:@"/"];
    [xpkg executeCommand:@"/usr/bin/touch" withArgs:@[@"/opt/xpkg/log/xpkg.log"] andPath:@"/"];
    [xpkg print:[NSString stringWithFormat:@"Cleared Log At: %@", [xpkg getTimestamp]]];
}

@end

