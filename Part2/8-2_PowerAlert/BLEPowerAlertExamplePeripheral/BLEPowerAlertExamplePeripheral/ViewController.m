//
//  ViewController.m
//  BLESample
//
//  Created by Shuichi Tsutsumi on 10/9/14.
//  Copyright (c) 2014 Shuichi Tsutsumi. All rights reserved.
//

#import "ViewController.h"
@import CoreBluetooth;


@interface ViewController () <CBPeripheralManagerDelegate>
@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
@property (nonatomic, weak) IBOutlet UIButton *advertiseBtn;
@end


@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];

    // PowerAlertオプションをYESに
    NSDictionary *options = @{CBPeripheralManagerOptionShowPowerAlertKey: @YES};
    
    // ペリフェラルマネージャ初期化
    self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self
                                                                     queue:nil
                                                                   options:options];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


// =============================================================================
#pragma mark - Private

- (void)startAdvertise {

    // アドバタイズメントデータを作成する
    NSDictionary *advertisementData = @{CBAdvertisementDataLocalNameKey: @"Test Device"};
    
    // アドバタイズ開始
    [self.peripheralManager startAdvertising:advertisementData];
    
    [self.advertiseBtn setTitle:@"STOP ADVERTISING" forState:UIControlStateNormal];
}

- (void)stopAdvertise {

    [self.peripheralManager stopAdvertising];
    
    [self.advertiseBtn setTitle:@"START ADVERTISING" forState:UIControlStateNormal];
}


// =============================================================================
#pragma mark - CBPeripheralManagerDelegate

// ペリフェラルマネージャの状態が変化すると呼ばれる
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {

    NSLog(@"peripheralManagerDidUpdateState:%ld", (long)peripheral.state);
    
    switch (peripheral.state) {
        case CBPeripheralManagerStatePoweredOn:

            // アドバタイズ開始
            [self startAdvertise];

            break;
            
        default:
            break;
    }
}

// アドバタイズ開始処理が完了すると呼ばれる
- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral
                                       error:(NSError *)error
{
    if (error) {
        NSLog(@"アドバタイズ開始失敗！ error:%@", error);
        return;
    }
    
    NSLog(@"アドバタイズ開始成功！");
}


// =============================================================================
#pragma mark - IBAction

- (IBAction)advertiseBtnTapped:(UIButton *)sender {

    // START
    if (!self.peripheralManager.isAdvertising) {

        [self startAdvertise];
    }
    // STOP
    else {

        [self stopAdvertise];
    }
}

@end
