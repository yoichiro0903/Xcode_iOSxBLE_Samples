//
//  ViewController.m
//  BLESample
//
//  Created by Shuichi Tsutsumi on 10/9/14.
//  Copyright (c) 2014 Shuichi Tsutsumi. All rights reserved.
//

#import "ViewController.h"
@import CoreBluetooth;


NSString * const kServiceUUID = @"1111";
NSString * const kCharacteristicUUID = @"1112";


@interface ViewController ()
<CBPeripheralManagerDelegate>
@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
@property (nonatomic, strong) CBUUID *serviceUUID;
@property (nonatomic, strong) CBUUID *characteristicUUID;
@property (nonatomic, strong) CBMutableCharacteristic *characteristic;
@property (nonatomic, weak) IBOutlet UIButton *advertiseBtn;
@end


@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];

    NSDictionary *options = @{CBPeripheralManagerOptionRestoreIdentifierKey: @"myRestoreIdentifierKey"};
    
    self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self
                                                                     queue:nil
                                                                   options:options];

    self.serviceUUID = [CBUUID UUIDWithString:kServiceUUID];
    self.characteristicUUID = [CBUUID UUIDWithString:kCharacteristicUUID];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


// =============================================================================
#pragma mark - Private

- (void)publishService {
    
    // サービスを作成
    CBMutableService *service = [[CBMutableService alloc] initWithType:self.serviceUUID
                                                               primary:YES];
    // キャラクタリスティックを作成
    CBCharacteristicProperties properties = (
                                             CBCharacteristicPropertyNotify |
                                             CBCharacteristicPropertyRead |
                                             CBCharacteristicPropertyWrite
                                             );
    CBAttributePermissions permissions = (CBAttributePermissionsReadable | CBAttributePermissionsWriteable);
    
    self.characteristic = [[CBMutableCharacteristic alloc] initWithType:self.characteristicUUID
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

    // アドバタイズメントデータを作成する
    NSDictionary *advertisingData = @{CBAdvertisementDataLocalNameKey: @"Test Device",
                                      CBAdvertisementDataServiceUUIDsKey: @[self.serviceUUID]};
    
    // アドバタイズ開始
    [self.peripheralManager startAdvertising:advertisingData];
    
    [self.advertiseBtn setTitle:@"STOP ADVERTISING" forState:UIControlStateNormal];
}

- (void)stopAdvertise {

    [self.peripheralManager stopAdvertising];
    
    [self.advertiseBtn setTitle:@"START ADVERTISING" forState:UIControlStateNormal];
}

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
#pragma mark - CBPeripheralManagerDelegate

// ペリフェラルマネージャの状態が変化すると呼ばれる
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {

    NSString *msg = [NSString stringWithFormat:@"peripheralManagerDidUpdateState:%ld", (long)peripheral.state];
    
    NSLog(@"%@", msg);
    
    switch (peripheral.state) {
        case CBPeripheralManagerStatePoweredOn:

            // 二重にサービス追加しようとするとエラーになる
            // 既にプロパティにオブジェクトがセットされていれば復元により再度ペリフェラルマネージャが初期化されたものと判断し、サービス登録はしない
            if (!self.characteristic) {
                
                // サービス登録
                [self publishService];
            }

            break;
            
        default:
            break;
    }
    
    [self publishLocalNotificationWithMessage:msg];
}

// サービス登録が完了すると呼ばれる
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

// アドバタイズ開始処理が完了すると呼ばれる
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
    NSString *msg = [NSString stringWithFormat:@"Readリクエスト受信！ service uuid:%@ characteristic uuid:%@ value:%@",
                     request.characteristic.service.UUID,
                     request.characteristic.UUID,
                     request.characteristic.value];
    NSLog(@"%@", msg);
    
    if (self.peripheralManager.state != CBPeripheralManagerStatePoweredOn) {
        NSLog(@"not powered on");
        return;
    }

    // どのキャラクタリスティックへのReadリクエストかを判定
    if ([request.characteristic.UUID isEqual:self.characteristic.UUID]) {
        
        // CBCharacteristicのvalueをCBATTRequestのvalueにセット
        request.value = self.characteristic.value;
        
        // リクエストに応答
        [self.peripheralManager respondToRequest:request
                                      withResult:CBATTErrorSuccess];
    }
    
    [self publishLocalNotificationWithMessage:msg];
}

