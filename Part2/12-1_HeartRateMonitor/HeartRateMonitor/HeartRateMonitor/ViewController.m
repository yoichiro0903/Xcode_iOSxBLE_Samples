//
//  ViewController.m
//  HeartRateMonitor
//
//  Created by Shuichi Tsutsumi on 2014/12/12.
//  Copyright (c) 2014年 Shuichi Tsutsumi. All rights reserved.
//

#import "ViewController.h"
@import CoreBluetooth;


NSString * const kServiceUUIDHeartRate = @"0x180D";
NSString * const kCharacteristicUUIDHeartRateMeasurement = @"0x2A37";


#define PULSESCALE 1.2
#define PULSEDURATION 0.2


@interface ViewController () <CBCentralManagerDelegate, CBPeripheralDelegate>
{
    uint16_t currentHeartRate;
}

// セントラルマネージャ
@property (nonatomic, strong) CBCentralManager *centralManager;

// ペリフェラル（心拍センサデバイス）
@property (nonatomic, strong) CBPeripheral *peripheral;

// HeartRateサービス
@property (nonatomic, strong) CBUUID *serviceUUID;

// HeartRateMeasurementキャラクタリスティック
@property (nonatomic, strong) CBUUID *characteristicUUID;

@property (nonatomic, assign) NSTimer *pulseTimer;
@property (nonatomic, weak) IBOutlet UIImageView *heartImageView;
@property (nonatomic, weak) IBOutlet UILabel *bpmLabel;
@end


@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self
                                                               queue:nil];

    self.serviceUUID = [CBUUID UUIDWithString:kServiceUUIDHeartRate];
    self.characteristicUUID =
    [CBUUID UUIDWithString:kCharacteristicUUIDHeartRateMeasurement];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


// =============================================================================
#pragma mark - Private

- (void)updateWithData:(NSData *)data {
    
    const uint8_t *reportData = [data bytes];
    uint16_t bpm = 0;

    // 先頭バイトの1ビット目で心拍データフォーマットを判別する
    if ((reportData[0] & 0x01) == 0) {
        
        // uint8
        bpm = reportData[1];
    }
    else {
        
        // uint16
        bpm = CFSwapInt16LittleToHost(*(uint16_t *)(&reportData[1]));
    }
    
    uint16_t oldBpm = currentHeartRate;
    currentHeartRate = bpm;
    
    // ラベルに数値表示
    self.bpmLabel.text = [NSString stringWithFormat:@"%u", currentHeartRate];

    // 心臓のアニメーション開始
    if (oldBpm == 0) {
        
        [self pulse];
    }
}

- (void)pulse {
    
    CABasicAnimation *pulseAnimation =
    [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    
    pulseAnimation.toValue = [NSNumber numberWithFloat:PULSESCALE];
    pulseAnimation.fromValue = [NSNumber numberWithFloat:1.0];
    
    pulseAnimation.duration = PULSEDURATION;
    pulseAnimation.repeatCount = 1;
    pulseAnimation.autoreverses = YES;
    pulseAnimation.timingFunction =
    [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    
    [self.heartImageView.layer addAnimation:pulseAnimation forKey:@"scale"];
    
    self.pulseTimer =
    [NSTimer scheduledTimerWithTimeInterval:(60. / currentHeartRate)
                                     target:self
                                   selector:@selector(pulse)
                                   userInfo:nil repeats:NO];
}


// =============================================================================
#pragma mark - CBCentralManagerDelegate

// セントラルマネージャの状態が変化すると呼ばれる
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
    NSLog(@"Updated state: %ld", central.state);
    
    switch (central.state) {
            
        case CBCentralManagerStatePoweredOn:
        {
            // スキャン開始
            NSArray *services = @[self.serviceUUID];
            [self.centralManager scanForPeripheralsWithServices:services
                                                        options:nil];
            
            break;
        }
        default:
            break;
    }
}

// ペリフェラルを発見すると呼ばれる
- (void)   centralManager:(CBCentralManager *)central
    didDiscoverPeripheral:(CBPeripheral *)peripheral
        advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSLog(@"peripheral:%@, advertisementData:%@, RSSI:%@",
          peripheral, advertisementData, RSSI);
    
    self.peripheral = peripheral;
    
    // スキャン停止
    [self.centralManager stopScan];
    
    // 接続開始
    [central connectPeripheral:peripheral options:nil];
}

// 接続成功すると呼ばれる
- (void)  centralManager:(CBCentralManager *)central
    didConnectPeripheral:(CBPeripheral *)peripheral
{
    LOG_CURRENT_METHOD;
    
    self.peripheral.delegate = self;
    
    // サービス探索開始
    [self.peripheral discoverServices:@[self.serviceUUID]];
}

// 接続失敗すると呼ばれる
- (void)        centralManager:(CBCentralManager *)central
    didFailToConnectPeripheral:(CBPeripheral *)peripheral
                         error:(NSError *)error
{
    LOG_CURRENT_METHOD;
    
    if (error) {
        NSLog(@"error:%@", error);
    }
    
    self.peripheral = nil;
}

// 接続が切断されると呼ばれる
- (void)     centralManager:(CBCentralManager *)central
    didDisconnectPeripheral:(CBPeripheral *)peripheral
                      error:(NSError *)error
{
    LOG_CURRENT_METHOD;

    if (error) {
        NSLog(@"error:%@", error);
    }
    
    self.peripheral = nil;
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
    
    // キャラクタリスティック探索開始
    [peripheral discoverCharacteristics:@[self.characteristicUUID]
                             forService:[peripheral.services firstObject]];
}

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

    // Notifyを開始する
    [peripheral setNotifyValue:YES
             forCharacteristic:[service.characteristics firstObject]];
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
    if (error) {
        NSLog(@"error:%@", error);
        return;
    }
    
    // データを処理する
    [self updateWithData:characteristic.value];
}

@end
