//
//  BLEManager.m
//  BLESample
//
//  Created by Shuichi Tsutsumi on 2014/11/17.
//  Copyright (c) 2014年 Shuichi Tsutsumi. All rights reserved.
//

#import "BLEManager.h"
@import CoreBluetooth;
#import <UIKit/UILocalNotification.h>
#import <UIKit/UIApplication.h>

//NSString * const kServiceUUID = @"0000";
NSString * const kServiceUUID = @"A495FF10-C5B1-4B44-B512-1370F02D74DE";
//NSString * const kCharacteristicUUID = @"0001";
NSString * const kCharacteristicUUID = @"A495FF21-C5B1-4B44-B512-1370F02D74DE";


@interface BLEManager ()
<CBCentralManagerDelegate, CBPeripheralDelegate>
@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, strong) CBCharacteristic *writingCharacteristics;
@property (nonatomic) BOOL writingFlg;
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
#pragma mark - Private

// ローカル通知を発行する（バックグラウンドのみ）
- (void)publishLocalNotificationWithMessage:(NSString *)message {
    
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
        
        UILocalNotification *localNotification = [UILocalNotification new];
        localNotification.alertBody = message;
        localNotification.fireDate = [NSDate date];
        localNotification.soundName = UILocalNotificationDefaultSoundName;
        [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
    }
}


// =============================================================================
#pragma mark - Public

- (void)startScan {
    
    // CBUUIDオブジェクトの配列を作成
    NSArray *serviceUUIDs = @[
                              [CBUUID UUIDWithString:kServiceUUID]
                              ];
    
    [self.centralManager scanForPeripheralsWithServices:serviceUUIDs
                                                options:nil];
    self.writingFlg = YES;
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
    NSString *msg = [NSString stringWithFormat:@"発見したBLEデバイス：%@", peripheral];
    
    NSLog(@"%@", msg);

    self.peripheral = peripheral;
    
    // 接続開始
    [self.centralManager connectPeripheral:peripheral
                                   options:nil];
    
    [self publishLocalNotificationWithMessage:msg];
}

- (void)  centralManager:(CBCentralManager *)central
    didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSString *msg = @"接続成功！";
    NSLog(@"%@", msg);
    
    peripheral.delegate = self;
    
    // サービス探索開始
    [peripheral discoverServices:nil];
    
    
    [self publishLocalNotificationWithMessage:msg];
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
    
    for (CBService *service in services) {
        
        // キャラクタリスティック探索開始
        [peripheral discoverCharacteristics:nil forService:service];
        NSLog(@"Found Service : %@",service);
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
        
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kCharacteristicUUID]]) {
            
            // 更新通知受け取りを開始する
            [peripheral setNotifyValue:YES
                     forCharacteristic:characteristic];
            self.writingCharacteristics = characteristic;
            NSLog(@"Found Characteristic : %@",characteristic);
        }
    }
}

// Notify開始／停止時に呼ばれる
- (void)                             peripheral:(CBPeripheral *)peripheral
    didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic
                                          error:(NSError *)error
{
    NSString *msg;
    
    if (error) {
        msg = [NSString stringWithFormat:@"Notify状態更新失敗...error:%@", error];
    }
    else {
        msg = [NSString stringWithFormat:@"Notify状態更新成功！characteristic UUID:%@, isNotifying:%d",
               characteristic.UUID ,characteristic.isNotifying ? YES : NO];
    }
    NSLog(@"%@", msg);

    [self publishLocalNotificationWithMessage:msg];
//    if (self.writingFlg) {
//        [self changeCharacteristics];
//    }
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

    [self publishLocalNotificationWithMessage:message];
//    if (self.writingFlg) {
//        [self changeCharacteristics];
//    }
}
-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSString *message = [NSString stringWithFormat:@"Send data to peripheral"];
    NSLog(@"%@", message);
    [self publishLocalNotificationWithMessage:message];
    NSLog(@"%@",error);
}
-(void) changeCharacteristics
{
    Byte value = 2;//arc4random() & 0xff;
    NSMutableData *data = [NSMutableData dataWithBytes:&value length:2];
//    CBUUID *characteristicUUID = [CBUUID UUIDWithString:kCharacteristicUUID];
//    CBCharacteristicProperties properties = (
//                                             CBCharacteristicPropertyNotify |
//                                             CBCharacteristicPropertyRead |
//                                             CBCharacteristicPropertyWrite
//                                             );
//    CBAttributePermissions permissions = (CBAttributePermissionsReadable | CBAttributePermissionsWriteable);
//
//    CBMutableCharacteristic *characteristic = [[CBMutableCharacteristic alloc] initWithType:characteristicUUID
//                                                             properties:properties
//                                                                  value:nil
//                                                            permissions:permissions];
    [self.peripheral writeValue:data forCharacteristic:self.writingCharacteristics type:CBCharacteristicWriteWithResponse];
    NSString *message = [NSString stringWithFormat:@"Wrote value of : %@, to Chara: %@",data, self.writingCharacteristics];
    NSLog(@"%@", message);
    [self publishLocalNotificationWithMessage:message];
    self.writingFlg = NO;
}

@end
