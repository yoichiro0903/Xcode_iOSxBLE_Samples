//
//  ViewController.m
//  ActivityMonitorPeripheral
//
//  Created by Shuichi Tsutsumi on 2014/12/13.
//  Copyright (c) 2014年 Shuichi Tsutsumi. All rights reserved.
//

#import "ViewController.h"
@import CoreBluetooth;
@import CoreMotion;


NSString * const kLocalName         = @"Activity";
NSString * const kSUUIDActivity     = @"D85DA530-B707-41AE-B1D3-BA33A9A67DD8";
NSString * const kCUUIDActivityData = @"2CE9E5C4-8B42-4567-9547-6F3A21D23F0D";


@interface ViewController () <CBPeripheralManagerDelegate>
@property (nonatomic, weak) IBOutlet UILabel *statusLabel;
@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
@property (nonatomic, strong) CBUUID *serviceUUID;
@property (nonatomic, strong) CBUUID *characteristicUUID;
@property (nonatomic, strong) CBMutableCharacteristic *characteristic;
@property (nonatomic, strong) CMPedometer *pedometer;
@end


@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self
                                                                     queue:nil];
    
    self.serviceUUID        = [CBUUID UUIDWithString:kSUUIDActivity];
    self.characteristicUUID = [CBUUID UUIDWithString:kCUUIDActivityData];

    if ([CMPedometer isStepCountingAvailable] && [CMPedometer isDistanceAvailable]) {
        
        self.pedometer = [[CMPedometer alloc] init];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


// =============================================================================
#pragma mark - Private

- (void)publishService {
    
    LOG_CURRENT_METHOD;
    
    CBMutableService *service =
    [[CBMutableService alloc] initWithType:self.serviceUUID
                                   primary:YES];

    self.characteristic =
    [[CBMutableCharacteristic alloc] initWithType:self.characteristicUUID
                                       properties:CBCharacteristicPropertyNotify
                                            value:nil
                                      permissions:CBAttributePermissionsReadable];
    
    service.characteristics = @[self.characteristic];
    
    [self.peripheralManager addService:service];
}

- (void)startAdvertising {

    LOG_CURRENT_METHOD;

    // アドバタイズメントデータを作成する
    NSDictionary *advertisementData =
    @{CBAdvertisementDataLocalNameKey: kLocalName,
      CBAdvertisementDataServiceUUIDsKey: @[self.serviceUUID]};

    // アドバタイズ開始
    [self.peripheralManager startAdvertising:advertisementData];
}

- (void)startPedometer {

    LOG_CURRENT_METHOD;
    
    // 歩行活動データの更新開始
    [self.pedometer startPedometerUpdatesFromDate:[NSDate date]
                                      withHandler:
     ^(CMPedometerData *pedometerData, NSError *error) {
         
         // 歩行活動データを処理する
         [self updateValueWithPedometerData:pedometerData];
     }];

    self.statusLabel.text = @"歩行活動データ取得中";
}

- (void)updateValueWithPedometerData:(CMPedometerData *)pedometerData {
    
    LOG_CURRENT_METHOD;
    
    // 歩数、距離を取り出す
    UInt64 numberOfSteps = [pedometerData.numberOfSteps unsignedIntegerValue];
    UInt64 distance      = [pedometerData.distance doubleValue];
    
    // 先頭8バイトに歩数、次の8バイトに距離を格納したNSDataオブジェクトを生成する
    NSMutableData *data = [NSMutableData dataWithLength:0];
    [data appendBytes:&numberOfSteps length:sizeof(numberOfSteps)];
    [data appendBytes:&distance length:sizeof(distance)];
    NSLog(@"pedometerData:%@, data:%@", pedometerData, data);

    // Activityキャラクタリスティックの値を更新する
    self.characteristic.value = data;
    BOOL result = [self.peripheralManager updateValue:data
                                    forCharacteristic:self.characteristic
                                 onSubscribedCentrals:nil];
    
    NSLog(@"Result for update: %@", result ? @"Succeeded" : @"Failed");
}


// =============================================================================
#pragma mark - CBPeripheralManagerDelegate

// ペリフェラルマネージャの状態が変化すると呼ばれる
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    
    NSLog(@"Updated state:%ld", (long)peripheral.state);
    
    switch (peripheral.state) {
        case CBPeripheralManagerStatePoweredOn:
            
            // サービス登録
            [self publishService];
            break;
            
        default:
            break;
    }
}

// サービス登録が完了すると呼ばれる
- (void)peripheralManager:(CBPeripheralManager *)peripheral
            didAddService:(CBService *)service
                    error:(NSError *)error
{
    LOG_CURRENT_METHOD;
    
    if (error) {
        NSLog(@"error:%@", error);
        return;
    }
    
    self.statusLabel.text = @"サービス登録成功";
    
    // アドバタイズ開始
    [self startAdvertising];
}

// アドバタイズ開始処理が完了すると呼ばれる
- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral
                                       error:(NSError *)error
{
    if (error) {
        NSLog(@"error:%@", error);
        return;
    }
    
    self.statusLabel.text = @"アドバタイズ開始成功";

    // 活動量の計測開始
    [self startPedometer];
}

// Notify開始リクエスト受信時に呼ばれる
- (void)       peripheralManager:(CBPeripheralManager *)peripheral
                         central:(CBCentral *)central
    didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    LOG_CURRENT_METHOD;
}

// Notify停止リクエスト受信時に呼ばれる
- (void)           peripheralManager:(CBPeripheralManager *)peripheral
                             central:(CBCentral *)central
    didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
{
    LOG_CURRENT_METHOD;
}

- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral {
    
    NSLog(@"peripheralManagerIsReadyToUpdateSubscribers");
}

@end
