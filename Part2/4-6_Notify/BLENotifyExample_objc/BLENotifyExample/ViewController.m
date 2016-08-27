//
//  ViewController.m
//  BLESample
//
//  Created by Shuichi Tsutsumi on 10/9/14.
//  Copyright (c) 2014 Shuichi Tsutsumi. All rights reserved.
//

#import "ViewController.h"
@import CoreBluetooth;


@interface ViewController ()
<CBCentralManagerDelegate, CBPeripheralDelegate>
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

// セントラルマネージャの状態が変化すると呼ばれる
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {

    // 特に何もしない
    NSLog(@"centralManagerDidUpdateState:%ld", (long)central.state);
}

// ペリフェラルを発見すると呼ばれる
- (void)   centralManager:(CBCentralManager *)central
    didDiscoverPeripheral:(CBPeripheral *)peripheral
        advertisementData:(NSDictionary *)advertisementData
                     RSSI:(NSNumber *)RSSI
{
    NSLog(@"発見したBLEデバイス：%@", peripheral);
    
    if ([peripheral.name hasPrefix:@"konashi"]) {
        
        self.peripheral = peripheral;
        
        // 接続開始
        [self.centralManager connectPeripheral:peripheral
                                       options:nil];
    }
}

// 接続成功すると呼ばれる
- (void)  centralManager:(CBCentralManager *)central
    didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"接続成功！");

    peripheral.delegate = self;
    
    // サービス探索開始
    [peripheral discoverServices:nil];
}

// 接続失敗すると呼ばれる
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

    for (CBCharacteristic *characteristic in characteristics) {
        
        // Notify可能なキャラクタリスティックかどうかを判定する
//        if ((characteristic.properties & CBCharacteristicPropertyNotify) != 0) {
//            
//            // 更新通知受け取りを開始する
//            [peripheral setNotifyValue:YES
//                     forCharacteristic:characteristic];
//        }

        // konashi の PIO_INPUT_NOTIFICATION キャラクタリスティック
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"3003"]]) {

            // 更新通知受け取りを開始する
            [peripheral setNotifyValue:YES
                     forCharacteristic:characteristic];
        }
    }
}

// Notify開始／停止時に呼ばれる
- (void)                             peripheral:(CBPeripheral *)peripheral
    didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic
                                          error:(NSError *)error
{
    if (error) {
        NSLog(@"Notify状態更新失敗...error:%@", error);
    }
    else {
        NSLog(@"Notify状態更新成功！characteristic UUID:%@, isNotifying:%d",
              characteristic.UUID ,characteristic.isNotifying ? YES : NO);
    }
}

// データ更新時に呼ばれる
- (void)                 peripheral:(CBPeripheral *)peripheral
    didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
                              error:(NSError *)error
{
    if (error) {
        NSLog(@"データ更新通知エラー:%@", error);
        return;
    }
    
    NSLog(@"データ更新！ characteristic UUID:%@, value:%@",
          characteristic.UUID, characteristic.value);
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
