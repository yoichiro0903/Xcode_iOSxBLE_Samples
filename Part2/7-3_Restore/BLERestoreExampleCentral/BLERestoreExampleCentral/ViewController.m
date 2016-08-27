//
//  ViewController.m
//  BLESample
//
//  Created by Shuichi Tsutsumi on 10/9/14.
//  Copyright (c) 2014 Shuichi Tsutsumi. All rights reserved.
//

#import "ViewController.h"
#import "BLEManager.h"


@interface ViewController ()
{
    BOOL isScanning;
}
@end


@implementation ViewController

- (void)viewDidLoad {
    
    NSLog(@"viewDidLoad");
    
    [super viewDidLoad];
    
    // 初期化
    [BLEManager sharedManager];
}

- (void)viewWillAppear:(BOOL)animated {

    NSLog(@"viewWillAppear");

    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {

    NSLog(@"viewDidAppear");

    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


// =============================================================================
#pragma mark - IBAction

- (IBAction)scanBtnTapped:(UIButton *)sender {

    if (!isScanning) {

        isScanning = YES;
        
        // スキャン開始
        [[BLEManager sharedManager] startScan];
        
        [sender setTitle:@"STOP SCAN" forState:UIControlStateNormal];
    }
    else {
        
        // スキャン停止
        [[BLEManager sharedManager] stopScan];
        
        [sender setTitle:@"START SCAN" forState:UIControlStateNormal];
        isScanning = NO;
    }
}

- (IBAction)readBtnTapped:(id)sender {

    [[BLEManager sharedManager] read];
}

- (IBAction)writeBtnTapped:(id)sender {

    [[BLEManager sharedManager] write];
}

@end
