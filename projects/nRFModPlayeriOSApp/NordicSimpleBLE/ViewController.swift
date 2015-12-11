//
//  ViewController.swift
//  NordicSimpleBLE
//
//  Created by System Architecture on 26/10/15.
//  Copyright © 2015 Nordic Semiconductor. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, peripheralDelegate, UITableViewDataSource, UITableViewDelegate {
    
    private var bleManager = BLEManager()
    
    private let nRFModPlayerName = "nRF_Mod_Player"
    
    private let nRFModPlayerServiceUUID          = CBUUID.init(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    private let nRFModPlayerTXCharacteristicUUID = CBUUID.init(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
    private let nRFModPlayerRXCharacteristicUUID = CBUUID.init(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
    
    private struct nordicBlueColor {
        let red:   Float = 0.0   / 255.0
        let green: Float = 156.0 / 255.0
        let blue:  Float = 222.0 / 255.0
        let alpha: Float = 1.0
    }
    
    private var modFileData1 : [UInt8]?
    
    private let OffNS = NSData(bytes: [0] as [UInt8], length: sizeof(UInt8))
    private let OnNS  = NSData(bytes: [0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69] as [UInt8], length: sizeof(UInt8) * 8)
    
    private var nRFModPlayerPeripheral            : CBPeripheral?
    private var nRFModPlayerService               : CBService?
    private var nRFModPlayerTXCharacteristic      : CBCharacteristic?
    private var nRFModPlayerRXCharacteristic      : CBCharacteristic?
    
    private var discoveredPeripherals = [(peripheral: CBPeripheral, RSSI: String)]()
    
    @IBOutlet weak var backgroundImage            : UIImageView!
    @IBOutlet weak var blurOverlay                : UIImageView!
    @IBOutlet weak var scanTableView              : UITableView!
    @IBOutlet weak var navigationBar              : UINavigationItem!
    @IBOutlet weak var scanDisconnectButtonOutlet : UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bleManager.peripheralDelegateInst = self
        
        scanTableView.rowHeight = UITableViewAutomaticDimension
        scanTableView.estimatedRowHeight = 44.0 // Default table view cell is 44, but it doesn`t seem to matter what is actually put here.
        
        let nordicBlue = nordicBlueColor.init()
        navigationController!.navigationBar.barTintColor = UIColor(colorLiteralRed: nordicBlue.red, green: nordicBlue.green, blue: nordicBlue.blue, alpha: nordicBlue.alpha)
        navigationController!.navigationBar.tintColor = UIColor.whiteColor()
        navigationController!.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.whiteColor()]
        
        let blur = UIBlurEffect(style: .Dark)
        let darkBlurView = UIVisualEffectView(effect: blur)
        darkBlurView.frame = view.bounds
        blurOverlay.addSubview(darkBlurView)
        
        hideScanWindow()
        
        self.modFileData1 = [0x63, 0x6C, 0x61, 0x73, 0x73, 0x30, 0x35, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x6D, 0x61, 0x6B, 0x74, 0x6F, 0x6E, 0x65, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x63, 0x6C, 0x61, 0x73, 0x73, 0x20, 0x26, 0x20, 0x73, 0x75, 0x70, 0x65, 0x72, 0x73, 0x74, 0x61, 0x72, 0x73, 0x00, 0x00, 0x00, 0x00, 0x00, 0xEB, 0x00, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  0xD6, 0xD6, 0xD6, 0xD6, 0xD6, 0xD6, 0xD6, 0xD6, 0xD6, 0xD6, 0xD6]
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func scanDisconnectButtonAction(sender: UIButton) {
        if let currentText = sender.currentTitle {
            if currentText == "Scan" {
                bleManager.startScanning([nRFModPlayerServiceUUID])
                showScanWindow()
            } else if currentText == "Disconnect" {
                if let peripheral = nRFModPlayerPeripheral {
                    bleManager.cancelConnectionToPeripheral(peripheral)
                }
            }
        }
    }
    
    @IBAction func hideScanWindow(sender: UITapGestureRecognizer) {
        bleManager.stopScanning()
        hideScanWindow()
    }
    
    @IBAction func bleSendData(sender: UIButton) {
        if let _ = nRFModPlayerPeripheral {
            if var modFileData : [UInt8] = modFileData1?.reverse() {
                
                var dataBytes : [UInt8] = []
                while modFileData.count != 0 {
                    dataBytes.append(modFileData.popLast()!)
                    if dataBytes.count == 20 {
                        bleSendPacket(dataBytes)
                        dataBytes.removeAll()
                    }
                }
                if dataBytes.count != 0 {
                    bleSendPacket(dataBytes)
                    dataBytes.removeAll()
                }
                
            }
        }
    }
    
    private func bleSendPacket(dataBytes : [UInt8]) {
        let data  = NSData(bytes: dataBytes, length: sizeof(UInt8) * dataBytes.count)
        bleManager.writeCharacteristic(data, characteristic: nRFModPlayerTXCharacteristic!)
    }
    
    func didDiscoverPeripheral(peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        discoveredPeripherals.append((peripheral, "\(RSSI)"))
        scanTableView.reloadData()
    }
    
    func didConnectPeripheral(peripheral: CBPeripheral) {
        if peripheral.name == nRFModPlayerName {
            nRFModPlayerPeripheral = peripheral
            bleManager.discoverServices(peripheral, services: nil)
            scanDisconnectButtonOutlet.setTitle("Disconnect", forState: .Normal)
            hideScanWindow()
        }
    }
    
    func didDiscoverServices(peripheral: CBPeripheral, services: [CBService]) {
        for service in services {
            if service.UUID == nRFModPlayerServiceUUID {
                nRFModPlayerService = service
                bleManager.discoverCharacteristics(peripheral, service: service, characteristics: [nRFModPlayerTXCharacteristicUUID, nRFModPlayerRXCharacteristicUUID])
            }
        }
    }
    
    func didDiscoverCharacteristics(peripheral: CBPeripheral, characteristics: [CBCharacteristic]) {
        for characteristic in characteristics {
            if characteristic.UUID == nRFModPlayerTXCharacteristicUUID {
                print("Discovered TX characteristic!")
                nRFModPlayerTXCharacteristic = characteristic
            } else if characteristic.UUID == nRFModPlayerRXCharacteristicUUID {
                print("Discovered RX characteristic!")
                nRFModPlayerRXCharacteristic = characteristic
                bleManager.setNotifyValue(characteristic)
            }
        }
    }
    
    func didUpdateValueForCharacteristic(peripheral: CBPeripheral, characteristic: CBCharacteristic) {
        print("didUpdateValueForCharacteristic")
        print(characteristic)
        print(characteristic.value)
        if let charValue = characteristic.value {
            if charValue == OffNS {
                backgroundImage.image = backgroundImage.image!.imageWithRenderingMode(.AlwaysOriginal)
            } else if charValue == OnNS {
                backgroundImage.image = backgroundImage.image!.imageWithRenderingMode(.AlwaysTemplate)
            }
        }
    }
    
    func didDisconnectPeripheral(peripheral: CBPeripheral) {
        nRFModPlayerPeripheral = nil
        nRFModPlayerService = nil
        nRFModPlayerTXCharacteristic = nil
        nRFModPlayerRXCharacteristic = nil
        scanDisconnectButtonOutlet.setTitle("Scan", forState: .Normal)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = scanTableView.dequeueReusableCellWithIdentifier("cell")!
        let peripheral = discoveredPeripherals[indexPath.row].peripheral
        let RSSI = discoveredPeripherals[indexPath.row].RSSI
        cell.textLabel?.text = peripheral.name
        cell.detailTextLabel?.text = "RSSI: \(RSSI)"
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return discoveredPeripherals.count
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        bleManager.connectToPeripheral(discoveredPeripherals[indexPath.row].peripheral)
    }
    
    private func hideScanWindow() {
        scanTableView.hidden = true
        blurOverlay.hidden = true
    }
    
    private func showScanWindow() {
        discoveredPeripherals.removeAll()
        scanTableView.reloadData()
        blurOverlay.hidden = false
        scanTableView.hidden = false
    }
    
}
