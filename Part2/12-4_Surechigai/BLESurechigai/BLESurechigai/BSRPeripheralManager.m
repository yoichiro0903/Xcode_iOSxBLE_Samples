//
//  BSRPeripheralManager.m
//  BLESurechigai
//
//  Created by Shuichi Tsutsumi on 2014/12/17.
//  Copyright (c) 2014年 Shuichi Tsutsumi. All rights reserved.
//

#import "BSRPeripheralManager.h"
@import CoreBluetooth;
#import "BSRConstants.h"
#import "BSRUserDefaults.h"


NSString * const kLocalName = @"Surechigai";


@interface BSRPeripheralManager () <CBPeripheralManagerDelegate>
@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
@property (nonatomic, strong) CBUUID *serviceUUID;
@property (nonatomic, strong) CBUUID *characteristicUUIDRead;
@property (nonatomic, strong) CBUUID *characteristicUUIDWrite;
@property (nonatomic, strong) CBMutableCharacteristic *characteristicRead;
@property (nonatomic, strong) CBMutableCharacteristic *characteristicWrite;
@end


@implementation BSRPeripheralManager

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
    
    NSDictionary *options =
    @{CBCentralManagerOptionShowPowerAlertKey: @YES,
      CBPeripheralManagerOptionRestoreIdentifierKey: kRestoreIdentifierKey};

    self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self
                                                                     queue:nil
                                                                   options:options];
    
    self.serviceUUID = [CBUUID UUIDWithString:kServiceUUIDEncounter];
    self.characteristicUUIDRead  = [CBUUID UUIDWithString:kCharacteristicUUIDEncounterRead];
    self.characteristicUUIDWrite = [CBUUID UUIDWithString:kCharacteristicUUIDEncounterWrite];
}



// =============================================================================
#pragma mark - Private

- (void)publishService {
    
    CBMutableService *service =
    [[CBMutableService alloc] initWithType:self.serviceUUID
                                   primary:YES];

    
    // Encounter Read キャラクタリスティックの生成
    CBCharacteristicProperties properties = (CBCharacteristicPropertyRead |
                                             CBCharacteristicPropertyNotify);
    
    CBAttributePermissions permissions = CBAttributePermissionsReadable;
    
    self.characteristicRead =
    [[CBMutableCharacteristic alloc] initWithType:self.characteristicUUIDRead
                                       properties:properties
                                            value:nil
                                      permissions:permissions];

    
    // Encounter Write キャラクタリスティックの生成
    permissions = CBAttributePermissionsWriteable;
    
    self.characteristicWrite =
    [[CBMutableCharacteristic alloc] initWithType:self.characteristicUUIDWrite
                                       properties:CBCharacteristicPropertyWrite
                                            value:nil
                                      permissions:permissions];


    service.characteristics = @[self.characteristicRead,
                                self.characteristicWrite];
    
    [self.peripheralManager addService:service];
}

- (void)startAdvertising {
    
    if ([self.peripheralManager isAdvertising]) {
        return;
    }
    
    NSDictionary *advertisementData = @{CBAdvertisementDataLocalNameKey: kLocalName,
                                        CBAdvertisementDataServiceUUIDsKey: @[self.serviceUUID]};
    
    [self.peripheralManager startAdvertising:advertisementData];
}

- (void)stopAdvertising {
    
    if ([self.peripheralManager isAdvertising]) {
        [self.peripheralManager stopAdvertising];
    }
}


// =============================================================================
#pragma mark - Public

- (void)updateUsername {
    
    if (!self.characteristicRead) {
        return;
    }
    
    // ユーザー名がまだなければ更新しない
    if (![[BSRUserDefaults username] length]) {
        return;
    }
    
    NSData *data =
    [[BSRUserDefaults username] dataUsingEncoding:NSUTF8StringEncoding];
    
    // valueを更新
    self.characteristicRead.value = data;
    
    // Notificationを発行
    BOOL result = [self.peripheralManager updateValue:data
                                    forCharacteristic:self.characteristicRead
                                 onSubscribedCentrals:nil];
    
    NSLog(@"Result for update: %@", result ? @"Succeeded" : @"Failed");
}


// =============================================================================
#pragma mark - CBPeripheralManagerDelegate

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    
    NSLog(@"Updated state:%ld", (long)peripheral.state);
    
    switch (peripheral.state) {
            
        case CBPeripheralManagerStatePoweredOn:
            
            // サービス登録
            if (!self.characteristicRead) {
                [self publishService];
            }
            
            break;
            
        default:
            break;
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral
            didAddService:(CBService *)service
                    error:(NSError *)error
{
    LOG_CURRENT_METHOD;
    
    if (error) {
        NSLog(@"error:%@", error);
        return;
    }
    
    // 現在のユーザー名を格納する
    [self updateUsername];
    
    // アドバタイズ開始
    [self startAdvertising];
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error {
    
    LOG_CURRENT_METHOD;
    
    if (error) {
        NSLog(@"error:%@", error);
        return;
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral
    didReceiveReadRequest:(CBATTRequest *)request
{
    NSLog(@"Received a read request! requested service uuid:%@ characteristic uuid:%@ value:%@",
          request.characteristic.service.UUID,
          request.characteristic.UUID,
          request.characteristic.value);
    
    // CBCharacteristicのvalueをCBATTRequestのvalueにセット
    request.value = self.characteristicRead.value;
    
    // リクエストに応答
    [self.peripheralManager respondToRequest:request
                                  withResult:CBATTErrorSuccess];
}

- (void)  peripheralManager:(CBPeripheralManager *)peripheral
    didReceiveWriteRequests:(NSArray *)requests
{
    NSLog(@"Received %lu write requests!", (unsigned long)[requests count]);
    
    for (CBATTRequest *aRequest in requests) {
        
        NSLog(@"Requested value:%@ service uuid:%@ characteristic uuid:%@",
              aRequest.value,
              aRequest.characteristic.service.UUID,
              aRequest.characteristic.UUID);
        
        // CBCharacteristicのvalueに、CBATTRequestのvalueをセット
        self.characteristicWrite.value = aRequest.value;
        
        // ViewControllerに移譲
        NSString *name = [[NSString alloc] initWithData:aRequest.value
                                               encoding:NSUTF8StringEncoding];
        [self.deleagte didEncounterUserWithName:name];
    }
    
    // リクエストに応答
    [self.peripheralManager respondToRequest:requests[0]
                                  withResult:CBATTErrorSuccess];
}

- (void)       peripheralManager:(CBPeripheralManager *)peripheral
                         central:(CBCentral *)central
    didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    LOG_CURRENT_METHOD;
}

- (void)           peripheralManager:(CBPeripheralManager *)peripheral
                             central:(CBCentral *)central
    didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
{
    LOG_CURRENT_METHOD;
}

- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral
{
    NSLog(@"peripheralManagerIsReadyToUpdateSubscribers");
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral
         willRestoreState:(NSDictionary *)dict
{
    // 復元された登録済みサービス
    NSArray *services = dict[CBPeripheralManagerRestoredStateServicesKey];
    
    // プロパティにセットしなおす
    for (CBMutableService *aService in services) {
        
        for (CBMutableCharacteristic *aCharacteristic in aService.characteristics) {
            
            if ([aCharacteristic.UUID isEqual:self.characteristicUUIDRead]) {
                
                self.characteristicRead = aCharacteristic;
            }
            else if ([aCharacteristic.UUID isEqual:self.characteristicUUIDWrite]) {
                
                self.characteristicWrite = aCharacteristic;
            }
        }
    }
}

@end
