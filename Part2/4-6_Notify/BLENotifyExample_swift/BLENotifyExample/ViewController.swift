//
//  ViewController.swift
//  BLEScanExample
//
//  Created by Shuichi Tsutsumi on 2014/12/12.
//  Copyright (c) 2014年 Shuichi Tsutsumi. All rights reserved.
//

import UIKit
import CoreBluetooth


class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {

    var isScanning = false
    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // セントラルマネージャ初期化
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    // =========================================================================
    // MARK: CBCentralManagerDelegate
    
    // セントラルマネージャの状態が変化すると呼ばれる
    func centralManagerDidUpdateState(central: CBCentralManager) {

        print("state: \(central.state)")
    }
    
    // ペリフェラルを発見すると呼ばれる
    func centralManager(central: CBCentralManager,
        didDiscoverPeripheral peripheral: CBPeripheral,
        advertisementData: [String : AnyObject],
        RSSI: NSNumber)
    {
        print("発見したBLEデバイス: \(peripheral)")
        
        if peripheral.name?.hasPrefix("konashi") == true {
            
            self.peripheral = peripheral
            
            // 接続開始
            self.centralManager.connectPeripheral(self.peripheral, options: nil)
        }
    }
    
    // ペリフェラルへの接続が成功すると呼ばれる
    func centralManager(central: CBCentralManager,
        didConnectPeripheral peripheral: CBPeripheral)
    {
        print("接続成功！")

        // サービス探索結果を受け取るためにデリゲートをセット
        peripheral.delegate = self
        
        // サービス探索開始
        peripheral.discoverServices(nil)
    }
    
    // ペリフェラルへの接続が失敗すると呼ばれる
    func centralManager(central: CBCentralManager,
        didFailToConnectPeripheral peripheral: CBPeripheral,
        error: NSError?)
    {
        print("接続失敗・・・")
    }

    
    // =========================================================================
    // MARK:CBPeripheralDelegate
    
    // サービス発見時に呼ばれる
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        
        if (error != nil) {
            print("エラー: \(error)")
            return
        }
        
        if !(peripheral.services?.count > 0) {
            print("no services")
            return
        }

        let services = peripheral.services!

        print("\(services.count) 個のサービスを発見！ \(services)")

        for service in services {
            
            // キャラクタリスティック探索開始
            peripheral.discoverCharacteristics(nil, forService: service)
        }
    }
    
    // キャラクタリスティック発見時に呼ばれる
    func peripheral(peripheral: CBPeripheral,
        didDiscoverCharacteristicsForService service: CBService,
        error: NSError?)
    {
        if (error != nil) {
            print("エラー: \(error)")
            return
        }
        
        if !(service.characteristics?.count > 0) {
            print("no characteristics")
            return
        }

        let characteristics = service.characteristics!
        
        for characteristic in characteristics {
            
            // konashi の PIO_INPUT_NOTIFICATION キャラクタリスティック
            if characteristic.UUID.isEqual(CBUUID(string: "3003")) {
                
                // 更新通知受け取りを開始する
                peripheral.setNotifyValue(
                    true,
                    forCharacteristic: characteristic)
            }
        }
    }

    // Notify開始／停止時に呼ばれる
    func peripheral(peripheral: CBPeripheral,
        didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic,
        error: NSError?)
    {
        if error != nil {
            
            print("Notify状態更新失敗...error: \(error)")
        }
        else {
            print("Notify状態更新成功！characteristic UUID:\(characteristic.UUID), isNotifying: \(characteristic.isNotifying)")
        }
    }

    // データ更新時に呼ばれる
    func peripheral(peripheral: CBPeripheral,
        didUpdateValueForCharacteristic characteristic: CBCharacteristic,
        error: NSError?)
    {
        if error != nil {
            print("データ更新通知エラー: \(error)")
            return
        }
        
        print("データ更新！ characteristic UUID: \(characteristic.UUID), value: \(characteristic.value)")
    }

    
    // =========================================================================
    // MARK: Actions

    @IBAction func scanBtnTapped(sender: UIButton) {
        
        if !isScanning {
            
            isScanning = true
            
            self.centralManager.scanForPeripheralsWithServices(nil, options: nil)
            
            sender.setTitle("STOP SCAN", forState: UIControlState.Normal)
        }
        else {
            
            self.centralManager.stopScan()
            
            sender.setTitle("START SCAN", forState: UIControlState.Normal)
            
            isScanning = false
        }
    }
}

