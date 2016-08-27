//
//  ViewController.m
//  BLEMIDI
//
//  Created by Shuichi Tsutsumi on 2014/11/30.
//  Copyright (c) 2014年 Shuichi Tsutsumi. All rights reserved.
//

#import "ViewController.h"
#import <CoreAudioKit/CoreAudioKit.h>


@interface ViewController ()

@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


// =============================================================================
#pragma mark - Actions

- (IBAction)centralBtnTapped:(id)sender {
    
    // CABTMIDICentralViewController オブジェクト生成
    CABTMIDICentralViewController *centralCtr;
    centralCtr = [[CABTMIDICentralViewController alloc] init];
    
    // CABTMIDICentralViewController に遷移
    [self.navigationController pushViewController:centralCtr
                                         animated:YES];
}

- (IBAction)peripheralBtnTapped:(id)sender {

    // CABTMIDILocalPeripheralViewController オブジェクト生成
    CABTMIDILocalPeripheralViewController *peripheralCtr;
    peripheralCtr = [[CABTMIDILocalPeripheralViewController alloc] init];
    
    // CABTMIDILocalPeripheralViewController に遷移
    [self.navigationController pushViewController:peripheralCtr animated:YES];
}

@end
