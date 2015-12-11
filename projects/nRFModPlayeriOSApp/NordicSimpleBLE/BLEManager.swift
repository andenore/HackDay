//
//  BLEManager.swift
//  NordicSimpleBLE
//
//  Created by System Architecture on 27/10/15.
//  Copyright © 2015 Nordic Semiconductor. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol peripheralDelegate {
    func didDiscoverPeripheral(peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber)
    func didConnectPeripheral(peripheral: CBPeripheral)
    func didDiscoverServices(peripheral : CBPeripheral, services : [CBService])
    func didDiscoverCharacteristics(peripheral : CBPeripheral, characteristics : [CBCharacteristic])
    func didUpdateValueForCharacteristic(peripheral: CBPeripheral, characteristic: CBCharacteristic)
    func didDisconnectPeripheral(peripheral: CBPeripheral)
}

class BLEManager : NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    private var centralManager : CBCentralManager!
    private var nRF5xPeripheral : CBPeripheral!
    
    var peripheralDelegateInst : peripheralDelegate?
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    /// Scans for peripherals that are advertising services.
    func startScanning(UUIDs: [CBUUID]?) {
        centralManager.scanForPeripheralsWithServices(UUIDs, options: nil)
    }
    
    /// Asks the central manager to stop scanning for peripherals.
    func stopScanning() {
        centralManager.stopScan()
    }
    
    /// Establishes a local connection to a peripheral.
    func connectToPeripheral(peripheral: CBPeripheral) {
        centralManager.stopScan()
        nRF5xPeripheral = peripheral
        nRF5xPeripheral.delegate = self
        centralManager.connectPeripheral(nRF5xPeripheral, options: nil)
    }
    
    /// Cancels an active or pending local connection to a peripheral.
    func cancelConnectionToPeripheral(peripheral: CBPeripheral) {
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    /// Discovers the specified services of the peripheral.
    func discoverServices(peripheral : CBPeripheral, services : [CBUUID]?) {
        peripheral.discoverServices(services)
    }
    
    /// Discovers the specified characteristics of a service.
    func discoverCharacteristics(peripheral : CBPeripheral, service: CBService, characteristics : [CBUUID]?) {
        peripheral.discoverCharacteristics(characteristics, forService: service)
    }
    
    /// Discovers the descriptors of a characteristic.
    func discoverDescriptors(characteristic: CBCharacteristic) {
        nRF5xPeripheral.discoverDescriptorsForCharacteristic(characteristic)
    }
    
    /// Sets notifications or indications for the value of a specified characteristic.
    func setNotifyValue(characteristic: CBCharacteristic) {
        nRF5xPeripheral.setNotifyValue(true, forCharacteristic: characteristic)
    }
    
    /// Writes the value of a characteristic.
    func writeCharacteristic(data: NSData, characteristic: CBCharacteristic) {
        nRF5xPeripheral.writeValue(data, forCharacteristic: characteristic, type: CBCharacteristicWriteType.WithResponse)
    }
    
    /// Retrieves the value of a specified characteristic.
    func readCharacteristic(characteristic: CBCharacteristic) {
        nRF5xPeripheral.readValueForCharacteristic(characteristic)
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        switch (central.state) {
        case .PoweredOff:
            print("CoreBluetooth BLE hardware is powered off.")
            
        case .PoweredOn:
            print("CoreBluetooth BLE hardware is powered on and ready.")
            
        case .Resetting:
            print("CoreBluetooth BLE hardware is resetting.")
            
        case .Unauthorized:
            print("CoreBluetooth BLE state is unauthorized.")
            
        case .Unknown:
            print("CoreBluetooth BLE state is unknown.")
            
        case .Unsupported:
            print("CoreBluetooth BLE hardware is unsupported on this platform.")
        }
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        peripheralDelegateInst?.didDiscoverPeripheral(peripheral, advertisementData: advertisementData, RSSI: RSSI)
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        print("Connected!")
        peripheralDelegateInst?.didConnectPeripheral(peripheral)
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        if let services = peripheral.services {
            peripheralDelegateInst?.didDiscoverServices(peripheral, services: services)
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        if let characteristics = service.characteristics {
            peripheralDelegateInst?.didDiscoverCharacteristics(peripheral, characteristics: characteristics)
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverDescriptorsForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        // TODO: implement if needed or remove.
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        peripheralDelegateInst?.didUpdateValueForCharacteristic(peripheral, characteristic: characteristic)
    }
    
    func centralManager(_: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        peripheralDelegateInst?.didDisconnectPeripheral(peripheral)
    }

}
