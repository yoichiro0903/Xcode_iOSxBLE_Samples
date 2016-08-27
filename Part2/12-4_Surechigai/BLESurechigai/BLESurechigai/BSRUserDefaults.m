//
//  BSRUserDefaults.m
//  BLESurechigai
//
//  Created by Shuichi Tsutsumi on 2014/12/28.
//  Copyright (c) 2014年 Shuichi Tsutsumi. All rights reserved.
//

#import "BSRUserDefaults.h"


#define Defaults [NSUserDefaults standardUserDefaults]

NSString * const kUserDefaultsKeyUsername   = @"username";
NSString * const kUserDefaultsEncounters = @"encounters";

NSString * const kEncouterDictionaryKeyUsername = @"username";
NSString * const kEncouterDictionaryKeyDate     = @"date";

NSString * const kDefaultUsername = @"名無しさん";


@interface BSRUserDefaults ()
@end


@implementation BSRUserDefaults

+ (NSString *)username {
    
    return [Defaults stringForKey:kUserDefaultsKeyUsername];
}

+ (void)setUsername:(NSString *)username {
    
    [Defaults setObject:username forKey:kUserDefaultsKeyUsername];
    [Defaults synchronize];
}

+ (NSArray *)encounters {
    
    return [Defaults arrayForKey:kUserDefaultsEncounters];
}

+ (void)setEncounters:(NSArray *)encounters {
    
    [Defaults setObject:encounters forKey:kUserDefaultsEncounters];
    [Defaults synchronize];
}

+ (void)addEncounterWithName:(NSString *)username date:(NSDate *)date {

    if (![username length] || !date) {
        return;
    }
    
    
    NSMutableArray *encounters = [self encounters] ? [self encounters].mutableCopy : @[].mutableCopy;
    [encounters addObject:@{kEncouterDictionaryKeyUsername: username,
                            kEncouterDictionaryKeyDate: date}];
    
    [self setEncounters:encounters];
}

@end
