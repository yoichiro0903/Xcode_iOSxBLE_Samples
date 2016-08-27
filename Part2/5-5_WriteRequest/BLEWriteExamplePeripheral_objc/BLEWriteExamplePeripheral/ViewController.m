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
@property (nonatomic, strong) CBUUID *serviceUUID;
@property (nonatomic, strong) CBMutableCharacteristic *characteristic;
@property (nonatomic, weak) IBOutlet UIButton *advertiseBtn;
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
    
    CBCharacteristicProperties properties =
    (CBCharacteristicPropertyRead | CBCharacteristicPropertyWrite);
    
    CBAttributePermissions permissions =
    (CBAttributePermissionsReadable | CBAttributePermissionsWriteable);
    
    self.characteristic =
    [[CBMutableCharacteristic alloc] initWithType:characteristicUUID
                                       properties:properties
                                            value:nil
                                      permissions:permissions];

    // キャラクタリスティックをサービスにセット
    service.characteristics = @[self.characteristic];
    
    // サービスを Peripheral Manager にセット
    [self.peripheralManager addService:service];

    // 値をセット
    Byte value = arc4random() & 0xff;
    NSData *data = [NSData dataWithBytes:&value length:1];
    self.characteristic.value = data;
}

- (void)startAdvertise {

    NSDictionary *advertisingData = @{CBAdvertisementDataLocalNameKey: @"Test Device",
                                      CBAdvertisementDataServiceUUIDsKey: @[self.serviceUUID]};
    
    [self.peripheralManager startAdvertising:advertisingData];
    
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

// Readリクエスト受信時に呼ばれる
- (void)peripheralManager:(CBPeripheralManager *)peripheral
    didReceiveReadRequest:(CBATTRequest *)request
{
    NSLog(@"Readリクエスト受信！ requested service uuid:%@ characteristic uuid:%@ value:%@",
          request.characteristic.service.UUID,
          request.characteristic.UUID,
          request.characteristic.value);
    
    // どのキャラクタリスティックへのReadリクエストかを判定
    if ([request.characteristic.UUID isEqual:self.characteristic.UUID]) {
        
        // CBCharacteristicのvalueをCBATTRequestのvalueにセット
        request.value = self.characteristic.value;
        
        // リクエストに応答
        [self.peripheralManager respondToRequest:request
                                      withResult:CBATTErrorSuccess];
    }
}

// Writeリクエスト受信時に呼ばれる
- (void)  peripheralManager:(CBPeripheralManager *)peripheral
    didReceiveWriteRequests:(NSArray *)requests
{
    NSLog(@"%lu 件のWriteリクエストを受信！", (unsigned long)[requests count]);
    for (CBATTRequest *aRequest in requests) {
        NSLog(@"Requested value:%@ service uuid:%@ characteristic uuid:%@",
              aRequest.value,
              aRequest.characteristic.service.UUID,
              aRequest.characteristic.UUID);

        if ([aRequest.characteristic.UUID isEqual:self.characteristic.UUID]) {
            
            // CBMutableCharacteristicのvalueに、CBATTRequestのvalueをセット
            self.characteristic.value = aRequest.value;
            
        }
    }
    
    // リクエストに応答
    [self.peripheralManager respondToRequest:requests[0]
                                  withResult:CBATTErrorSuccess];
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
