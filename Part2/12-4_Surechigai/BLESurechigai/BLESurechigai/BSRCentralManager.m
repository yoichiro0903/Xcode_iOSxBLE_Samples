//
//  BSRCentralManager.m
//  BLESurechigai
//
//  Created by Shuichi Tsutsumi on 2014/12/17.
//  Copyright (c) 2014年 Shuichi Tsutsumi. All rights reserved.
//

#import "BSRCentralManager.h"
@import CoreBluetooth;
#import "BSRConstants.h"
#import "BSRUserDefaults.h"
#import <UIKit/UIKit.h>


@interface BSRCentralManager () <CBCentralManagerDelegate, CBPeripheralDelegate>
@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) NSMutableArray *peripherals;
@property (nonatomic, strong) CBUUID *serviceUUID;
@property (nonatomic, strong) CBUUID *characteristicUUIDRead;
@property (nonatomic, strong) CBUUID *characteristicUUIDWrite;
@end


@implementation BSRCentralManager

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
    
    NSDictionary *options = @{CBCentralManagerOptionShowPowerAlertKey: @YES};
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self
                                                               queue:nil
                                                             options:options];
    
    self.serviceUUID = [CBUUID UUIDWithString:kServiceUUIDEncounter];
    self.characteristicUUIDRead  = [CBUUID UUIDWithString:kCharacteristicUUIDEncounterRead];
    self.characteristicUUIDWrite = [CBUUID UUIDWithString:kCharacteristicUUIDEncounterWrite];
    
    self.peripherals = @[].mutableCopy;
}


// =============================================================================
#pragma mark - Private

- (void)writeData:(NSData *)data toConnectedPeripheral:(CBPeripheral *)peripheral {
    
    if (!data) {
        return;
    }
    
    // サービス・キャラクタリスティックをたどって目的のCBCharacteristicオブジェクトを探す
    for (CBService *aService in peripheral.services) {
        
        for (CBCharacteristic *aCharacteristic in aService.characteristics) {
            
            if ([aCharacteristic.UUID isEqual:self.characteristicUUIDWrite]) {

                // ペリフェラルに情報を送る（Writeする）
                [peripheral writeValue:data
                     forCharacteristic:aCharacteristic
                                  type:CBCharacteristicWriteWithResponse];
                
                break;
            }
        }
    }
}


// =============================================================================
#pragma mark - Public



// =============================================================================
#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
    NSLog(@"Updated state: %ld", (long)central.state);
    
    switch (central.state) {
            
        case CBCentralManagerStatePoweredOn:
            
            // スキャン開始
            [self.centralManager scanForPeripheralsWithServices:nil options:nil];
            
            break;
            
        default:
            break;
    }
}

- (void)   centralManager:(CBCentralManager *)central
    didDiscoverPeripheral:(CBPeripheral *)peripheral
        advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    LOG_CURRENT_METHOD;

    NSLog(@"peripheral:%@, advertisementData:%@, RSSI:%@", peripheral, advertisementData, RSSI);

    // 配列に保持
    if (![self.peripherals containsObject:peripheral]) {
        
        [self.peripherals addObject:peripheral];
    }
    
    // 発見したペリフェラルへの接続を開始する
    [central connectPeripheral:peripheral options:nil];
}

- (void)  centralManager:(CBCentralManager *)central
    didConnectPeripheral:(CBPeripheral *)peripheral
{
    LOG_CURRENT_METHOD;
    NSLog(@"peripheral:%@", peripheral);
    
    peripheral.delegate = self;
    [peripheral discoverServices:nil];
}

- (void)        centralManager:(CBCentralManager *)central
    didFailToConnectPeripheral:(CBPeripheral *)peripheral
                         error:(NSError *)error
{
    LOG_CURRENT_METHOD;

    if (error) {
        NSLog(@"error:%@", error);
    }
    
    [self.peripherals removeObject:peripheral];
}

- (void)     centralManager:(CBCentralManager *)central
    didDisconnectPeripheral:(CBPeripheral *)peripheral
                      error:(NSError *)error
{
    LOG_CURRENT_METHOD;

    if (error) {
        NSLog(@"error:%@", error);
    }
    
    [self.peripherals removeObject:peripheral];
}


// =============================================================================
#pragma mark - CBPeripheralDelegate

