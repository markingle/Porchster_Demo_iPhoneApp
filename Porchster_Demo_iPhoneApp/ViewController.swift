//
//  ViewController.swift
//  Porchster_Demo_iPhoneApp
//
//  Created by Mark Brady Ingle on 11/10/19.
//  Copyright © 2019 Mark Brady Ingle. All rights reserved.
//

import UIKit

import CoreBluetooth


// MARK: - Core Bluetooth service IDs
let Porchster_Service_CBUUID = CBUUID(string: "4fafc201-1fb5-459e-8fcc-c5c9c331915c")


// MARK: - Core Bluetooth characteristic IDs
let Porchster_Solenoid_Characteristic_CBUUID = CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26b7")
let Porchster_Scanner_Characteristic_CBUUID = CBUUID(string: "beb5483e-36e1-4688-b7f6-ea07361b26c8")
let Livewell_ONTIME_Characteristic_CBUUID = CBUUID(string: "beb5483e-36e1-4688-b7f7-ea07361b26d9")
let Livewell_TIMER_Characteristic_CBUUID = CBUUID(string: "beb5483e-36e1-4688-b7f8-ea07361b26a1")



class ViewController: UIViewController,CBCentralManagerDelegate, CBPeripheralDelegate {
    
        
    // Create instance variables of the
    // CBCentralManager and CBPeripheral so they
    // persist for the duration of the app's life
    var centralManager: CBCentralManager?
    var PorchsterLockbox: CBPeripheral?
    
    @IBOutlet weak var bluetoothOffLabel: UILabel!
    
    @IBOutlet weak var Lock_Unlock_Button: UIButton!
    var isPressed = false
    
    @IBOutlet weak var barcodeNumberLabel: UILabel!
    
    @IBAction func didPressButton(_ sender: UIButton) {
        isPressed = !isPressed
        if isPressed {
            print("LOCK")
            sender.setTitle("LOCK", for: .normal)
            let PorchsterState = "1"
            let data = Data(PorchsterState.utf8)
            print("data = ", data)
            writeonStateValueToChar(withCharacteristic: LockState!, withValue: data)
        } else {
            print("UNLOCK")
            sender.setTitle("UNLOCK", for: .normal)
            let SwitchState = "0"
            let data = Data(SwitchState.utf8)
            print("data = ", data)
            writeonStateValueToChar(withCharacteristic: LockState!, withValue: data)
        }
    }
    
    // Characteristics
    private var LockState: CBCharacteristic?
    private var Barcode_Scanner_Value: CBCharacteristic?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        bluetoothOffLabel.alpha = 0.0
        
        // Create a concurrent background queue for the central
        let centralQueue: DispatchQueue = DispatchQueue(label: "com.iosbrain.centralQueueName", attributes: .concurrent)
        
        // Create a central to scan for, connect to,
        // manage, and collect data from peripherals
        centralManager = CBCentralManager(delegate: self, queue: centralQueue)
    }

    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        
        case .unknown:
            print("Bluetooth status is UNKNOWN")
            bluetoothOffLabel.alpha = 1.0
        case .resetting:
            print("Bluetooth status is RESETTING")
            bluetoothOffLabel.alpha = 1.0
        case .unsupported:
            print("Bluetooth status is UNSUPPORTED")
            bluetoothOffLabel.alpha = 1.0
        case .unauthorized:
            print("Bluetooth status is UNAUTHORIZED")
            bluetoothOffLabel.alpha = 1.0
        case .poweredOff:
            print("Bluetooth status is POWERED OFF")
            bluetoothOffLabel.alpha = 1.0
        case .poweredOn:
            print("Bluetooth status is POWERED ON")
            DispatchQueue.main.async { () -> Void in
                self.bluetoothOffLabel.alpha = 0.0
                /*self.connectionActivityStatus.backgroundColor = UIColor.black
                self.connectionActivityStatus.startAnimating()*/
                
            }
            // STEP 3.2: scan for peripherals that we're interested in
            centralManager?.scanForPeripherals(withServices: [Porchster_Service_CBUUID])
            print("Central Manager Looking!!")
        default: break
        } // END switch
    }

   func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
       
       print("Peripheral Found ",peripheral.name!)
       decodePeripheralState(peripheralState: peripheral.state)
       // STEP 4.2: MUST store a reference to the peripheral in
       // class instance variable
       PorchsterLockbox = peripheral
       // STEP 4.3: since ViewController
       // adopts the CBPeripheralDelegate protocol,
       // the SeaArkLivewellTimer must set its
       // delegate property to ViewController
       // (self)
       PorchsterLockbox?.delegate = self
       
       // STEP 5: stop scanning to preserve battery life;
       // re-scan if disconnected
       centralManager?.stopScan()
       print("Stopped Scanning")
       
       // STEP 6: connect to the discovered peripheral of interest
       centralManager?.connect(PorchsterLockbox!)
       
   } // END func centralManager(... didDiscover peripheral
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        DispatchQueue.main.async { () -> Void in
            
            
        }
        
        // STEP 8: look for services of interest on peripheral
        print("Did Connect....Looking for Locking Service")
        PorchsterLockbox?.discoverServices([Porchster_Service_CBUUID])

    } // END func centralManager(... didConnect peripheral
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    
    for service in peripheral.services! {
        
        if service.uuid == Porchster_Service_CBUUID {
            
            print("Service: \(service)")
            
            // STEP 9: look for characteristics of interest
            // within services of interest
            peripheral.discoverCharacteristics(nil, for: service)
            
        }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        centralManager?.scanForPeripherals(withServices: [Porchster_Service_CBUUID])
        print("Central Manager Looking!!")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        for characteristic in service.characteristics! {
            
            print("Characteristic: \(characteristic)")
            
            if characteristic.uuid == Porchster_Scanner_Characteristic_CBUUID{
                print("Barcode Scanner Characteristic")
                peripheral.setNotifyValue(true, for: characteristic)
            }
            
            if characteristic.uuid == Porchster_Solenoid_Characteristic_CBUUID{
                print("Lock State Characteristic")
                LockState = characteristic
            }
        }
    } // END func peripheral(... didDiscoverCharacteristicsFor service
    
    func decodePeripheralState(peripheralState: CBPeripheralState) {
    
    switch peripheralState {
        case .disconnected:
            print("Peripheral state: disconnected")
        case .connected:
            print("Peripheral state: connected")
        case .connecting:
            print("Peripheral state: connecting")
        case .disconnecting:
            print("Peripheral state: disconnecting")
    default: break
    }
    }
    
    func writeonStateValueToChar( withCharacteristic characteristic: CBCharacteristic, withValue value: Data) {
        if characteristic.properties.contains(.writeWithoutResponse) && PorchsterLockbox != nil {
            PorchsterLockbox?.writeValue(value, for: characteristic, type:.withoutResponse)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if characteristic.uuid == Porchster_Scanner_Characteristic_CBUUID {
            
            // STEP 14: we generally have to decode BLE
            // data into human readable format
            let barcode_number = [UInt8](characteristic.value!)
            
            print("Barcode", barcode_number[0])

            DispatchQueue.main.async { () -> Void in
                self.barcodeNumberLabel.text = String(barcode_number[0])
            }
        } // END if characteristic.uuid ==...
        
    } // END func peripheral(... didUpdateValueFor characteristic
}

