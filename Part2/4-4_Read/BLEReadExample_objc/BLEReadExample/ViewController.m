//
//  ViewController.m
//  BLESample
//
//  Created by Shuichi Tsutsumi on 10/9/14.
//  Copyright (c) 2014 Shuichi Tsutsumi. All rights reserved.
//

#import "ViewController.h"
@import CoreBluetooth;


@interface ViewController () <CBCentralManagerDelegate, CBPeripheralDelegate>
{
    BOOL isScanning;
}
@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheral *peripheral;
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

// セントラルマネージャの状態が変化すると呼ばれる
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {

    // 特に何もしない
    NSLog(@"centralManagerDidUpdateState:%ld", (long)central.state);
}

// ペリフェラルを発見すると呼ばれる
- (void)   centralManager:(CBCentralManager *)central
    didDiscoverPeripheral:(CBPeripheral *)peripheral
        advertisementData:(NSDictionary *)advertisementData
                     RSSI:(NSNumber *)RSSI
{
    NSLog(@"発見したペリフェラル：%@", peripheral);

    if ([peripheral.name hasPrefix:@"konashi"]) {
        
        // 接続開始
        self.peripheral = peripheral;
        [self.centralManager connectPeripheral:peripheral
                                       options:nil];
    }
}

- (void)  centralManager:(CBCentralManager *)central
    didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"接続成功！");

    // サービス探索結果を受け取るためにデリゲートをセット
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
        
        // Readのビットが立っているすべてのキャラクタリスティックに対して読み出し開始
//        if ((characteristic.properties & CBCharacteristicPropertyRead) != 0) {
//            
//            [peripheral readValueForCharacteristic:characteristic];
//        }
//        else {
//            NSLog(@"Readプロパティなし:%@", characteristic.UUID);
//        }

        // Read専用のキャラクタリスティックに限定して読み出す場合
        if (characteristic.properties == CBCharacteristicPropertyRead) {
            
            [peripheral readValueForCharacteristic:characteristic];
        }
    }
}

// データ読み出しが完了すると呼ばれる
- (void)                 peripheral:(CBPeripheral *)peripheral
    didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
                              error:(NSError *)error
{
    if (error) {
        NSLog(@"読み出し失敗...error:%@, characteristic uuid:%@", error, characteristic.UUID);
        return;
    }
    
    NSLog(@"読み出し成功！service uuid:%@, characteristice uuid:%@, value%@",
          characteristic.service.UUID, characteristic.UUID, characteristic.value);

    // バッテリーレベルのキャラクタリスティックかどうかを判定
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2A19"]]) {
        
        unsigned char byte;
        
        // 1バイト取り出す
        [characteristic.value getBytes:&byte length:1];
        
        NSLog(@"Battery Level: %d", byte);
    }
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

@end
