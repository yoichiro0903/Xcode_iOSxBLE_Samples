//
//  ViewController.m
//  KonashiFind
//
//  Created by Matsumura Reo on 2015/03/18.
//  Copyright (c) 2015年 Matsumura Reo. All rights reserved.
//

#import "ViewController.h"
#import "Konashi.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [Konashi initialize];
    [Konashi find];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
