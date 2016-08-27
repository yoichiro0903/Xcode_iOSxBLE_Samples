//
//  ViewController.m
//  KonashiPioDrive
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
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)ready{
    [Konashi pinMode:KonashiDigitalIO1 mode:KonashiPinModeOutput];
    [Konashi digitalWrite:KonashiDigitalIO1 value:KonashiLevelHigh];
}

@end
