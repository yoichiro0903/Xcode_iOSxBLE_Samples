//
//  ViewController.m
//  BLESurechigai
//
//  Created by Shuichi Tsutsumi on 2014/12/12.
//  Copyright (c) 2014年 Shuichi Tsutsumi. All rights reserved.
//

#import "ViewController.h"
#import "BSRCentralManager.h"
#import "BSRPeripheralManager.h"
#import "BSRUserDefaults.h"
#import "SVProgressHUD.h"


@interface ViewController () <BSREncounterDelegate>
@property (nonatomic, strong) NSArray *items;
@end


@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];

    // ペリフェラル側は初期化しておく
    // （セントラルはユーザー名の入力が完了してから初期化→スキャン開始する）
    [[BSRPeripheralManager sharedManager] setDeleagte:self];

    UIRefreshControl *refreshCtl = [[UIRefreshControl alloc] init];
    [refreshCtl addTarget:self action:@selector(onRefresh:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refreshCtl];

    self.items = [BSRUserDefaults encounters];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];

}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];

    // ユーザー名が未決定であればユーザー名入力画面を表示する
    if (![[BSRUserDefaults username] length]) {
        
        [self performSegueWithIdentifier:@"ShowSetting" sender:self];
    }
    // ユーザー名の入力完了
    else {
        
        // セントラル側は初期化＆スキャン開始する
        [[BSRCentralManager sharedManager] setDeleagte:self];

        // ペリフェラル側はキャラクタリスティックを更新する
        [[BSRPeripheralManager sharedManager] updateUsername];
        
        NSLog(@"Start with username: %@", [BSRUserDefaults username]);
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


// =============================================================================
#pragma mark - Private

- (void)alertWithUsername:(NSString *)username {

    NSString *msg = [NSString stringWithFormat:@"%@とすれ違いました！", username];

    // バックグラウンド時はローカル通知
    if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive) {
        
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        notification.alertBody = msg;
        notification.fireDate = [NSDate date];
        notification.soundName = UILocalNotificationDefaultSoundName;
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    }
    // フォアグラウンドではHUD
    else {
        [SVProgressHUD showSuccessWithStatus:msg];
    }
}



// =============================================================================
#pragma mark - TableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [self.items count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    NSDictionary *encounterDic = self.items[indexPath.row];
    
    cell.textLabel.text = encounterDic[kEncouterDictionaryKeyUsername];
    cell.detailTextLabel.text = [(NSDate *)encounterDic[kEncouterDictionaryKeyDate] descriptionWithLocale:[NSLocale currentLocale]];
    
    return cell;
}


// =============================================================================
#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


// =============================================================================
#pragma mark - BSREncounterDelegate

- (void)didEncounterUserWithName:(NSString *)username {
    
    LOG_CURRENT_METHOD;

    dispatch_async(dispatch_get_main_queue(), ^{

        // アラート表示
        [self alertWithUsername:username];
        
        // すれちがいリストに追加
        [BSRUserDefaults addEncounterWithName:username date:[NSDate date]];
        
        self.items = [BSRUserDefaults encounters];
        [self.tableView reloadData];
    });
}


// =============================================================================
#pragma mark - Event Handler

- (void)onRefresh:(UIRefreshControl *)sender {

    [sender beginRefreshing];
    
    self.items = [BSRUserDefaults encounters];
    [self.tableView reloadData];
    
    [sender endRefreshing];
}

@end
