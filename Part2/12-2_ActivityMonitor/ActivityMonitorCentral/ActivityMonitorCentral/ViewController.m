//
//  ViewController.m
//  ActivityMonitorCentral
//
//  Created by Shuichi Tsutsumi on 2014/12/13.
//  Copyright (c) 2014年 Shuichi Tsutsumi. All rights reserved.
//

#import "ViewController.h"
@import CoreBluetooth;
#import "JBLineChartView.h"
#import "SVProgressHUD.h"


#define kNumberOfPoints 20


NSString * const kSUUIDActivity     = @"D85DA530-B707-41AE-B1D3-BA33A9A67DD8";
NSString * const kCUUIDActivityData = @"2CE9E5C4-8B42-4567-9547-6F3A21D23F0D";


@interface ViewController ()
<CBCentralManagerDelegate, CBPeripheralDelegate, JBLineChartViewDelegate, JBLineChartViewDataSource>

@property (nonatomic, strong) CBCentralManager *centralManager; // セントラルマネージャ
@property (nonatomic, strong) CBPeripheral *targetPeripheral;   // ペリフェラル
@property (nonatomic, strong) CBUUID *serviceUUID;        // Pedometerサービス
@property (nonatomic, strong) CBUUID *characteristicUUID; // Pedometerキャラクタリスティック

@property (nonatomic, weak) IBOutlet JBLineChartView *lineChartView;
@property (nonatomic, weak) IBOutlet UILabel *dateLabel;
@property (nonatomic, weak) IBOutlet UILabel *dataLabel;
@property (nonatomic, strong) NSMutableArray *chartData;
@end


