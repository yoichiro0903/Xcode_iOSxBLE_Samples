//
//  SensorHelper.m
//  GestureRecognizerCentral
//
//  Created by Shuichi Tsutsumi on 2014/12/30.
//  Copyright (c) 2014年 Shuichi Tsutsumi. All rights reserved.
//

#import "SensorHelper.h"


@implementation SensorHelper

+ (float)calcXValue:(NSData *)data {
    
    char scratchVal[data.length];
    [data getBytes:&scratchVal length:3];
    return ((scratchVal[0] * 1.0) / (256 / KXTJ9_RANGE));
}

+ (float)calcYValue:(NSData *)data {
    
    //Orientation of sensor on board means we need to swap Y (multiplying with -1)
    char scratchVal[data.length];
    [data getBytes:&scratchVal length:3];
    return ((scratchVal[1] * 1.0) / (256 / KXTJ9_RANGE)) * -1;
}

+ (float)calcZValue:(NSData *)data {
    
    char scratchVal[data.length];
    [data getBytes:&scratchVal length:3];
    return ((scratchVal[2] * 1.0) / (256 / KXTJ9_RANGE));
}

+ (float)getRange {
    
    return KXTJ9_RANGE;
}

@end
