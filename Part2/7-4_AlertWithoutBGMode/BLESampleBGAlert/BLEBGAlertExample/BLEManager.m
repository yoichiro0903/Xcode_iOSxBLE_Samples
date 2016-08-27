//
//  BLEManager.m
//  BLESample
//
//  Created by Shuichi Tsutsumi on 2014/11/17.
//  Copyright (c) 2014年 Shuichi Tsutsumi. All rights reserved.
//

#import "BLEManager.h"
@import CoreBluetooth;


@interface BLEManager ()
<CBCentralManagerDelegate, CBPeripheralDelegate>
@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheral *peripheral;
@end


@implementation BLEManager

+ (id)sharedManager {
    
    static id instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        instance = [[self alloc] init];
        [instance initInstance];
    });
    
    return instance;
}

- (void)initInstance {

    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self
                                                               queue:nil];
}


// =============================================================================
#pragma mark - Public

- (void)startScan {
    
    // CBUUIDオブジェクトの配列を作成
    NSArray *serviceUUIDs = @[
                              [CBUUID UUIDWithString:@"FF00"]
                              ];
    
    [self.centralManager scanForPeripheralsWithServices:serviceUUIDs
                                                options:nil];
}

- (void)stopScan {
    [self.centralManager stopScan];
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
    
    if ([peripheral.name hasPrefix:@"konashi"]) {
        
        self.peripheral = peripheral;
        
        // 接続開始
        NSDictionary *options =
        @{CBConnectPeripheralOptionNotifyOnConnectionKey: @YES,
          CBConnectPeripheralOptionNotifyOnDisconnectionKey: @YES,
          CBConnectPeripheralOptionNotifyOnNotificationKey: @YES};
        
        [self.centralManager connectPeripheral:peripheral
                                       options:options];
    }
}

- (void)  centralManager:(CBCentralManager *)central
    didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"接続成功！");

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

- (void)     centralManager:(CBCentralManager *)central
    didDisconnectPeripheral:(CBPeripheral *)peripheral
                      error:(NSError *)error
{
    NSLog(@"ペリフェラル（%@）の接続が切断されました", peripheral.name);
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
    
    NSString *message = [NSString stringWithFormat:@"データ更新！ characteristic UUID:%@, value:%@",
                         characteristic.UUID, characteristic.value];
    NSLog(@"%@", message);
}

@end