// サービス発見時に呼ばれる
- (void)     peripheral:(CBPeripheral *)peripheral
    didDiscoverServices:(NSError *)error
{
    LOG_CURRENT_METHOD;
    
    if (error) {
        NSLog(@"error:%@", error);
        return;
    }
    
    if (![peripheral.services count]) {
        NSLog(@"No services are found.");
        return;
    }

    NSLog(@"services:%@", peripheral.services);
    
    // 目的のサービスを提供しているペリフェラルかどうかを判定
    BOOL hasTargetService = NO;
    for (CBService *aService in peripheral.services) {

        // 目的のサービスを提供していれば、キャラクタリスティック探索を開始する
        if ([aService.UUID isEqual:self.serviceUUID]) {
            
            [peripheral discoverCharacteristics:nil forService:aService];
            hasTargetService = YES;
            
            break;
        }
    }
    
    // 目的とするサービスを提供していないペリフェラルの参照を解放する
    if (!hasTargetService) {
        [self.peripherals removeObject:peripheral];
    }
}

// キャラクタリスティック発見時に呼ばれる
- (void)                      peripheral:(CBPeripheral *)peripheral
    didDiscoverCharacteristicsForService:(CBService *)service
                                   error:(NSError *)error
{
    LOG_CURRENT_METHOD;

    if (error) {
        NSLog(@"error:%@", error);
        return;
    }
    
    if (![service.characteristics count]) {
        NSLog(@"No characteristics are found.");
        return;
    }

    for (CBCharacteristic *aCharacteristic in service.characteristics) {
        
        if ([aCharacteristic.UUID isEqual:self.characteristicUUIDRead]) {
            
            // 現在値をRead
            [peripheral readValueForCharacteristic:aCharacteristic];
        }
    }
}

- (void)                             peripheral:(CBPeripheral *)peripheral
    didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic
                                          error:(NSError *)error
{
    LOG_CURRENT_METHOD;
    
    if (error) {
        NSLog(@"error:%@", error);
        return;
    }
}

- (void)                 peripheral:(CBPeripheral *)peripheral
    didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
                              error:(NSError *)error
{
    LOG_CURRENT_METHOD;
    
    if (error) {
        NSLog(@"error:%@", error);
        return;
    }
    
    // キャラクタリスティックの値から相手のユーザー名を取得
    NSString *username = [[NSString alloc] initWithData:characteristic.value
                                               encoding:NSUTF8StringEncoding];
    NSLog(@"peripheral:%@, username:%@", peripheral, username);
    
    // 自分のユーザー名をNSUserDefaultsから取り出す
    NSString *myUsername = [BSRUserDefaults username];

    // 相手のユーザー名が入っていて、自分のユーザー名も入力済みのときのみすれちがい処理を行う
    if ([username length] && [myUsername length]) {
        
        // 結果表示処理をViewControllerに移譲
        [self.deleagte didEncounterUserWithName:username];
        
        // 自分のユーザー名をペリフェラル側に伝える
        NSData *data = [myUsername dataUsingEncoding:NSUTF8StringEncoding];
        [self writeData:data toConnectedPeripheral:peripheral];
    }
    // 相手のユーザー名か自分のユーザー名がない
    else {
        NSLog(@"すれちがい失敗！%@, %@", username, myUsername);
        [self.centralManager cancelPeripheralConnection:peripheral];
    }
}

- (void)                peripheral:(CBPeripheral *)peripheral
    didWriteValueForCharacteristic:(CBCharacteristic *)characteristic
                             error:(NSError *)error
{
    LOG_CURRENT_METHOD;
    
    if (error) {
        NSLog(@"error:%@", error);
    }

    // 相手への情報送信が成功でも失敗でも、接続を解除する
    [self.centralManager cancelPeripheralConnection:peripheral];
}

// アプリケーション復元時に呼ばれる
- (void)centralManager:(CBCentralManager *)central
      willRestoreState:(NSDictionary *)dict
{
    // 復元された、接続を試みている、あるいは接続済みのペリフェラル
    NSArray *peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey];
    
    // プロパティに保持しなおす
    for (CBPeripheral *aPeripheral in peripherals) {
        
        if (![self.peripherals containsObject:aPeripheral]) {
            
            [self.peripherals addObject:aPeripheral];
            
            aPeripheral.delegate = self;
        }
    }    
}

@end
