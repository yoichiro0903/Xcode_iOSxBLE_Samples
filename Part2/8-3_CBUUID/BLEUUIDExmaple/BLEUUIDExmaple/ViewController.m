//
//  ViewController.m
//  BLEUUIDExmaple
//
//  Created by Shuichi Tsutsumi on 2015/01/20.
//  Copyright (c) 2015年 Shuichi Tsutsumi. All rights reserved.
//

#import "ViewController.h"
@import CoreBluetooth;


@interface ViewController ()

@end


@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];

    // 128ビットUUID文字列から生成
    CBUUID *uuidFrom128 = [CBUUID UUIDWithString:@"00009999-0000-1000-8000-00805F9B34FB"];
    NSLog(@"CBUUID from 128bit: %@, UUIDString: %@, data: %@", uuidFrom128, uuidFrom128.UUIDString, uuidFrom128.data);

    // 16ビット短縮表現の文字列から生成
    CBUUID *uuidFrom16 = [CBUUID UUIDWithString:@"9999"];
    NSLog(@"CBUUID from 16bit: %@, UUIDString: %@, data: %@", uuidFrom16, uuidFrom16.UUIDString, uuidFrom16.data);
    
    // 両者を比較（==）
    NSLog(@"isEqual: %d", uuidFrom16 == uuidFrom128);

    // 両者を比較（isEqual）
    NSLog(@"isEqual: %d", [uuidFrom16 isEqual:uuidFrom128]);

    // ハイフンなし（実行時エラーとなる）
//    CBUUID *uuidFrom128_2 = [CBUUID UUIDWithString:@"0000180D00001000800000805F9B34FB"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