@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.dateLabel.text = nil;
    self.dataLabel.text = nil;
    
    self.lineChartView.dataSource = self;
    self.lineChartView.delegate = self;
    self.lineChartView.backgroundColor = [UIColor clearColor];

    [self initChartData];

    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self
                                                               queue:nil];
    
    self.serviceUUID = [CBUUID UUIDWithString:kSUUIDActivity];
    self.characteristicUUID = [CBUUID UUIDWithString:kCUUIDActivityData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


// =============================================================================
#pragma mark - Private

// 0で埋めたグラフ用初期データを作成
- (void)initChartData {

    self.chartData = @[
                       @[].mutableCopy,
                       @[].mutableCopy,
                       @[].mutableCopy,
                       ].mutableCopy;
    
    for (int i=0; i<kNumberOfPoints; i++) {
        [(NSMutableArray *)self.chartData[0] addObject:@(0)];
        [(NSMutableArray *)self.chartData[1] addObject:@(0)];
        [(NSMutableArray *)self.chartData[2] addObject:@(0)];
    }

    [self.lineChartView reloadData];
}

- (void)updateWithData:(NSData *)data {
    
    LOG_CURRENT_METHOD;
    
    NSData *subdata1 = [data subdataWithRange:NSMakeRange(0, 8)];
    NSData *subdata2 = [data subdataWithRange:NSMakeRange(8, 8)];
    
    NSUInteger numberOfSteps;
    NSUInteger distance;
    
    [subdata1 getBytes:&numberOfSteps length:sizeof(numberOfSteps)];
    [subdata2 getBytes:&distance      length:sizeof(distance)];

    NSLog(@"number of steps:%lu, distance:%lu", (unsigned long)numberOfSteps, (unsigned long)distance);

    // グラフ更新
    [self updateChartWithNumberOfSteps:numberOfSteps distance:distance];
}

- (void)updateChartWithNumberOfSteps:(NSUInteger)numberOfSteps
                            distance:(NSUInteger)distance
{
    // 古いデータを削除
    [(NSMutableArray *)self.chartData[0] removeObjectAtIndex:0];
    [(NSMutableArray *)self.chartData[1] removeObjectAtIndex:0];
    [(NSMutableArray *)self.chartData[2] removeObjectAtIndex:0];
    
    // 新しいデータを入れる
    [(NSMutableArray *)self.chartData[0] addObject:@(numberOfSteps)];
    [(NSMutableArray *)self.chartData[1] addObject:@(distance)];
    [(NSMutableArray *)self.chartData[2] addObject:[NSDate date]];
    
    [self.lineChartView reloadData];
}


// =============================================================================
#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
    NSLog(@"Updated state: %ld", (long)central.state);
    
    switch (central.state) {
        case CBCentralManagerStatePoweredOn:
            [self.centralManager scanForPeripheralsWithServices:@[self.serviceUUID] options:nil];
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
    
    self.targetPeripheral = peripheral;
    
    [central connectPeripheral:peripheral options:nil];
}

- (void)  centralManager:(CBCentralManager *)central
    didConnectPeripheral:(CBPeripheral *)peripheral
{
    LOG_CURRENT_METHOD;
    
    self.targetPeripheral.delegate = self;
    [self.targetPeripheral discoverServices:@[self.serviceUUID]];
}

- (void)        centralManager:(CBCentralManager *)central
    didFailToConnectPeripheral:(CBPeripheral *)peripheral
                         error:(NSError *)error
{
    LOG_CURRENT_METHOD;
    
    if (error) {
        NSLog(@"error:%@", error);
    }
    
    self.targetPeripheral = nil;

    [SVProgressHUD showErrorWithStatus:@"Failed to connect..."];
}

- (void)     centralManager:(CBCentralManager *)central
    didDisconnectPeripheral:(CBPeripheral *)peripheral
                      error:(NSError *)error
{
    LOG_CURRENT_METHOD;
    
    if (error) {
        NSLog(@"error:%@", error);
    }
    
    self.targetPeripheral = nil;

    [SVProgressHUD showErrorWithStatus:@"Disconnected!"];
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
    
    [peripheral setNotifyValue:YES forCharacteristic:[service.characteristics firstObject]];
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

    [SVProgressHUD showSuccessWithStatus:@"Connected!"];
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


// =============================================================================
#pragma mark - JBLineChartViewDataSource

- (NSUInteger)numberOfLinesInLineChartView:(JBLineChartView *)lineChartView
{
    // 歩数と距離は相関があるので、グラフとしては歩数だけ表示する
    return 1;
}

- (NSUInteger)lineChartView:(JBLineChartView *)lineChartView numberOfVerticalValuesAtLineIndex:(NSUInteger)lineIndex
{
    return [self.chartData[lineIndex] count];
}

- (BOOL)lineChartView:(JBLineChartView *)lineChartView showsDotsForLineAtLineIndex:(NSUInteger)lineIndex
{
    return NO;
}

- (BOOL)lineChartView:(JBLineChartView *)lineChartView smoothLineAtLineIndex:(NSUInteger)lineIndex
{
    return NO;
}


// =============================================================================
#pragma mark - JBLineChartViewDelegate

- (CGFloat)           lineChartView:(JBLineChartView *)lineChartView
    verticalValueForHorizontalIndex:(NSUInteger)horizontalIndex
                        atLineIndex:(NSUInteger)lineIndex
{
    return [self.chartData[lineIndex][horizontalIndex] floatValue];
}

- (void)   lineChartView:(JBLineChartView *)lineChartView
    didSelectLineAtIndex:(NSUInteger)lineIndex
         horizontalIndex:(NSUInteger)horizontalIndex
              touchPoint:(CGPoint)touchPoint
{
    NSNumber *numberOfSteps = self.chartData[0][horizontalIndex];
    NSNumber *distance      = self.chartData[1][horizontalIndex];
    NSDate   *date          = self.chartData[2][horizontalIndex];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterShortStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [formatter setLocale:[NSLocale systemLocale]];
    
    self.dateLabel.text = [NSString stringWithFormat:@"%@", [formatter stringFromDate:date]];
    self.dataLabel.text = [NSString stringWithFormat:@"STEPS: %@, DISTANCE: %@ m", numberOfSteps, distance];
}

- (void)didDeselectLineInLineChartView:(JBLineChartView *)lineChartView
{
    self.dateLabel.text = nil;
    self.dataLabel.text = nil;
}

- (UIColor *)lineChartView:(JBLineChartView *)lineChartView colorForLineAtLineIndex:(NSUInteger)lineIndex
{
    return [UIColor whiteColor];
}

- (UIColor *)lineChartView:(JBLineChartView *)lineChartView fillColorForLineAtLineIndex:(NSUInteger)lineIndex
{
    return [UIColor colorWithWhite:1. alpha:0.5];
}

- (UIColor *)lineChartView:(JBLineChartView *)lineChartView selectionFillColorForLineAtLineIndex:(NSUInteger)lineIndex
{
    return [UIColor colorWithWhite:1. alpha:0.5];
}

- (CGFloat)lineChartView:(JBLineChartView *)lineChartView widthForLineAtLineIndex:(NSUInteger)lineIndex
{
    return 2.;
}

- (JBLineChartViewLineStyle)lineChartView:(JBLineChartView *)lineChartView lineStyleForLineAtLineIndex:(NSUInteger)lineIndex
{
    return JBLineChartViewLineStyleSolid;
}

@end
