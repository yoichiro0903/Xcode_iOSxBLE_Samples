//
//  BSRCentralManager.h
//  BLESurechigai
//
//  Created by Shuichi Tsutsumi on 2014/12/17.
//  Copyright (c) 2014年 Shuichi Tsutsumi. All rights reserved.
//

#import "BSREncounterDelegate.h"


@interface BSRCentralManager : NSObject

@property (nonatomic, weak) id<BSREncounterDelegate> deleagte;

+ (id)sharedManager;

@end
