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
<CBCentralManagerDelegate, CBPeripheralDelegate>
{
    BOOL isScanning;
}
@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheral *peripheral;

// #define KONASHI_PIO_SETTING_UUID [CBUUID UUIDWithString: @"3000"]
@property (nonatomic, strong) CBCharacteristic *settingCharacteristic;
// #define KONASHI_PIO_OUTPUT_UUID [CBUUID UUIDWithString: @"3002"]
@property (nonatomic, strong) CBCharacteristic *outputCharacteristic;
@end


@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];

    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self
                                                               queue:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


// =============================================================================
#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {

    // 特に何もしない
    NSLog(@"centralManagerDidUpdateState:%ld", (long)central.state);
}

- (void)   centralManager:(CBCentralManager *)central
    didDiscoverPeripheral:(CBPeripheral *)peripheral
        advertisementData:(NSDictionary *)advertisementData
                     RSSI:(NSNumber *)RSSI
{
    NSLog(@"発見したBLEデバイス：%@", peripheral);

    if ([peripheral.name hasPrefix:@"konashi"]) {
        
        self.peripheral = peripheral;
        
        // 接続開始
        [self.centralManager connectPeripheral:peripheral
                                       options:nil];
    }
}

- (void)  centralManager:(CBCentralManager *)central
    didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"接続成功！");

    peripheral.delegate = self;

    // サービス探索開始
    [peripheral discoverServices:nil];
}

- (void)        centralManager:(CBCentralManager *)central
    didFailToConnectPeripheral:(CBPeripheral *)peripheral
                         error:(NSError *)error
{
    NSLog(@"接続失敗・・・");
}


// =============================================================================
#pragma mark - CBPeripheralDelegate

// サービス発見時に呼ばれる
- (void)     peripheral:(CBPeripheral *)peripheral
    didDiscoverServices:(NSError *)error
{
    if (error) {
        NSLog(@"エラー:%@", error);
        return;
    }
    
    NSArray *services = peripheral.services;
    NSLog(@"%lu 個のサービスを発見！:%@", (unsigned long)services.count, services);

    for (CBService *service in services) {
        
        // キャラクタリスティック探索開始
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

// キャラクタリスティック発見時に呼ばれる
- (void)                      peripheral:(CBPeripheral *)peripheral
    didDiscoverCharacteristicsForService:(CBService *)service
                                   error:(NSError *)error
{
    if (error) {
        NSLog(@"エラー:%@", error);
        return;
    }
    
    NSArray *characteristics = service.characteristics;
    NSLog(@"%lu 個のキャラクタリスティックを発見！%@", (unsigned long)characteristics.count, characteristics);

    for (CBCharacteristic *characteristic in characteristics) {
        
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"3000"]]) {
            self.settingCharacteristic = characteristic;
            NSLog(@"KONASHI_PIO_SETTING_UUID を発見！");
        }
        else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"3002"]]) {
            self.outputCharacteristic = characteristic;
            NSLog(@"KONASHI_PIO_OUTPUT_UUID を発見！");
        }
    }
}


// データ書き込みが完了すると呼ばれる
- (void)                peripheral:(CBPeripheral *)peripheral
    didWriteValueForCharacteristic:(CBCharacteristic *)characteristic
                             error:(NSError *)error
{
    if (error) {
        NSLog(@"Write失敗...error:%@", error);
        return;
    }
    
    NSLog(@"Write成功！");
}


// =============================================================================
#pragma mark - IBAction

- (IBAction)scanBtnTapped:(UIButton *)sender {

    if (!isScanning) {

        isScanning = YES;
        
        // スキャン開始
        [self.centralManager scanForPeripheralsWithServices:nil
                                                    options:nil];
        [sender setTitle:@"STOP SCAN" forState:UIControlStateNormal];
    }
    else {
        
        // スキャン停止
        [self.centralManager stopScan];
        [sender setTitle:@"START SCAN" forState:UIControlStateNormal];
        isScanning = NO;
    }
}

- (IBAction)ledBtnTapped:(id)sender {

    if (!(self.settingCharacteristic && self.outputCharacteristic)) {
        NSLog(@"Konashi is not ready!");
        return;
    }

    // LED2を光らせる
    
    // 書き込みデータ生成（LED2）
    unsigned char value = 0x01 << 1;
    NSData *data = [[NSData alloc] initWithBytes:&value length:1];
    
    // konashi の pinMode:mode: で LED2 のモードを OUTPUT にすることに相当
    [self.peripheral writeValue:data
              forCharacteristic:self.settingCharacteristic
                           type:CBCharacteristicWriteWithoutResponse];
    
    // konashiの digitalWrite:value: で LED2 を HIGH にすることに相当
    [self.peripheral writeValue:data
              forCharacteristic:self.outputCharacteristic
                           type:CBCharacteristicWriteWithoutResponse];
}

@end
