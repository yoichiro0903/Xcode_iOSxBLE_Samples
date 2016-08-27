//
//  SensorHelper.h
//  GestureRecognizerCentral
//
//  Created by Shuichi Tsutsumi on 2014/12/30.
//  Copyright (c) 2014年 Shuichi Tsutsumi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SensorHelper : NSObject

#define KXTJ9_RANGE 4.0

+ (float)calcXValue:(NSData *)data;
+ (float)calcYValue:(NSData *)data;
+ (float)calcZValue:(NSData *)data;
+ (float)getRange;

@end
