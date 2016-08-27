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
<CBPeripheralManagerDelegate>
@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
@property (nonatomic, weak) IBOutlet UIButton *advertiseBtn;
@property (nonatomic, strong) CBUUID *serviceUUID;
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

- (void)publishService {

    // サービスを作成
    self.serviceUUID = [CBUUID UUIDWithString:@"0000"];
    CBMutableService *service = [[CBMutableService alloc] initWithType:self.serviceUUID
                                                               primary:YES];
    // キャラクタリスティックを作成
    CBUUID *characteristicUUID = [CBUUID UUIDWithString:@"0001"];
    
    CBCharacteristicProperties properties = (
                                             CBCharacteristicPropertyNotify |
                                             CBCharacteristicPropertyRead |
                                             CBCharacteristicPropertyWrite
                                             );
    CBAttributePermissions permissions = (CBAttributePermissionsReadable | CBAttributePermissionsWriteable);
    CBMutableCharacteristic *characteristic = [[CBMutableCharacteristic alloc] initWithType:characteristicUUID
                                                                                 properties:properties
                                                                                      value:nil
                                                                                permissions:permissions];
    // キャラクタリスティックをサービスにセット
    service.characteristics = @[characteristic];
    
    // サービスを Peripheral Manager にセット
    [self.peripheralManager addService:service];
}

- (void)startAdvertise {

    // アドバタイズしたいサービスのUUIDのリスト
    NSArray *serviceUUIDs = @[self.serviceUUID];
    
    // アドバタイズメントデータの作成
    NSDictionary *advertisementData =
    @{CBAdvertisementDataLocalNameKey: @"Test Device",
      CBAdvertisementDataServiceUUIDsKey: serviceUUIDs};
    
    [self.peripheralManager startAdvertising:advertisementData];
    
    [self.advertiseBtn setTitle:@"STOP ADVERTISING" forState:UIControlStateNormal];
}

- (void)stopAdvertise {

    [self.peripheralManager stopAdvertising];
    
    [self.advertiseBtn setTitle:@"START ADVERTISING" forState:UIControlStateNormal];
}


// =============================================================================
#pragma mark - CBPeripheralManagerDelegate

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {

    NSLog(@"peripheralManagerDidUpdateState:%ld", (long)peripheral.state);
    
    switch (peripheral.state) {
        case CBPeripheralManagerStatePoweredOn:

            // サービス登録
            [self publishService];

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

    // アドバタイズ開始
    [self startAdvertise];
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

        [self startAdvertise];
    }
    // STOP
    else {

        [self stopAdvertise];
    }
}

@end
