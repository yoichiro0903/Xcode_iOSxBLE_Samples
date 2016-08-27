//
//  ViewController.m
//  BLESample
//
//  Created by Shuichi Tsutsumi on 10/9/14.
//  Copyright (c) 2014 Shuichi Tsutsumi. All rights reserved.
//

#import "ViewController.h"
@import CoreBluetooth;


@interface ViewController () <CBCentralManagerDelegate>
{
    BOOL isScanning;
}
@property (nonatomic, strong) CBCentralManager *centralManager;
@end


@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];

    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


// =============================================================================
#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {

    NSLog(@"centralManagerDidUpdateState:%ld", (long)central.state);

    switch (central.state) {
            
        case CBCentralManagerStatePoweredOn:
            
            // オンになったらスキャンを開始してもOK

            break;
            
        default:
            break;
    }
}

- (void)   centralManager:(CBCentralManager *)central
    didDiscoverPeripheral:(CBPeripheral *)peripheral
        advertisementData:(NSDictionary *)advertisementData
                     RSSI:(NSNumber *)RSSI
{
    NSLog(@"発見したBLEデバイス：%@", peripheral);

    NSLog(@"アドバタイズメントデータ: %@", advertisementData);
}


// =============================================================================
#pragma mark - IBAction

- (IBAction)scanBtnTapped:(UIButton *)sender {
    
    if (!isScanning) {
        
        isScanning = YES;
        
        // スキャン開始
        [self.centralManager scanForPeripheralsWithServices:nil
                                                    options:nil];
        [sender setTitle:@"STOP SCAN" forState:UIControlStateNormal];
    }
    else {
        
        // スキャン停止
        [self.centralManager stopScan];
        [sender setTitle:@"START SCAN" forState:UIControlStateNormal];
        isScanning = NO;
    }
}

@end
