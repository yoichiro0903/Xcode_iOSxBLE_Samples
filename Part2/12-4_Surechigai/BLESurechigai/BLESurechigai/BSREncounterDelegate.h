//
//  BSREncounterDelegate.h
//  BLESurechigai
//
//  Created by Shuichi Tsutsumi on 2014/12/28.
//  Copyright (c) 2014年 Shuichi Tsutsumi. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol BSREncounterDelegate <NSObject>
- (void)didEncounterUserWithName:(NSString *)username;
@end