// Writeリクエスト受信時に呼ばれる
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests {
    
    NSString *msg = [NSString stringWithFormat:@"%lu 件のWriteリクエストを受信！",
                     (unsigned long)[requests count]];
    NSLog(@"%@", msg);
    
    for (CBATTRequest *aRequest in requests) {
        NSLog(@"Requested value:%@ service uuid:%@ characteristic uuid:%@",
              aRequest.value,
              aRequest.characteristic.service.UUID,
              aRequest.characteristic.UUID);
        
        if ([aRequest.characteristic.UUID isEqual:self.characteristic.UUID]) {
            
            // CBCharacteristicのvalueに、CBATTRequestのvalueをセット
            self.characteristic.value = aRequest.value;
        }
    }
    
    // リクエストに応答
    [self.peripheralManager respondToRequest:requests[0]
                                  withResult:CBATTErrorSuccess];
    
    // 更新を通知する
    [self.peripheralManager updateValue:self.characteristic.value
                      forCharacteristic:self.characteristic
                   onSubscribedCentrals:nil];

    [self publishLocalNotificationWithMessage:msg];
}

// Notify開始リクエスト受信時に呼ばれる
- (void)       peripheralManager:(CBPeripheralManager *)peripheral
                         central:(CBCentral *)central
    didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    NSString *msg = @"Notify開始リクエストを受信";
    NSLog(@"%@", msg);
    
    [self publishLocalNotificationWithMessage:msg];
}

// Notify停止リクエスト受信時に呼ばれる
- (void)           peripheralManager:(CBPeripheralManager *)peripheral
                             central:(CBCentral *)central
    didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"Notify停止リクエストを受信");
}

// 復元時に呼ばれる
- (void)peripheralManager:(CBPeripheralManager *)peripheral
         willRestoreState:(NSDictionary *)dict
{
    NSString *msg = [NSString stringWithFormat:@"ペリフェラル復元：%@", dict];

    NSLog(@"%@", msg);
    
    [self publishLocalNotificationWithMessage:msg];


    // ペリフェラルマネージャを見てみる
    NSLog(@"peripheralManager: %@, isAdvertising: %d, delegate: %@",
          self.peripheralManager, self.peripheralManager.isAdvertising, self.peripheralManager.delegate);
    
    // コンソール出力結果: peripheralManager: <CBPeripheralManager: 0x1700cc6a0>, isAdvertising: 1
    // → アドバタイズ状態まで復元されていることがわかる

    // プロパティを見てみる
    NSLog(@"characteristic: %@", self.characteristic);
    
    // コンソール出力結果: characteristic: (null)
    // → プロパティまでは復元されない。peripheralManagerはアプリをバックグラウンド状態にする際の処理で初期化されるため。
    
    
    // 復元された登録済みサービス
    NSArray *services = dict[CBPeripheralManagerRestoredStateServicesKey];
    
    // サービス・キャラクタリスティックの状態を見てみる＆プロパティにセットしなおす
    for (CBMutableService *aService in services) {

        if ([aService.UUID isEqual:self.serviceUUID]) {
            
            NSLog(@"service: %@", aService);
            
            /* コンソール出力結果:
             service: <CBMutableService: 0x17008d610 Primary = YES, UUID = 1111, Included Services = (null), Characteristics = (
             "<CBMutableCharacteristic: 0x1700d3160 UUID = 1112, Value = <>, Properties = 0x0, Permissions = 0x3, Descriptors = (null), SubscribedCentrals = (\n    \"<CBCentral: 0x17007c7c0 identifier = 94F924E5-7187-1467-2D9F-9255E1ADBD78, MTU = 155>\"\n)>"
             )>
             */
            // → キャラクタリスティックをサブスクライブしているペリフェラルのリストまで復元されていることがわかる
        }
        
        NSArray *characteristics = aService.characteristics;
        
        for (CBMutableCharacteristic *aCharacteristic in characteristics) {

            if ([aCharacteristic.UUID isEqual:self.characteristicUUID]) {

                // プロパティにセットし直す
                self.characteristic = aCharacteristic;
            }
        }
    }
    
//    NSDictionary *advertisementData = dict[CBPeripheralManagerRestoredStateAdvertisementDataKey];
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

- (IBAction)updateBtnTapped:(id)sender {

    // 新しい値となるNSDataオブジェクトを生成
    Byte value = arc4random() & 0xff;
    NSData *data = [NSData dataWithBytes:&value length:1];

    // 値を更新する
    self.characteristic.value = data;
    
    // 更新を通知する
    BOOL result = [self.peripheralManager updateValue:data
                                    forCharacteristic:self.characteristic
                                 onSubscribedCentrals:nil];

    NSLog(@"%@", result ? @"通知成功！" : @"通知失敗");
}

@end
