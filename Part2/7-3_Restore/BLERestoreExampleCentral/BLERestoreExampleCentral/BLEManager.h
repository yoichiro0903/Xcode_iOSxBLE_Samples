//
//  BLEManager.h
//  BLESample
//
//  Created by Shuichi Tsutsumi on 2014/11/17.
//  Copyright (c) 2014年 Shuichi Tsutsumi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BLEManager : NSObject

+ (id)sharedManager;

- (void)startScan;
- (void)stopScan;

- (void)read;
- (void)write;

@end
