//
//  ViewController.m
//  ANCSClient
//
//  Created by Shuichi Tsutsumi on 2014/12/04.
//  Copyright (c) 2014年 Shuichi Tsutsumi. All rights reserved.
//

#import "ViewController.h"
@import CoreBluetooth;


static NSString * const kANCSServiceUUID = @"7905F431-B5CE-4E99-A40F-4B1E122D00D0";

static NSString * const kANCSCharacteristicUUIDNotificationSource = @"9FBF120D-6301-42D9-8C58-25E699A21DBD";
static NSString * const kANCSCharacteristicUUIDControlPoint       = @"69D1D8F3-45E1-49A8-9821-9BBDFDAAD9D9";
static NSString * const kANCSCharacteristicUUIDDataSource         = @"22EAC6E9-24D6-4BB5-BE44-B36ACE7C7BFB";


@interface ViewController ()
<CBCentralManagerDelegate, CBPeripheralDelegate>
@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheral *ncPeripheral;
@property (nonatomic, strong) CBService *ancsService;
@property (nonatomic, strong) CBCharacteristic *notificationSourceCharacteristic;
@end


@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];

    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self
                                                               queue:nil];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


// =============================================================================
#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
    LOG_CURRENT_METHOD;
}

- (void)   centralManager:(CBCentralManager *)central
    didDiscoverPeripheral:(CBPeripheral *)peripheral
        advertisementData:(NSDictionary *)advertisementData
                     RSSI:(NSNumber *)RSSI
{
    LOG_CURRENT_METHOD;
    
    NSLog(@"peripheral:%@", peripheral);
    NSString *localName = advertisementData[CBAdvertisementDataLocalNameKey];
    
    if ([localName isEqualToString:@"ANCS_NP"]) {
        
        [self.centralManager stopScan];
        
        self.ncPeripheral = peripheral;
        
        [self.centralManager connectPeripheral:peripheral options:nil];
    }
}

- (void)  centralManager:(CBCentralManager *)central
    didConnectPeripheral:(CBPeripheral *)peripheral
{
    LOG_CURRENT_METHOD;

    peripheral.delegate = self;
    [peripheral discoverServices:nil];
}


// =============================================================================
#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {

    LOG_CURRENT_METHOD;
    
    if (error) {
        NSLog(@"error:%@", error);
    }

    CBUUID *serviceUuid = [CBUUID UUIDWithString:kANCSServiceUUID];

    for (CBService *aService in peripheral.services) {
        
        if ([aService.UUID isEqualTo:serviceUuid]) {
            
            self.ancsService = aService;
            
            [peripheral discoverCharacteristics:nil
                                     forService:aService];
        }
    }
}

- (void)                      peripheral:(CBPeripheral *)peripheral
    didDiscoverCharacteristicsForService:(CBService *)service
                                   error:(NSError *)error
{
    LOG_CURRENT_METHOD;

    if (error) {
        NSLog(@"error:%@", error);
    }

    CBUUID *notificationSourceUuid =
    [CBUUID UUIDWithString:kANCSCharacteristicUUIDNotificationSource];
    
    for (CBCharacteristic *aCharacteristic in service.characteristics) {
        
        if ([aCharacteristic.UUID isEqualTo:notificationSourceUuid]) {

            self.notificationSourceCharacteristic = aCharacteristic;
            
            // Notification Source の subscribeを開始する
            [peripheral setNotifyValue:YES
                     forCharacteristic:aCharacteristic];
        }
    }
}

- (void)                             peripheral:(CBPeripheral *)peripheral
    didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic
                                          error:(NSError *)error
{
    LOG_CURRENT_METHOD;

    if (error) {
        NSLog(@"error:%@", error);
    }
}

- (void)                 peripheral:(CBPeripheral *)peripheral
    didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
                              error:(NSError *)error
{
    LOG_CURRENT_METHOD;
    
    if (error) {
        NSLog(@"error:%@", error);
    }

    NSLog(@"updated value:%@", characteristic.value);

    // 8バイト取り出す
    unsigned char bytes[8];
    [characteristic.value getBytes:bytes length:8];
    

    // Event ID
    unsigned char eventId = bytes[0];
    switch (eventId) {
        case 0:
            NSLog(@"Notification Added");
            break;
        case 1:
            NSLog(@"Notification Modified");
            break;
        case 2:
            NSLog(@"Notification Removed");
            break;
        default:
            // reserved
            break;
    }

//    unsigned char eventFlags = bytes[1];

    unsigned char categoryId = bytes[2];
    switch (categoryId) {
        case 0:
            // Other
            break;

        case 1:
            NSLog(@"Incoming Call");
            break;

        case 2:
            NSLog(@"Missed Call");
            break;

        case 3:
            NSLog(@"Voice Mail");
            break;

        case 4:
            NSLog(@"Social");
            break;

        case 5:
            NSLog(@"Schedule");
            break;

        case 6:
            NSLog(@"Email");
            break;

        case 7:
            NSLog(@"News");
            break;

        case 8:
            NSLog(@"Health and Fitness");
            break;

        case 9:
            NSLog(@"Business and Finance");
            break;

        case 10:
            NSLog(@"Location");
            break;

        case 11:
            NSLog(@"Entertainment");
            break;

        default:
            // Reserved
            break;
    }
    
    unsigned char categoryCount = bytes[3];
    NSLog(@"count:%u", categoryCount);
    
    // 残り4バイトはNotificationUID（Control Pointキャラクタリスティックに送るコマンドで使用する）
}



// =============================================================================
#pragma mark - IBAction

- (IBAction)scanBtnClicked:(id)sender {
    
    LOG_CURRENT_METHOD;
    
    [self.centralManager scanForPeripheralsWithServices:nil
                                                options:nil];
}

@end
