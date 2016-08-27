//
//  ViewController.h
//  BLESample
//
//  Created by Shuichi Tsutsumi on 10/9/14.
//  Copyright (c) 2014 Shuichi Tsutsumi. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef enum {
    AdvertiseMode1,
    AdvertiseMode2,
} AdvertiseMode;


@interface ViewController : UIViewController

- (void)startAdvertiseWithMode:(AdvertiseMode)mode;

@end

