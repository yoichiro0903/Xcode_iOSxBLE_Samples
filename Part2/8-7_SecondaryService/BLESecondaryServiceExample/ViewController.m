//
//  ViewController.m
//  BLESample
//
//  Created by Shuichi Tsutsumi on 10/9/14.
//  Copyright (c) 2014 Shuichi Tsutsumi. All rights reserved.
//

#import "ViewController.h"
@import CoreBluetooth;


NSString * const kServiceUUIDPrimary          = @"0000";
NSString * const kServiceUUIDSecondary        = @"1000";
NSString * const kCharacteristicUUIDPrimary   = @"0001";
NSString * const kCharacteristicUUIDSecondary = @"1001";


@interface ViewController ()
<CBPeripheralManagerDelegate>
@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
@property (nonatomic, weak) IBOutlet UIButton *advertiseBtn;
@property (nonatomic, strong) CBMutableService *servicePrimary;
@property (nonatomic, strong) CBMutableService *serviceSecondary;
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

// セカンダリサービスを登録
- (void)publishSecondaryService {

    // セカンダリサービスを生成
    CBUUID *serviceUUID = [CBUUID UUIDWithString:kServiceUUIDSecondary];
    self.serviceSecondary = [[CBMutableService alloc] initWithType:serviceUUID
                                                           primary:NO];
    NSLog(@"isPrimary:%d", self.serviceSecondary.isPrimary);
    
    // セカンダリサービスのキャラクタリスティックを作成
    CBUUID *characteristicUUID =
    [CBUUID UUIDWithString:kCharacteristicUUIDSecondary];
    
    CBMutableCharacteristic *characteristic =
    [[CBMutableCharacteristic alloc] initWithType:characteristicUUID
                                       properties:CBCharacteristicPropertyRead
                                            value:nil
                                      permissions:CBAttributePermissionsReadable];
    
    // キャラクタリスティックをセカンダリサービスにセット
    self.serviceSecondary.characteristics = @[characteristic];

    // セカンダリサービスを追加
    [self.peripheralManager addService:self.serviceSecondary];
}

// プライマリサービスを登録
- (void)publishPrimaryService {

    // プライマリサービスを生成
    CBUUID *serviceUUID = [CBUUID UUIDWithString:kServiceUUIDPrimary];
    self.servicePrimary = [[CBMutableService alloc] initWithType:serviceUUID
                                                         primary:YES];
    NSLog(@"isPrimary:%d", self.servicePrimary.isPrimary);

    // プライマリサービスのキャラクタリスティックを作成
    CBUUID *characteristicUUID =
    [CBUUID UUIDWithString:kCharacteristicUUIDPrimary];
    
    CBMutableCharacteristic *characteristic =
    [[CBMutableCharacteristic alloc] initWithType:characteristicUUID
                                       properties:CBCharacteristicPropertyRead
                                            value:nil
                                      permissions:CBAttributePermissionsReadable];

    // キャラクタリスティックをプライマリサービスにセット
    self.servicePrimary.characteristics = @[characteristic];

    // セカンダリサービスへの参照を持たせる
    // [memo]この時点で、セカンダリサービスの追加（ローカルデータベースへの登録）が完了している必要がある
    self.servicePrimary.includedServices = @[self.serviceSecondary];
    
    // プライマリサービスを追加
    [self.peripheralManager addService:self.servicePrimary];
}

- (void)startAdvertise {

    // アドバタイズしたいサービスのUUIDのリスト
    NSArray *serviceUUIDs = @[[CBUUID UUIDWithString:kServiceUUIDPrimary]];
    
    // アドバタイズメントデータの作成
    NSDictionary *advertisingData = @{CBAdvertisementDataLocalNameKey: @"Test Device",
                                      CBAdvertisementDataServiceUUIDsKey: serviceUUIDs};
    
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
            [self publishSecondaryService];

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
    
    // セカンダリサービスの追加が完了してから、プライマリサービスを追加
    if ([service.UUID isEqual:self.serviceSecondary.UUID]) {
        
        [self publishPrimaryService];
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

        [self startAdvertise];
    }
    // STOP
    else {

        [self stopAdvertise];
    }
}

@end
