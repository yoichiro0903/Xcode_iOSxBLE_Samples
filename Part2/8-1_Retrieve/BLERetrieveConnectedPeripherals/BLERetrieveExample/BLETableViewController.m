//
//  BLETableViewController.m
//  BLESample
//
//  Created by Shuichi Tsutsumi on 10/9/14.
//  Copyright (c) 2014 Shuichi Tsutsumi. All rights reserved.
//

#import "BLETableViewController.h"
@import CoreBluetooth;


NSString * const kBLEUserDefaultsKeyIdentifiers = @"identifiers";


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
    
    return [self.peripherals count] + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier;
    switch (indexPath.row) {
        case 0:
            identifier = @"RetrieveCell";
            break;

        default:
            identifier = @"PeripheralCell";
            break;
    }

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];

    if (indexPath.row >= 1 && indexPath.row - 1 < [self.peripherals count]) {
        
        CBPeripheral *peripheral = self.peripherals[indexPath.row - 1];
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
            // Retrieveセルをタップ

            // UUIDのリストを作成
            NSArray *serviceUUIDs = @[[CBUUID UUIDWithString:@"0000"]];
            
            // retrieve実行
            NSArray *peripherals =
            [self.centralManager retrieveConnectedPeripheralsWithServices:serviceUUIDs];

            self.peripherals = peripherals.mutableCopy;
            NSLog(@"retrieved peripherals:%@", peripherals);
            
            [self.tableView reloadData];
            
            break;
        }
        default:
        {
            // ペリフェラルセルをタップ
            CBPeripheral *peripheral = self.peripherals[indexPath.row - 1];
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
    NSArray *savedIdentifiers = [userDefaults arrayForKey:kBLEUserDefaultsKeyIdentifiers];
    NSMutableArray *identifiers = [[NSMutableArray alloc] initWithArray:savedIdentifiers];
    
    // 今回接続成功したペリフェラルのUUIDを配列に追加
    NSString *uuidStr = peripheral.identifier.UUIDString;
    if (![identifiers containsObject:uuidStr]) {
        [identifiers addObject:uuidStr];
    }
    
    // 改めて保存する
    [userDefaults setObject:identifiers forKey:kBLEUserDefaultsKeyIdentifiers];
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
