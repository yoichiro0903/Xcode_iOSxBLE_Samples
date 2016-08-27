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


NSString * const kServiceUUID = @"1111";
NSString * const kCharacteristicUUID = @"1112";


@interface BLEManager ()
<CBCentralManagerDelegate, CBPeripheralDelegate>
@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, strong) CBCharacteristic *characteristic;
@property (nonatomic, strong) CBUUID *characteristicUUID;
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

    NSLog(@"initInstance");
    
    NSDictionary *options = @{CBCentralManagerOptionRestoreIdentifierKey: @"myRestoreIdentifierKey"};

    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self
                                                               queue:nil
                                                             options:options];
    
    self.characteristicUUID = [CBUUID UUIDWithString:kCharacteristicUUID];
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
}

- (void)stopScan {
    [self.centralManager stopScan];
}

- (void)read {

    [self.peripheral readValueForCharacteristic:self.characteristic];
}

- (void)write {

    Byte value = arc4random() & 0xff;
    NSData *data = [NSData dataWithBytes:&value length:1];
    
    [self.peripheral writeValue:data
              forCharacteristic:self.characteristic
                           type:CBCharacteristicWriteWithResponse];
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

// アプリケーション復元時に呼ばれる
- (void)centralManager:(CBCentralManager *)central
      willRestoreState:(NSDictionary *)dict
{
    NSString *msg = [NSString stringWithFormat:@"セントラル復元：%@", dict];
    
    NSLog(@"%@", msg);
    
    [self publishLocalNotificationWithMessage:msg];
    
    // 復元直後のプロパティを見てみる
    NSLog(@"centralManager:%@, peripheral: %@", self.centralManager, self.peripheral);

    // コンソール出力結果: centralManager:<CBCentralManager: 0x17408cad0>, peripheral: (null)
    // → プロパティ等を復元してくれるわけではない。centralManagerにオブジェクトがセットされているのは、アプリをバックグラウンド状態で起動する際に sharedInstance を通るため

    // 復元されたcentralManagerと、新たに初期化したcentralManagerとを比較してみる
    NSLog(@"centralManager: %@, %@", central, self.centralManager);
    NSLog(@"isEqual: %d", [central isEqual:self.centralManager]);
    NSLog(@"state:%ld, %ld", (long)central.state, (long)self.centralManager.state);
    
    // コンソール出力結果: centralManager: <CBCentralManager: 0x170082f80>, <CBCentralManager: 0x170082f80>
    //  isEqual: 1
    //  state:0, 0
    // → initInstanceで初期化する際に復元識別子を渡しているので、引数に入ってくるものと同じオブジェクトが復元できている
    //   この時点ではまだPowerOnにはなっていない
    
    
    // 復元された、接続を試みている、あるいは接続済みのペリフェラル
    NSArray *peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey];
    
    // 接続済みであればプロパティに保持しなおす
    for (CBPeripheral *aPeripheral in peripherals) {
        
        if (aPeripheral.state == CBPeripheralStateConnected) {
            
            self.peripheral = aPeripheral;
            
            // delegateがセットされてるか見てみる
            NSLog(@"peripheral.delegate: %@", self.peripheral.delegate);
            // コンソール出力結果：peripheral.delegate: (null)
            // → delegateにセットしていたオブジェクトは復元してくれない
            
            // セットしなおす
            self.peripheral.delegate = self;
        }
    }
    
    // 復元されたペリフェラルについて、キャラクタリスティックの状態を見てみる・プロパティにセットしなおす
    for (CBService *aService in self.peripheral.services) {
        
        for (CBCharacteristic *aCharacteristic in aService.characteristics) {

            if ([aCharacteristic.UUID isEqual:self.characteristicUUID]) {
                
                NSLog(@"characteristic: %@", aCharacteristic);
                
                // コンソール出力結果： characteristic: <CBCharacteristic: 0x174086680, UUID = 1112, properties = 0x12, value = <a5>, notifying = YES>
                // → Notifyの状態まで復元されていることがわかる
                
                self.characteristic = aCharacteristic;
            }
        }
    }

//    NSArray *services = dict[CBCentralManagerRestoredStateScanServicesKey];
//    NSArray *options = dict[CBCentralManagerRestoredStateScanOptionsKey];
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
        
        if ([characteristic.UUID isEqual:self.characteristicUUID]) {
            
            self.characteristic = characteristic;
            
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
}

@end
