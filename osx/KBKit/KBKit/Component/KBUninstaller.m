//
//  KBUninstaller.m
//  Keybase
//
//  Created by Gabriel on 6/11/15.
//  Copyright (c) 2015 Keybase. All rights reserved.
//

#import "KBUninstaller.h"
#import "KBLaunchCtl.h"
#import "KBRunOver.h"
#import "KBPath.h"
#import <CocoaLumberjack/CocoaLumberjack.h>

@implementation KBUninstaller

+ (void)uninstall:(NSString *)prefix completion:(KBCompletion)completion {
  NSAssert([prefix length] > 2, @"Must have a prefix");
  NSFileManager *fileManager = NSFileManager.defaultManager;

  NSURL *URL = [NSURL fileURLWithPath:[KBPath path:@"~/Library/LaunchAgents/" options:0] isDirectory:YES];

  NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtURL:URL includingPropertiesForKeys:@[NSURLIsRegularFileKey] options:0 errorHandler:^(NSURL *url, NSError *error) {
    return YES;
  }];

  KBRunOver *rover = [[KBRunOver alloc] init];
  rover.enumerator = enumerator;
  rover.runBlock = ^(NSURL *URL, KBRunCompletion runCompletion) {
    if ([[URL.path lastPathComponent] hasPrefix:prefix]) {
      DDLogDebug(@"Unloading %@", URL.path);
      [KBLaunchCtl unload:URL.path label:nil disable:NO completion:^(NSError *error, NSString *output) {
        DDLogDebug(@"Removing %@", URL.path);
        [fileManager removeItemAtPath:[KBPath path:URL.path options:0] error:nil];
        runCompletion(URL);
      }];
    } else {
      runCompletion(URL);
    }
  };
  rover.completion = ^(NSArray *outputs) {
    //[self deleteAll:@"~/Library/Application Support/Keybase"];
    completion(nil);
  };
  [rover run];
}

+ (void)deleteAll:(NSString *)dir {
  NSFileManager *fileManager = NSFileManager.defaultManager;
  NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:[KBPath path:dir options:0]];
  for (NSString *file in enumerator) {
    DDLogDebug(@"Removing %@", file);
    NSError *error = nil;
    if (![fileManager removeItemAtPath:[KBPath pathInDir:dir path:file options:0] error:&error]) {
      DDLogError(@"Error: %@", error);
    }
  }
}

@end
