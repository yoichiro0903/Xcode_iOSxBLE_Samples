//
//  ViewController.m
//  KonashiReadRSSI
//
//  Created by Matsumura Reo on 2015/03/18.
//  Copyright (c) 2015年 Matsumura Reo. All rights reserved.
//

#import "ViewController.h"
#import "Konashi.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [Konashi initialize];
    [Konashi find];
    
    [Konashi addObserver:self selector:@selector(ready) name:KonashiEventReadyToUseNotification];
    [Konashi addObserver:self selector:@selector(updateRSSI) name:KonashiEventSignalStrengthDidUpdateNotification];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)ready{
    NSLog(@"READY");
    NSTimer *tm = [NSTimer
                   scheduledTimerWithTimeInterval:01.0f
                   target:self
                   selector:@selector(onRSSITimer:)
                   userInfo:nil
                   repeats:YES
                   ];
    [tm fire];
}

- (void)onRSSITimer:(NSTimer *)timer
{
    [Konashi signalStrengthReadRequest];
}

- (void)updateRSSI{
    NSLog(@"READ_STRENGRH: %d",[Konashi signalStrengthRead]);
    
}

@end
