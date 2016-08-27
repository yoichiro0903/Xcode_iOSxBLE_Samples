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
@property (nonatomic, strong) NSMutableArray *peripherals;
@property (nonatomic, strong) dispatch_queue_t centralQueue;
@end


@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];

    self.peripherals = @[].mutableCopy;
    
    
    // セントラルのイベントをディスパッチするキューの作成
    self.centralQueue =
    dispatch_queue_create("com.shu223.BLEExample", DISPATCH_QUEUE_SERIAL);

    // キューを指定してセントラルマネージャを初期化
    self.centralManager =
    [[CBCentralManager alloc] initWithDelegate:self
                                         queue:self.centralQueue];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


// =============================================================================
#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {

    // 特に何もしない
    NSLog(@"centralManagerDidUpdateState:%ld", (long)central.state);

    const char *label = dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL);
    NSLog(@"実行キュー: %s", label);
}

- (void)   centralManager:(CBCentralManager *)central
    didDiscoverPeripheral:(CBPeripheral *)peripheral
        advertisementData:(NSDictionary *)advertisementData
                     RSSI:(NSNumber *)RSSI
{
    NSLog(@"発見したBLEデバイス：%@", peripheral);

    const char *label = dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL);
    NSLog(@"実行キュー: %s", label);

    [self.peripherals addObject:peripheral];
    
    [self.centralManager connectPeripheral:peripheral
                                   options:nil];
}

- (void)  centralManager:(CBCentralManager *)central
    didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"接続成功！:%@", peripheral);

    const char *label = dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL);
    NSLog(@"実行キュー: %s", label);

    peripheral.delegate = self;
    
    // サービス探索開始
    [peripheral discoverServices:nil];
}

- (void)        centralManager:(CBCentralManager *)central
    didFailToConnectPeripheral:(CBPeripheral *)peripheral
                         error:(NSError *)error
{
    NSLog(@"接続失敗・・・");

    const char *label = dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL);
    NSLog(@"実行キュー: %s", label);
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
    
    const char *label = dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL);
    NSLog(@"実行キュー: %s", label);

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

    const char *label = dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL);
    NSLog(@"実行キュー: %s", label);
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
