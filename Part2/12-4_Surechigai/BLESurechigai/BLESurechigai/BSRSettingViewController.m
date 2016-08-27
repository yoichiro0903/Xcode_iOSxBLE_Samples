//
//  BSRSettingViewController.m
//  BLESurechigai
//
//  Created by Shuichi Tsutsumi on 2014/12/28.
//  Copyright (c) 2014年 Shuichi Tsutsumi. All rights reserved.
//

#import "BSRSettingViewController.h"
#import "BSRUserDefaults.h"
#import "SVProgressHUD.h"


@interface BSRSettingViewController ()
@property (nonatomic, weak) IBOutlet UITextField *usernameField;
@end


@implementation BSRSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    // 既にユーザー名があれば表示する
    NSString *username = [BSRUserDefaults username];
    if ([username length]) {
        self.usernameField.text = username;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    
    // ユーザー名が入力されていれば保存する
    if ([self.usernameField.text length]) {
        [BSRUserDefaults setUsername:self.usernameField.text];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


// =============================================================================
#pragma mark - IBAction

- (IBAction)doneBtnTapped:(id)sender {

    if (![self.usernameField.text length]) {
        [SVProgressHUD showErrorWithStatus:@"ユーザー名を入力してください"];
    }

    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
