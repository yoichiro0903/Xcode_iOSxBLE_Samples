//
//  ViewController.m
//  BLESample
//
//  Created by Shuichi Tsutsumi on 10/9/14.
//  Copyright (c) 2014 Shuichi Tsutsumi. All rights reserved.
//

#import "ViewController.h"
@import CoreBluetooth;


@interface ViewController () <CBCentralManagerDelegate, CBPeripheralDelegate>
{
    BOOL isScanning;
}
@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheral *peripheral;
@end


@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];

    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self
                                                               queue:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


// =============================================================================
#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {

    // 特に何もしない
    NSLog(@"centralManagerDidUpdateState:%ld", (long)central.state);
}

- (void)   centralManager:(CBCentralManager *)central
    didDiscoverPeripheral:(CBPeripheral *)peripheral
        advertisementData:(NSDictionary *)advertisementData
                     RSSI:(NSNumber *)RSSI
{
    NSLog(@"発見したBLEデバイス：%@", peripheral);
    
    // 接続開始
    self.peripheral = peripheral;
    [self.centralManager connectPeripheral:peripheral
                                   options:nil];
}

- (void)  centralManager:(CBCentralManager *)central
    didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"接続成功！:%@", peripheral);

    peripheral.delegate = self;
    
    // サービス探索開始
    [peripheral discoverServices:nil];
}

- (void)        centralManager:(CBCentralManager *)central
    didFailToConnectPeripheral:(CBPeripheral *)peripheral
                         error:(NSError *)error
{
    NSLog(@"接続失敗・・・");
}


// =============================================================================
#pragma mark - CBPeripheralDelegate

// サービス発見時に呼ばれる
- (void)     peripheral:(CBPeripheral *)peripheral
    didDiscoverServices:(NSError *)error
{
    if (error) {
        NSLog(@"エラー:%@", error);
        return;
    }
    
    NSArray *services = peripheral.services;
    NSLog(@"%lu 個のサービスを発見！:%@", (unsigned long)services.count, services);
    
    for (CBService *service in services) {
        
        // キャラクタリスティック探索開始
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

// キャラクタリスティック発見時に呼ばれる
- (void)                      peripheral:(CBPeripheral *)peripheral
    didDiscoverCharacteristicsForService:(CBService *)service
                                   error:(NSError *)error
{
    if (error) {
        NSLog(@"エラー:%@", error);
        return;
    }
    
    NSArray *characteristics = service.characteristics;
    NSLog(@"%lu 個のキャラクタリスティックを発見！%@", (unsigned long)characteristics.count, characteristics);
}

- (void)   peripheral:(CBPeripheral *)peripheral
    didModifyServices:(NSArray *)invalidatedServices
{
    
    NSLog(@"didModifyServices: %@", invalidatedServices);
    
    [self.peripheral discoverServices:nil];
}


// =============================================================================
#pragma mark - IBAction

- (IBAction)scanBtnTapped:(UIButton *)sender {
    
    if (!isScanning) {
        
        isScanning = YES;
        
        // スキャン開始
        [self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:@"0010"]]
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
