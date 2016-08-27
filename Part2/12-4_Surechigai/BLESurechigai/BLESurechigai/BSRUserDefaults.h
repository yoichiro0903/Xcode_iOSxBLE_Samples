//
//  BSRUserDefaults.h
//  BLESurechigai
//
//  Created by Shuichi Tsutsumi on 2014/12/28.
//  Copyright (c) 2014年 Shuichi Tsutsumi. All rights reserved.
//

#import <Foundation/Foundation.h>


extern NSString * const kEncouterDictionaryKeyUsername;
extern NSString * const kEncouterDictionaryKeyDate;
extern NSString * const kDefaultUsername;


@interface BSRUserDefaults : NSObject

+ (NSString *)username;
+ (void)setUsername:(NSString *)username;

+ (NSArray *)encounters;
+ (void)setEncounters:(NSArray *)encounters;
+ (void)addEncounterWithName:(NSString *)username date:(NSDate *)date;

@end
