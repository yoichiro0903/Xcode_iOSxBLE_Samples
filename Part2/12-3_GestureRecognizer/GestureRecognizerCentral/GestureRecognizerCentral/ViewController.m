//
//  ViewController.m
//  GestureRecognizerCentral
//
//  Created by Shuichi Tsutsumi on 2014/12/13.
//  Copyright (c) 2014年 Shuichi Tsutsumi. All rights reserved.
//

#import "ViewController.h"
@import CoreBluetooth;
@import AVFoundation;
#import "SensorHelper.h"


#define kThreshold 1.0


NSString * const kLocalName = @"SensorTag";
NSString * const kServiceUUIDAccelerometer = @"F000AA10-0451-4000-B000-000000000000";
NSString * const kCharUUIDAccData   = @"F000AA11-0451-4000-B000-000000000000";
NSString * const kCharUUIDAccConfig = @"F000AA12-0451-4000-B000-000000000000";
NSString * const kCharUUIDAccPeriod = @"F000AA13-0451-4000-B000-000000000000";


@interface ViewController () <CBCentralManagerDelegate, CBPeripheralDelegate>
{
    float prevX, prevY, prevZ;
}
@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, strong) CBUUID *serviceUUID;
@property (nonatomic, strong) CBUUID *characteristicUUIDData;
@property (nonatomic, strong) CBUUID *characteristicUUIDConfig;
@property (nonatomic, strong) CBUUID *characteristicUUIDPeriod;
@property (nonatomic, strong) AVAudioPlayer *player;
@end


@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self
                                                               queue:nil];
    
    self.serviceUUID = [CBUUID UUIDWithString:kServiceUUIDAccelerometer];
    self.characteristicUUIDData   = [CBUUID UUIDWithString:kCharUUIDAccData];
    self.characteristicUUIDConfig = [CBUUID UUIDWithString:kCharUUIDAccConfig];
    self.characteristicUUIDPeriod = [CBUUID UUIDWithString:kCharUUIDAccPeriod];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"swing"
                                                     ofType:@"wav"];
    NSURL *url = [NSURL fileURLWithPath:path];
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:url
                                                         error:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


// =============================================================================
#pragma mark - Private

- (void)updateWithData:(NSData *)data {
    
    // 生データを変換する
    float x = [SensorHelper calcXValue:data];
    float y = [SensorHelper calcYValue:data];
    float z = [SensorHelper calcZValue:data];

    // 前回の値との差分が一定以上であれば、音を鳴らす
    if (fabs(prevX - x) >= kThreshold ||
        fabs(prevY - y) >= kThreshold ||
        fabs(prevZ - z) >= kThreshold)
    {
        // 再生
        [self.player play];
    }
    
    prevX = x;
    prevY = y;
    prevZ = z;
    
//    NSLog(@"x:%f, y:%f, z:%f", x, y, z);
}


// =============================================================================
#pragma mark - Public

- (void)startScan {
    
    LOG_CURRENT_METHOD;
    [self.centralManager scanForPeripheralsWithServices:nil options:nil];
}


// =============================================================================
#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
    NSLog(@"Updated state: %ld", central.state);
    
    switch (central.state) {
            
        case CBCentralManagerStatePoweredOn:
            
            // スキャン開始
            [self startScan];
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
    
    NSString *localName = advertisementData[CBAdvertisementDataLocalNameKey];
    
    // ローカル名がSensorTagのものであれば接続
    if ([localName isEqualToString:kLocalName]) {
        
        self.peripheral = peripheral;
        
        [central connectPeripheral:peripheral options:nil];
    }
}

- (void)  centralManager:(CBCentralManager *)central
    didConnectPeripheral:(CBPeripheral *)peripheral
{
    LOG_CURRENT_METHOD;
    
    self.peripheral.delegate = self;
    [self.peripheral discoverServices:@[self.serviceUUID]];
}

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
    
    // キャラクタリスティックの探索を開始
    NSArray *characteristics = @[self.characteristicUUIDData,
                                 self.characteristicUUIDConfig,
                                 self.characteristicUUIDPeriod];
    [peripheral discoverCharacteristics:characteristics
                             forService:[peripheral.services firstObject]];
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
        
        // 加速度データの取得間隔
        if ([aCharacteristic.UUID isEqual:self.characteristicUUIDPeriod]) {
            
            // Period = [Input*10] ms なので、100msに1回の更新になる
            uint8_t periodData = (uint8_t)10;
            
            // Periodキャラクタリスティックへ書き込む
            [peripheral writeValue:[NSData dataWithBytes:&periodData length:1]
                 forCharacteristic:aCharacteristic
                              type:CBCharacteristicWriteWithResponse];
        }
        // 加速度センサの設定
        else if ([aCharacteristic.UUID isEqual:self.characteristicUUIDConfig]) {
            
            // レンジ2Gでセンサを有効にする
            uint8_t configData = 0x01;
            
            // Configurationキャラクタリスティックへ書き込む
            [peripheral writeValue:[NSData dataWithBytes:&configData length:1]
                 forCharacteristic:aCharacteristic
                              type:CBCharacteristicWriteWithResponse];
        }
        // Notify開始
        else if ([aCharacteristic.UUID isEqual:self.characteristicUUIDData]) {
            
            [peripheral setNotifyValue:YES forCharacteristic:aCharacteristic];
        }
    }
}

- (void)                peripheral:(CBPeripheral *)peripheral
    didWriteValueForCharacteristic:(CBCharacteristic *)characteristic
                             error:(NSError *)error
{
    LOG_CURRENT_METHOD;
    
    NSLog(@"characteristic:%@", characteristic);

    if (error) {
        NSLog(@"error:%@", error);
        return;
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
    if (error) {
        NSLog(@"error:%@", error);
        return;
    }
    
    [self updateWithData:characteristic.value];
}

@end
