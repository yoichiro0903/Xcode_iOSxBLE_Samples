//
//  BLETableViewController.m
//  BLESample
//
//  Created by Shuichi Tsutsumi on 10/9/14.
//  Copyright (c) 2014 Shuichi Tsutsumi. All rights reserved.
//

#import "BLETableViewController.h"
@import CoreBluetooth;


NSString * const kUserDefaultsKeyIdentifiers = @"identifiers";


@interface BLETableViewController ()
<CBCentralManagerDelegate>
{
    BOOL isScanning;
}
@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) NSMutableArray *peripherals;
@end


@implementation BLETableViewController

- (void)viewDidLoad {

    [super viewDidLoad];

    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self
                                                               queue:nil];
    
    self.peripherals = @[].mutableCopy;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



// =============================================================================
#pragma mark - TableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [self.peripherals count] + 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier;
    switch (indexPath.row) {
        case 0:
            identifier = @"ScanCell";
            break;

        case 1:
            identifier = @"RetrieveCell";
            break;

        default:
            identifier = @"PeripheralCell";
            break;
    }

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];

    if (indexPath.row >= 2 && indexPath.row - 2 < [self.peripherals count]) {
        
        CBPeripheral *peripheral = self.peripherals[indexPath.row - 2];
        cell.textLabel.text = [peripheral.name length] ? peripheral.name : @"No Name";
        cell.detailTextLabel.text = peripheral.identifier.UUIDString;
    }
    
    return cell;
}


// =============================================================================
#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    switch (indexPath.row) {
        case 0:
        {
            // スキャンセルをタップ
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            
            if (!isScanning) {
                
                // スキャン開始
                isScanning = YES;
                [self.centralManager scanForPeripheralsWithServices:nil
                                                            options:nil];
                cell.textLabel.text = @"STOP SCAN";
            }
            else {
                
                // スキャン停止
                [self.centralManager stopScan];
                cell.textLabel.text = @"START SCAN";
                isScanning = NO;
            }
            break;
        }
        case 1:
        {
            // Retrieveセルをタップ

            // 保存したUUID文字列のリストを取得
            NSArray *savedUUIDStrings =
            [[NSUserDefaults standardUserDefaults] arrayForKey:kUserDefaultsKeyIdentifiers];
            
            NSMutableArray *identifiers = @[].mutableCopy;
            for (NSString *anUUIDStr in savedUUIDStrings) {
                
                // NSUUIDオブジェクトを生成
                NSUUID *anIdentifier = [[NSUUID alloc] initWithUUIDString:anUUIDStr];
                [identifiers addObject:anIdentifier];
            }
            
            // retrieve実行
            NSArray *peripherals =
            [self.centralManager retrievePeripheralsWithIdentifiers:identifiers];
            
            self.peripherals = peripherals.mutableCopy;
            [self.tableView reloadData];
            
            break;
        }
        default:
        {
            // ペリフェラルセルをタップ
            CBPeripheral *peripheral = self.peripherals[indexPath.row - 2];
            [self.centralManager connectPeripheral:peripheral
                                           options:nil];
            break;
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


// =============================================================================
#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
    // 特に何もしない
    NSLog(@"centralManagerDidUpdateState:%ld", (long)central.state);

}

//
- (void)   centralManager:(CBCentralManager *)central
    didDiscoverPeripheral:(CBPeripheral *)peripheral
        advertisementData:(NSDictionary *)advertisementData
                     RSSI:(NSNumber *)RSSI
{
    NSLog(@"発見したペリフェラル：%@", peripheral);

    // 発見したペリフェラルを配列に追加
    [self.peripherals addObject:peripheral];
    
    
    
    // リスト更新
    [self.tableView reloadData];
}

// ペリフェラルとの接続が成功すると呼ばれる
- (void)  centralManager:(CBCentralManager *)central
    didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"接続成功！");
    
    // ---- ペリフェラルのUUIDを保存する ----

    // 保存済みの配列を取り出す
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSArray *savedIdentifiers =
    [userDefaults arrayForKey:kUserDefaultsKeyIdentifiers];
    NSMutableArray *identifiers =
    [[NSMutableArray alloc] initWithArray:savedIdentifiers];
    
    // 今回接続成功したペリフェラルのUUIDを配列に追加
    NSString *uuidStr = peripheral.identifier.UUIDString;
    if (![identifiers containsObject:uuidStr]) {
        [identifiers addObject:uuidStr];
    }
    
    // 改めて保存する
    [userDefaults setObject:identifiers forKey:kUserDefaultsKeyIdentifiers];
    [userDefaults synchronize];
}

// ペリフェラルとの接続が失敗すると呼ばれる
- (void)        centralManager:(CBCentralManager *)central
    didFailToConnectPeripheral:(CBPeripheral *)peripheral
                         error:(NSError *)error
{
    NSLog(@"接続失敗・・・");
}

/*!
 *  @discussion         This method returns the result of a {@link retrievePeripherals} call, with the peripheral(s) that the central manager was
 *                      able to match to the provided UUID(s).
 */
// Retrieveが完了すると呼ばれる
- (void)    centralManager:(CBCentralManager *)central
    didRetrievePeripherals:(NSArray *)peripherals
{
    NSLog(@"Retrieveしたペリフェラル: %@", peripherals);
}

@end
