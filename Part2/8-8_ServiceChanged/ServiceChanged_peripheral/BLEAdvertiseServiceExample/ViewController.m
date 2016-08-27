//
//  ViewController.m
//  BLESample
//
//  Created by Shuichi Tsutsumi on 10/9/14.
//  Copyright (c) 2014 Shuichi Tsutsumi. All rights reserved.
//

#import "ViewController.h"
@import CoreBluetooth;


NSString * const kServiceUUID = @"0010";

NSString * const kCharacteristicUUID1 = @"0011";
NSString * const kCharacteristicUUID2 = @"0012";


@interface ViewController ()
<CBPeripheralManagerDelegate>
{
    AdvertiseMode currentMode;
}
@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
@property (nonatomic, weak) IBOutlet UIButton *advertiseBtn;
@property (nonatomic, strong) CBUUID *serviceUUID;
@property (nonatomic, strong) CBMutableService *service;
@end


@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];

    self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self
                                                                     queue:nil
                                                                   options:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


// =============================================================================
#pragma mark - Private

- (void)publishServiceChangedService {

    // CBUUIDServiceChangedString は deprecated
    CBUUID *uuid = [CBUUID UUIDWithString:@"2A05"];
    CBMutableService *service = [[CBMutableService alloc] initWithType:uuid
                                                               primary:YES];
    NSLog(@"Service Changed service: %@", service);
    [self.peripheralManager addService:service];
}

- (void)publishServiceWithMode:(AdvertiseMode)mode {

    // サービス削除
    if (self.service) {
        [self.peripheralManager removeService:self.service];
    }

    self.serviceUUID = [CBUUID UUIDWithString:kServiceUUID];
    
    self.service = [[CBMutableService alloc] initWithType:self.serviceUUID
                                                  primary:YES];

    CBUUID *characteristicUUID;
    
    switch (mode) {
        case AdvertiseMode1:
        default:
        {
            characteristicUUID = [CBUUID UUIDWithString:kCharacteristicUUID1];
            break;
        }
        case AdvertiseMode2:
        {
            characteristicUUID = [CBUUID UUIDWithString:kCharacteristicUUID2];
            break;
        }
    }

    CBMutableCharacteristic *characteristic = [[CBMutableCharacteristic alloc] initWithType:characteristicUUID
                                                                                 properties:CBCharacteristicPropertyRead
                                                                                      value:nil
                                                                                permissions:CBAttributePermissionsReadable];

    self.service.characteristics = @[characteristic];
    [self.peripheralManager addService:self.service];
}

- (void)stopAdvertise {
    
    [self.peripheralManager stopAdvertising];
    
    [self.advertiseBtn setTitle:@"START ADVERTISING" forState:UIControlStateNormal];
}


// =============================================================================
#pragma mark - Public

- (void)startAdvertiseWithMode:(AdvertiseMode)mode {
    
    if (self.peripheralManager.isAdvertising) {
        [self.peripheralManager stopAdvertising];
    }
    
    // アドバタイズメントデータの作成
    NSDictionary *advertisingData = @{CBAdvertisementDataLocalNameKey: @"Test Device",
                                      CBAdvertisementDataServiceUUIDsKey: @[self.serviceUUID]};
    
    NSLog(@"advertisementData: %@", advertisingData);
    
    [self.peripheralManager startAdvertising:advertisingData];
    
    [self.advertiseBtn setTitle:@"STOP ADVERTISING" forState:UIControlStateNormal];
}


// =============================================================================
#pragma mark - CBPeripheralManagerDelegate

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {

    NSLog(@"peripheralManagerDidUpdateState:%ld", (long)peripheral.state);
    
    switch (peripheral.state) {
        case CBPeripheralManagerStatePoweredOn:

            // Service Changedサービス登録
            [self publishServiceChangedService];

            break;
            
        default:
            break;
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral
            didAddService:(CBService *)service
                    error:(NSError *)error
{
    if (error) {
        NSLog(@"サービス追加失敗！ error:%@", error);
        return;
    }
    
    NSLog(@"サービス追加成功！ service:%@", service);
    
    if ([service.UUID isEqual:self.serviceUUID]) {
        
        // アドバタイズ開始
        [self startAdvertiseWithMode:currentMode];
    }
}

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

        AdvertiseMode mode;
        
        switch (sender.tag) {
            case 0:
            default:
                mode = AdvertiseMode1;
                break;
            case 1:
                mode = AdvertiseMode2;
                break;
        }
        
        currentMode = mode;
        
        [self publishServiceWithMode:currentMode];
    }
    // STOP
    else {

        [self stopAdvertise];
    }
}

@end
