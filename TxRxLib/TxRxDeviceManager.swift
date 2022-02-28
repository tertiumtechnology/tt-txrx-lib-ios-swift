/*
 * The MIT License
 *
 * Copyright 2017-2021 Tertium Technology.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */
import UIKit
import CoreBluetooth
import Foundation

/// TxRxDeviceManager library TxRxDeviceManager class
///
/// TxRxDeviceManager class is TxRxDeviceManager library main class
///
/// TxRxDeviceManager eases programmer life by dealing with CoreBluetooth internals
///
/// NOTE: Implements CBCentralManagerDelegate and CBPeripheralDelegate protocols
///
/// Methods are ordered chronologically
public class TxRxDeviceManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    ///
    /// Queue to which TxRxDeviceManager internals dispatch asyncronous calls. Change if you want the class to work in a thread with its GCD queue
    ///
    /// DEFAULT: main thread queue
    private var _dispatchQueue: DispatchQueue
    
    /// Dispatch queue to which delegate callbacks will be issued.
    ///
    /// DEFAULT: main thread queue
    private var _callbackQueue: DispatchQueue
    
    /// Delegate for scanning devices. Delegate methods will be called on device events (refer to TxRxDeviceScanProtocol.swift)
    public var _delegate: TxRxDeviceScanProtocol?
    
    /// Property telling if the class is currently in scanning devices phase
    public internal(set) var _isScanning = false
    
    /// The MAXIMUM time the class and BLE hardware have to connect to a BLE device
    ///
    /// Check setTimeOutDefaults method to see the default value
    private var _connectTimeout: Double = 0
    
    /// The MAXIMUM time a Tertium BLE device has to send the first response packet to an issued command
    ///
    /// Check setTimeOutDefaults method to see the default value
    private var _receiveFirstPacketTimeout: Double = 0
    
    /// The MAXIMUM time a Tertium BLE device has to send the after having sent the first response packet to an issued command (commands and data are sent in FRAGMENTS)
    ///
    /// Check setTimeOutDefaults method to see the default value
    private var _receivePacketsTimeout: Double = 0
    
    /// The MAXIMUM time a Tertium BLE device has to notify when a write operation on a device is issued by sendData method
    ///
    /// Check setTimeOutDefaults method to see the default value
    private var _writePacketTimeout: Double = 0
    
    /// Tells if CoreBluetooth is ready to operate
    private var _blueToothPoweredOn = false
        
    /// CoreBluetooth manager class reference
    private var _centralManager: CBCentralManager!
    
    /// Array of supported Tertium BLE Devices (please refer to init method for details)
    private var _txRxSupportedDevices = [TxRxDeviceProfile]()
    
    /// Array of scannned devices found by startScan. Used for input parameter validation and internal cleanup
    private var _scannedDevices = [TxRxDevice]()
    
    /// Array of connecting devices. Used for input parameter validation
    private var _connectingDevices = [TxRxDevice]()
    
    /// Array of disconnecting devices. Used for input parameter validation
    private var _disconnectingDevices = [TxRxDevice]()
    
    /// Array of connected devices. Used for input parameter validation
    private var _connectedDevices = [TxRxDevice]()
    
    // TxRxDeviceManager singleton
    private static let _sharedInstance = TxRxDeviceManager()
    
    /// Gets the singleton instance of the class
    ///
    /// NOTE: CLASS Method
    ///
    /// - returns: The singleton instance of TxRxDeviceManager class
    public class func getInstance() -> TxRxDeviceManager {
        return _sharedInstance;
    }
    
    let SENSOR_TERTIUM_SERVICEUUID = "f3770001-1164-49bc-8f22-0ac34292c217";
    let TX_RX_ACKME_SERVICEUUID = "175f8f23-a570-49bd-9627-815a6a27de2a";
    let ZHAGA_SERVICEUUID = "3cc30001-cb91-4947-bd12-80d2f0535a30";
    let TX_RX_TERTIUM_SERVICEUUID = "d7080001-052c-46c4-9978-c0977bebf328";
    let ZEBRA_TERTIUM_SERVICEUUID = "c1ff0001-c47e-424d-9495-fb504404b8f5";
    
    override init() {
        _callbackQueue = DispatchQueue.main
        _dispatchQueue = _callbackQueue
        super.init()
        
        //
        setTimeOutDefaults()
        
        // Tertium sensor
        _txRxSupportedDevices.append(TxRxDeviceProfile(inServiceUUID: SENSOR_TERTIUM_SERVICEUUID,
                                                   withRxUUID: "f3770002-1164-49bc-8f22-0ac34292c217",
                                                   withTxUUID: "f3770003-1164-49bc-8f22-0ac34292c217",
                                                   withSetModeUUID: "",
                                                   withEventUUID: "",
                                                   withCommandEnd: TxRxDeviceProfile.TerminatorType.CRLF.rawValue,
                                                   withRxPacketSize: 240,
                                                   withTxPacketSize: 240))
        
        // Zentri Ackme
        _txRxSupportedDevices.append(TxRxDeviceProfile(inServiceUUID: TX_RX_ACKME_SERVICEUUID,
                                                   withRxUUID: "1cce1ea8-bd34-4813-a00a-c76e028fadcb",
                                                   withTxUUID: "cacc07ff-ffff-4c48-8fae-a9ef71b75e26",
                                                   withSetModeUUID: "20b9794f-da1a-4d14-8014-a0fb9cefb2f7",
                                                   withEventUUID: "",
                                                   withCommandEnd: TxRxDeviceProfile.TerminatorType.CRLF.rawValue,
                                                   withRxPacketSize: 15,
                                                   withTxPacketSize: 20))
        
        // Zhaga TxRx
        _txRxSupportedDevices.append(TxRxDeviceProfile(inServiceUUID: ZHAGA_SERVICEUUID,
                                                   withRxUUID: "3cc30002-cb91-4947-bd12-80d2f0535a30",
                                                   withTxUUID: "3cc30003-cb91-4947-bd12-80d2f0535a30",
                                                   withSetModeUUID: "",
                                                   withEventUUID: "3cc30004-cb91-4947-bd12-80d2f0535a30",
                                                   withCommandEnd: TxRxDeviceProfile.TerminatorType.CR.rawValue,
                                                   withRxPacketSize: 240,
                                                   withTxPacketSize: 240))
        
        // Tertium TxRx
        _txRxSupportedDevices.append(TxRxDeviceProfile(inServiceUUID: TX_RX_TERTIUM_SERVICEUUID,
                                                   withRxUUID: "d7080002-052c-46c4-9978-c0977bebf328",
                                                   withTxUUID: "d7080003-052c-46c4-9978-c0977bebf328",
                                                   withSetModeUUID: "",
                                                   withEventUUID: "",
                                                   withCommandEnd: TxRxDeviceProfile.TerminatorType.CRLF.rawValue,
                                                   withRxPacketSize: 240,
                                                   withTxPacketSize: 240))
        
        // Tetium-Zebra TxRx
        _txRxSupportedDevices.append(TxRxDeviceProfile(inServiceUUID: ZEBRA_TERTIUM_SERVICEUUID,
                                                   withRxUUID: "c1ff0002-c47e-424d-9495-fb504404b8f5",
                                                   withTxUUID: "c1ff0003-c47e-424d-9495-fb504404b8f5",
                                                   withSetModeUUID: "",
                                                   withEventUUID: "",
                                                   withCommandEnd: TxRxDeviceProfile.TerminatorType.CRLF.rawValue,
                                                   withRxPacketSize: 240,
                                                   withTxPacketSize: 240))

        // Initialize Ble API
        _centralManager = CBCentralManager(delegate: self, queue: _dispatchQueue)
    }
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
            case .unknown, .resetting, .unsupported, .unauthorized, .poweredOff:
                masterCleanUp()
                _blueToothPoweredOn = false
            
            case .poweredOn:
                _blueToothPoweredOn = true
        @unknown default:
                //print("Unknown CBCentralManager state value, shutting bluetooth down")
                _blueToothPoweredOn = true
        }
    }
    
    /// Begins scanning of BLE devices
    ///
    /// NOTE: You cannot connect, send data nor receive data from devices when in scan mode
    public func startScan() {
        // Verify BlueTooth is powered on
        guard _blueToothPoweredOn == true else {
            sendBlueToothNotReadyOrLost()
            return
        }
        
        // Verify we aren't scanning already
        guard _isScanning == false else {
            sendScanError(errorCode: TxRxDeviceManagerErrors.ErrorCodes.ERROR_DEVICE_SCAN_ALREADY_STARTED, errorText: TxRxDeviceManagerErrors.S_ERROR_DEVICE_SCAN_ALREADY_STARTED)
            return
        }
        
        //
        _scannedDevices.removeAll()
        _isScanning = true
        
        // Initiate peripheral scan
        _centralManager.scanForPeripherals(withServices: nil, options: nil)
        
        // Inform delegate we began scanning
        if let delegate = _delegate {
            _callbackQueue.async{
                delegate.deviceScanBegan()
            }
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        //
        for device in _scannedDevices {
            if device.cbPeripheral.identifier == peripheral.identifier {
                //print("Duplicated peripheral identifier found. Filtered out")
                return
            }
        }
        
        // Instances a new TxRxDevice class keeping CoreBluetooth CBPeripheral class instance reference
        let newDevice: TxRxDevice = TxRxDevice(CBPeripheral: peripheral)
        
        // If peripheral name is supplied set it in the new device
        if let name = peripheral.name, name.isEmpty == false {
            newDevice.name = name
        }
        
        newDevice.indexedName = String(format: "%@_%lu", newDevice.name, _scannedDevices.count)
        
        //
        //print("Scanned device: ", peripheral)
        
        // Add the device to the array of scanned devices
        _scannedDevices.append(newDevice)
        
        // Dispatch call to delegate, we have found a BLE device
        if let delegate = _delegate {
            _callbackQueue.async{
                delegate.deviceFound(device: newDevice)
            }
        }
    }
    
    /// stopScan - Ends the scan of BLE devices
    ///
    /// NOTE: After scan ends you can connect to found devices
    public func stopScan() {
        // Verify BlueTooth is powered on
        guard _blueToothPoweredOn == true else {
            sendBlueToothNotReadyOrLost()
            return
        }
        
        // If we aren't scanning, report an error to the delegate
        guard _isScanning == true else {
            sendScanError(errorCode: TxRxDeviceManagerErrors.ErrorCodes.ERROR_DEVICE_SCAN_NOT_STARTED, errorText: TxRxDeviceManagerErrors.S_ERROR_DEVICE_SCAN_NOT_STARTED)
            return
        }
        
        // Stop bluetooth hardware from scanning devices
        _centralManager.stopScan()
        _isScanning = false
        
        // Inform delegate device scan ended. Its NOW possible to connect to devices
        if let delegate = _delegate {
            _callbackQueue.async{
                delegate.deviceScanEnded()
            }
        }
    }
    
    /// Tries to connect to a previously found (by startScan) BLE device
    ///
    /// NOTE: Connect is an asyncronous operation, delegate will be informed when and if connected
    ///
    /// NOTE: TxRxDeviceManager library will connect ONLY to Tertium BLE devices (service UUID and characteristic UUID will be matched)
    ///
    /// - parameter device: the TxRxDevice device to connect to, MUST be non null
    public func connectDevice(device: TxRxDevice) {
        // Verify BlueTooth is powered on
        guard _blueToothPoweredOn == true else {
            sendBlueToothNotReadyOrLost()
            return
        }

        // Verify we aren't scanning. Connect IS NOT supported while scanning for devices
        guard _isScanning == false else {
            sendUnabletoPerformDuringScan(device: device)
            return
        }
        
        // Verify we aren't already connecting to specified device
        guard _connectingDevices.contains(where: { $0 === device }) == false else {
            sendDeviceConnectError(device: device, errorCode: TxRxDeviceManagerErrors.ErrorCodes.ERROR_DEVICE_ALREADY_CONNECTING, errorText: TxRxDeviceManagerErrors.S_ERROR_DEVICE_ALREADY_CONNECTING)
            return
        }
        
        // Verify we aren't already connected to specified device
        guard _connectedDevices.contains(where: { $0 === device }) == false else {
            sendDeviceConnectError(device: device, errorCode: TxRxDeviceManagerErrors.ErrorCodes.ERROR_DEVICE_ALREADY_CONNECTED, errorText: TxRxDeviceManagerErrors.S_ERROR_DEVICE_ALREADY_CONNECTED)
            return
        }
        
        // Reset device states
        device.resetStates()

        // Create connect watchdog timer
        device.scheduleWatchdogTimer(inPhase: TxRxDeviceManagerPhase.PHASE_CONNECTING, withTimeInterval: _connectTimeout, withTargetFunc: self.watchDogTimerForConnectTick)
        
        // Device is added to the list of connecting devices
        _connectingDevices.append(device)
        
        // Inform CoreBluetooth we want to connect the specified peripheral. Answer will come via a callback
        _centralManager.connect(device.cbPeripheral, options: nil)
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        var device: TxRxDevice?
        
        // Search for the TxRxDevice class instance by the CoreBlueTooth peripheral instance
        device = deviceFromConnectingPeripheral(peripheral)
        guard device != nil else {
            return
        }
        
        if let error = error {
            // An error happened discovering services, report to delegate. For us, it's still CONNECT phase
            if let delegate = device?.delegate {
                let nsError = NSError(domain: TxRxDeviceManagerErrors.S_TERTIUM_TXRX_ERROR_DOMAIN, code: TxRxDeviceManagerErrors.ErrorCodes.ERROR_IOS_ERROR.rawValue, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription])
                
                _callbackQueue.async{
                    delegate.deviceConnectError(device: device!, error: nsError)
                }
            }
            
            removeDeviceFromCollection(collection: &_connectingDevices, device: device!)
            return
        }
    }
    
    /// Handles the timeout when connecting to a device
    ///
    /// - parameter timer: the timer instance which ticked
    /// - parameter device: the device to which connect failed
    private func watchDogTimerForConnectTick(timer: TxRxWatchDogTimer, device: TxRxDevice) {
        _centralManager.cancelPeripheralConnection(device.cbPeripheral)
        
        removeDeviceFromCollection(collection: &_connectingDevices, device: device)
        removeDeviceFromCollection(collection: &_connectedDevices, device: device)
        
        device.resetStates()
        
        sendDeviceConnectError(device: device, errorCode: TxRxDeviceManagerErrors.ErrorCodes.ERROR_DEVICE_CONNECT_TIMED_OUT, errorText:  TxRxDeviceManagerErrors.S_ERROR_DEVICE_CONNECT_TIMED_OUT)
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        var device: TxRxDevice?
        
        // Search for the TxRxDevice class instance by the CoreBlueTooth peripheral instance
        device = deviceFromConnectingPeripheral(peripheral)
        guard device != nil else {
            // We are connected to a unknown peripheral or a peripheral which connected past timeout time, disconnect from it
            _centralManager.cancelPeripheralConnection(peripheral)
            return
        }
        
        // Assign delegate of CoreBluetooth peripheral to our class
        peripheral.delegate = self
        device!.isConnected = true
        
        // Stop timeout watchdog timer
        device!.invalidateWatchDogTimer()
        
        // Device is connected, add it to the connected devices list and remove it from connecting devices list
        _connectedDevices.append(device!)
        removeDeviceFromCollection(collection: &_connectingDevices, device: device!)
        
        // Call delegate
        if let delegate = device?.delegate {
            _callbackQueue.async {
                delegate.deviceConnected(device: device!)
            }
        }
        
        // Ask CoreBluetooth to discover services for this peripheral
        peripheral.discoverServices(nil)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        var device: TxRxDevice?
        var tertiumService: CBService?
        
        // Search for the TxRxDevice class instance by the CoreBlueTooth peripheral instance
        device = deviceFromConnectedPeripheral(peripheral)
        guard device != nil else {
            sendInternalError(errorCode: TxRxDeviceManagerErrors.ErrorCodes.ERROR_DEVICE_NOT_FOUND, errorText: TxRxDeviceManagerErrors.S_ERROR_DEVICE_NOT_FOUND)
            return
        }
        
        if let error = error {
            // An error happened discovering services, report to delegate. For us, it's still CONNECT phase
            if let delegate = device?.delegate {
                let nsError = NSError(domain: TxRxDeviceManagerErrors.S_TERTIUM_TXRX_ERROR_DOMAIN, code: TxRxDeviceManagerErrors.ErrorCodes.ERROR_IOS_ERROR.rawValue, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription])
                
                //_callbackQueue.async{
                    delegate.deviceConnectError(device: device!, error: nsError)
                //}
            }
            
            return
        }
        
        if let services = peripheral.services {
            // Search for device service UUIDs. We use service UUID to map device to a Tertium BLE device profile. See class TxRxDeviceProfile for details
            for service: CBService in services {
                if device?.deviceProfile == nil {
                    for deviceProfile: TxRxDeviceProfile in _txRxSupportedDevices {
                        if service.uuid.isEqual(CBUUID(string: deviceProfile.txRxServiceUUID)) {
                            device?.deviceProfile = deviceProfile
                            tertiumService = service
                            break
                        }
                    }
                }
                
                if tertiumService != nil {
                    break
                }
            }
                        
            //
            if let tertiumService = tertiumService {
                // Instruct CoreBlueTooth to discover Tertium device service's characteristics
                //print("Discovering characteristic of service \(tertiumService.uuid.uuidString) of device \(String(describing: device?.name))")
                peripheral.discoverCharacteristics(nil, for: tertiumService)
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        var device: TxRxDevice?
        //var maxWriteLen: Int
        
        // Look for Tertium BLE device transmit and receive characteristics
        device = deviceFromConnectedPeripheral(peripheral)
        if let device = device, let characteristics = service.characteristics {
            for characteristic: CBCharacteristic in characteristics {
                if let deviceProfile = device.deviceProfile {
                    if characteristic.uuid.uuidString.caseInsensitiveCompare(deviceProfile.txCharacteristicUUID) == ComparisonResult.orderedSame {
                        // TX characteristic
                        peripheral.setNotifyValue(true, for: characteristic)
                        device.txChar = characteristic
                        
                        /*
                            if #available(iOS 9.0, *) {
                                //print("Peripheral maximumWriteValueLength = \(peripheral.maximumWriteValueLength)")

                                maxWriteLen = peripheral.maximumWriteValueLength(for: CBCharacteristicWriteType.withResponse)
                                //print("maximumWriteValueLength for txChar is \(maxWriteLen)")
                                //device.deviceProfile?.maxSendPacketSize = maxWriteLen
                            }
                        */
                        
                        //
                        if device.txChar != nil, device.rxChar != nil, let delegate = device.delegate {
                            _callbackQueue.async {
                                delegate.deviceReady(device: device)
                            }
                        }
                    } else if characteristic.uuid.uuidString.caseInsensitiveCompare(deviceProfile.rxCharacteristicUUID) == ComparisonResult.orderedSame {
                        // RX characteristic
                        device.rxChar = characteristic
                        
                        //
                        if device.txChar != nil, device.rxChar != nil, let delegate = device.delegate {
                            _callbackQueue.async {
                                delegate.deviceReady(device: device)
                            }
                        }
                    } else if characteristic.uuid.uuidString.caseInsensitiveCompare(deviceProfile.setModeCharacteristicUUID) == ComparisonResult.orderedSame {
                        // SetMode characteristic
                        peripheral.setNotifyValue(true, for: characteristic)
                        device.setModeChar = characteristic
                        
                        if let delegate = device.delegate {
                            _callbackQueue.async {
                                delegate.setModeCharacteristicDiscovered(device: device)
                            }
                        }
                    } else if characteristic.uuid.uuidString.caseInsensitiveCompare(deviceProfile.eventCharacteristicUUID) == ComparisonResult.orderedSame {
                        // Event characteristic
                        peripheral.setNotifyValue(true, for: characteristic)
                        device.eventChar = characteristic
                    }
                }
                
                //print(String(format: "Discovered characteristic \(characteristic.uuid.uuidString) of service \(service.uuid.uuidString) of device \(String(describing: device.name)) option mask %08lx", characteristic.properties.rawValue))
            }
        }
    }
    
    ///
    /// Check if the connected device is a TxRxAckme device
    ///
    /// - parameter device:the device get information from
    /// - returns - true if the connected device is a TxRxAckme, false otherwise.
    public func isTxRxAckme(device: TxRxDevice) -> Bool {
        if let deviceProfile = device.deviceProfile {
            return TX_RX_ACKME_SERVICEUUID == deviceProfile.txRxServiceUUID
        }
        
        return false
    }

    ///
    /// Check if the connected device is a TxRxAckme device
    ///
    /// - parameter device:the device get information from
    /// - returns - true if the connected device is a TxRxAckme, false otherwise.
    public func isTxRxZhaga(device: TxRxDevice) -> Bool {
        if let deviceProfile = device.deviceProfile {
            return ZHAGA_SERVICEUUID == deviceProfile.txRxServiceUUID
        }
        
        return false
    }

    /// Begins sending the Data byte buffer to a connected device.
    ///
    /// NOTE: you may ONLY send data to already connected devices
    ///
    /// NOTE: Data to device is sent in MTU fragments (refer to TxRxDeviceProfile maxSendPacketSize class attribute)
    ///
    /// - parameter device: the device to send the data (must be connected first!)
    /// - parameter data: Data class with contents of data to send
    public func sendData(device: TxRxDevice, data: Data) {
        //
        //print("sendData()\n");
        
        // Verify BlueTooth is powered on
        guard _blueToothPoweredOn == true else {
            sendBlueToothNotReadyOrLost()
            return
        }
        
        // Verify we arent't scanning for devices, we cannot interact with a device while in scanning mode
        guard _isScanning == false else {
            sendUnabletoPerformDuringScan(device: device)
            return
        }
        
        // Verify supplied devices is connected, we may only send data to connected devices
        guard _connectedDevices.contains(where: { $0 === device}) else {
            sendNotConnectedError(device: device)
            return
        }
        
        // Verify we have discovered required characteristics
        guard device.txChar != nil, device.rxChar != nil else {
            sendDeviceConnectError(device: device, errorCode: TxRxDeviceManagerErrors.ErrorCodes.ERROR_DEVICE_SERVICE_OR_CHARACTERISTICS_NOT_DISCOVERED_YET, errorText: TxRxDeviceManagerErrors.S_ERROR_DEVICE_SERVICE_OR_CHARACTERISTICS_NOT_DISCOVERED_YET)
            return
        }
        
        // Verify if we aren't already sending data to the device
        guard device.sendingData == false else {
            sendDeviceWriteError(device: device, errorCode: TxRxDeviceManagerErrors.ErrorCodes.ERROR_DEVICE_SENDING_DATA_ALREADY, errorText: TxRxDeviceManagerErrors.S_ERROR_DEVICE_SENDING_DATA_ALREADY)

            //
            //print("Unable to issue sendData, sending data already")
            return
        }
        
        guard device.waitingAnswer == false else {
            //
            //print("sendDeviceWriteError()\n");
            sendDeviceWriteError(device: device, errorCode: TxRxDeviceManagerErrors.ErrorCodes.ERROR_DEVICE_WAITING_COMMAND_ANSWER, errorText: TxRxDeviceManagerErrors.S_ERROR_DEVICE_WAITING_COMMAND_ANSWER)
            
            //
            //print("Unable to issue sendData, waiting for answer")
            return
        }
        
        if let deviceProfile = device.deviceProfile {
            var dataToSend = Data()
            dataToSend.append(data)
            if let commandEnd = deviceProfile.commandEnd.data(using: String.Encoding.ascii) {
                // We need to append commandEnd to the data so BLE device will understand when the command ends
                dataToSend.append(commandEnd)
                device.setDataToSend(data: dataToSend)
                device.sendingData = true
                
                //
                //print("Issuing senddata")

                // Commence data sending to device
                deviceSendDataPiece(device)
            }
        }
    }
    
    /// Sends a fragment of data to the device
    ///
    /// NOTE: This method is also called in response to CoreBlueTooth send data fragment acknowledgement to send data pieces to the device
    ///
    /// - parameter device: The device to send data to
    private func deviceSendDataPiece(_ device: TxRxDevice) {
        var packet: Data?
        var packetSize: Int
        
        //
        //print("deviceSendDataPiece\n");
        guard _connectedDevices.contains(where: { $0 === device}) else {
            sendDeviceWriteError(device: device, errorCode: TxRxDeviceManagerErrors.ErrorCodes.ERROR_DEVICE_NOT_CONNECTED, errorText: TxRxDeviceManagerErrors.S_ERROR_DEVICE_NOT_CONNECTED)
            return;
        }
        
        guard device.sendingData == true else {
            sendInternalError(device: device, errorCode: TxRxDeviceManagerErrors.ErrorCodes.ERROR_DEVICE_NOT_SENDING_DATA, errorText: TxRxDeviceManagerErrors.S_ERROR_DEVICE_NOT_SENDING_DATA)

            //
            //print("Unable to issue sendData, sending data already")
            return;
        }
        
        if device.totalBytesSent < device.bytesToSend {
            // We still have to send buffer pieces
            if let deviceProfile = device.deviceProfile {
                if let dataToSend = device.dataToSend {
                    // Determine max send packet size
                    if (deviceProfile.txPacketSize + device.totalBytesSent < device.bytesToSend) {
                        packetSize = deviceProfile.txPacketSize
                    } else {
                        packetSize = device.bytesToSend - device.totalBytesSent;
                    }
                    
                    //
                    //print("deviceSendDataPiece, totalBytesSent = \(device.totalBytesSent), bytesToSend = \(device.bytesToSend), calculated packetSize = \(packetSize)")
                    
                    // Create a data packet from the buffer supplied by the caller
                    packet = dataToSend.subdata(in: device.totalBytesSent ..< device.totalBytesSent+packetSize)
                    if let packet = packet, let rxChar = device.rxChar {
                        // Send data to device with bluetooth response feedback
                        device.cbPeripheral.writeValue(packet, for: rxChar, type: .withResponse)
                        device.bytesSent = packetSize
                        
                        // Enable recieve watchdog timer for send acknowledgement
                        var timeOut: Double
                        
                        if (device.totalBytesSent == 0) {
                            timeOut = _receiveFirstPacketTimeout
                        } else {
                            timeOut = _receivePacketsTimeout
                        }
                        
                        //
                        //print("sending data piece")
                        
                        device.scheduleWatchdogTimer(inPhase: TxRxDeviceManagerPhase.PHASE_WAITING_SEND_ACK, withTimeInterval: timeOut, withTargetFunc: self.watchDogTimerTickReceivingSendAck)
                    }
                }
            }
        }
        
        if device.totalBytesSent >= device.bytesToSend {
            //
            //print("sent all data, waiting answer")
            
            // All buffer contents have been sent
            device.sendingData = false
            device.dataToSend = nil
            
            // Enable recieve watchdog timer. Waiting for response from Tertium BLE device
            device.scheduleWatchdogTimer(inPhase: TxRxDeviceManagerPhase.PHASE_RECEIVING_DATA, withTimeInterval: _receiveFirstPacketTimeout, withTargetFunc: self.watchDogTimerTickReceivingData)
            
            //
            //print("device.waitingAnswer = true\n");
            
            //
            device.waitingAnswer = true
            return
        }
    }
    
    /// Handles receive bluetooth send feedback timeouts
    ///
    /// - parameter timer: the TxRxWatchDogTimer instance which handled the timeout
    /// - parameter device: the device to which connect failed
    private func watchDogTimerTickReceivingSendAck(timer: TxRxWatchDogTimer, device: TxRxDevice) {
        //
        //print("watchDogTimerTickReceivingSendAck()")
        
        device.sendingData = false
        if device.settingMode {
            device.settingMode = false
            if let delegate = device.delegate {
                delegate.setModeError(device: device, errorCode: TxRxDeviceManagerErrors.ErrorCodes.ERROR_SET_MODE.rawValue)
                return
            }
        }
        
        sendDeviceWriteError(device: device, errorCode: TxRxDeviceManagerErrors.ErrorCodes.ERROR_DEVICE_SENDING_DATA_TIMEOUT, errorText: TxRxDeviceManagerErrors.S_ERROR_DEVICE_SENDING_DATA_TIMEOUT)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        var device: TxRxDevice?
        
        //
        //print("---- didWriteValueFor characteristic() ----")
        
        device = deviceFromConnectedPeripheral(peripheral)
        if let device = device {
            if let error = error {
                // There has been a write error
                device.settingMode = false
                device.sendingData = false
                let nsError = NSError(domain: TxRxDeviceManagerErrors.S_TERTIUM_TXRX_ERROR_DOMAIN, code: TxRxDeviceManagerErrors.ErrorCodes.ERROR_IOS_ERROR.rawValue, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription])
                if let delegate = device.delegate {
                    //_callbackQueue.async {
                        delegate.deviceWriteError(device: device, error: nsError)
                    //}
                }
                
                //
                //print("SENDACK ERROR: " + error.localizedDescription)
                
                // There has been an error, invalidate WatchDog timer
                device.invalidateWatchDogTimer()
                return
            }
            
            // Send data acknowledgement arrived in time, stop the watchdog timer
            device.invalidateWatchDogTimer()
            
            if characteristic == device.rxChar {
                // Update device's total bytes sent and try to send more data
                device.totalBytesSent += device.bytesSent
                //_dispatchQueue.async {
                    self.deviceSendDataPiece(device)
                //}
            } else if characteristic == device.setModeChar {
                // nothing to do here
            } else {
                //print("Error! Unexpected write on characteristic \(characteristic)")
            }
        }
    }
    
    /// Watchdog for timeouts on BLE device answer to previously issued command
    ///
    /// - parameter timer: the timer instance which handled the timeout
    /// - parameter device: the device on which the read operation timed out
    private func watchDogTimerTickReceivingData(_ timer: TxRxWatchDogTimer, device: TxRxDevice) {
        // Verify what we have received data
        //var text: String
        
        //
        //print("watchDogTimerTickReceivingData()\n")
        
        // Verify terminator is ok, otherwise we may haven't received a whole response and there has been a receive error or receive timed out
        //text = String(data: device.receivedData, encoding: String.Encoding.ascii) ?? ""
        //if isTerminatorOK(device: device, text: text) {
        if device.receivedData.count != 0 {
            // REMOVE
            //print("COMMAND ANSWER RECEIVED, TERMINATOR OK")
            
            //
            //print("watchDogTimerTickReceivingData, device.waitingAnswer = false\n");
            
            //
            device.waitingAnswer = false
            
            if let delegate = device.delegate {
                //
                //print("watchDogTimerTickReceivingData, active receive\n");

                let dispatchData = Data(device.receivedData)
                device.resetReceivedData()
                _callbackQueue.async {
                    delegate.receivedData(device: device, data: dispatchData)
                }
            } else {
                device.resetReceivedData()
            }
        } else {
            //
            //print("COMMAND ANSWER RECEIVED BUT TERMINATOR NOT OK. DATALEN: ", device.receivedData.count," DATA: ", String(data: device.receivedData, encoding: .ascii)!)
            
            //
            //print("watchDogTimerTickReceivingData, device.waitingAnswer = false\n");

            //
            device.waitingAnswer = false
            
            device.resetReceivedData()
            sendDeviceReadError(device: device, errorCode: TxRxDeviceManagerErrors.ErrorCodes.ERROR_DEVICE_RECEIVING_DATA_TIMEOUT, errorText: TxRxDeviceManagerErrors.S_ERROR_DEVICE_RECEIVING_DATA_TIMEOUT)
        }
    }
    
    /// Watchdog for timeouts for receiving data from event characteristic
    ///
    /// - parameter timer: the timer instance which handled the timeout
    /// - parameter device: the device on which the read operation timed out
    private func watchDogTimerTickReceivingEventData(_ timer: TxRxWatchDogTimer, device: TxRxDevice) {
        //
        device.eventWatchdogTimer?.stop()
        device.eventWatchdogTimer = nil
        
        //
        if device.eventData.count != 0 {
            // if we received data send it to the delegate
            let dataCopy = Data(device.eventData)
            device.eventData = Data()
            
            // Notify delegate of the received event data
            if let delegate = device.delegate {
                delegate.receivedEventData(device: device, data: dataCopy)
            }
        } else {
            // We didn't receive any data despite the watchdog, send error to the delegate
            sendDeviceReadError(device: device, errorCode: TxRxDeviceManagerErrors.ErrorCodes.ERROR_DEVICE_RECEIVING_DATA_TIMEOUT, errorText: TxRxDeviceManagerErrors.S_ERROR_DEVICE_RECEIVING_DATA_TIMEOUT)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
		var device: TxRxDevice?
        
		device = deviceFromConnectedPeripheral(peripheral)
        if let device = device {
            //
            //print("didUpdateValueFor characteristic, device.waitingAnswer = false")
            
            //
            device.waitingAnswer = false
            
            if let error = error {
                //
                //print("didUpdateValueFor characteristic, error: ", error.localizedDescription)
                
                // There has been an error receiving data
                if let delegate = device.delegate {
                    let nsError = NSError(domain: TxRxDeviceManagerErrors.S_TERTIUM_TXRX_ERROR_DOMAIN, code: TxRxDeviceManagerErrors.ErrorCodes.ERROR_IOS_ERROR.rawValue, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription])
                    _callbackQueue.async {
                        delegate.deviceReadError(device: device, error: nsError)
                    }
                }
                
                // Device read error, stop WatchDogTimer
                device.invalidateWatchDogTimer()
                return
            }
            
            if characteristic == device.txChar {
                // We received data from peripheral
                if let value = characteristic.value {
                    let data: Data = Data(value)
                    
                    //
                    //print("didUpdateValueFor characteristic, data received: ", String(data: data, encoding: .ascii)!)
                    
                    //
                    device.receivedData.append(data)
                    
                    //
                    //print("didUpdateValueFor characteristic, data so far: ", String(data: device.receivedData, encoding: .ascii)!)
                    
                    if device.watchDogTimer == nil {
                        //
                        //print("didUpdateValueFor characteristic, passive receive")

                        // Passive receive
                        if let delegate = device.delegate {
                            _callbackQueue.async {
                                delegate.receivedData(device: device, data: data)
                            }
                        }
                    } else {
                        // Schedule a new watchdog timer for receiving data packets
                        device.scheduleWatchdogTimer(inPhase: TxRxDeviceManagerPhase.PHASE_RECEIVING_DATA, withTimeInterval: _receivePacketsTimeout, withTargetFunc: self.watchDogTimerTickReceivingData)
                    }
                }
            } else if characteristic == device.setModeChar {
                // Received mode change notify
                if device.settingMode == false {
                    //
                    //print("Unexpected mode change happened!")
                }
                
                //
                device.settingMode = false
                
                if let value = characteristic.value {
                    let array = [UInt8](value)
                    if array.count != 0 {
                        device.currentOperationalMode = UInt(array[0])
                        if let delegate = device.delegate {
                            _callbackQueue.async {
                                delegate.hasSetMode(device: device, operationalMode: device.currentOperationalMode)
                            }
                        }
                    } else {
                        //print("Error while receiving update value for set mode characteristic, data to string conversion failed")
                    }
                } else {
                    //print("Error while receiving update value for set mode characteristic")
                    if let delegate = device.delegate {
                        _callbackQueue.async {
                            delegate.setModeError(device: device, errorCode: TxRxDeviceManagerErrors.ErrorCodes.ERROR_SET_MODE.rawValue)
                        }
                    }
                }
            } else if characteristic == device.eventChar {
                // We received data from event characteristic
                if let value = characteristic.value {
                    if device.eventWatchdogTimer == nil {
                        // Check if we have setup a watchdog timer for event characteristic, when the watchdog
                        // fires we'll send accumulated event data to the delegate
                        device.scheduleEventWatchdogTimer(inPhase: TxRxDeviceManagerPhase.PHASE_RECEIVING_EVENT_DATA, withTimeInterval: _receivePacketsTimeout, withTargetFunc: self.watchDogTimerTickReceivingEventData)
                    }
                    
                    device.eventData.append(value)
                }
            }
        }
	}
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateForCharacteristicFor characteristic: CBCharacteristic, error: Error?) {
        var device: TxRxDevice?
        
        device = deviceFromConnectedPeripheral(peripheral)
        if let device = device {
            //
            device.waitingAnswer = false
            
            //
            //print("didUpdateValueFor, receiving data")

            if let error = error {
                //
                //print("didUpdateNotificationStateFor error: ", error.localizedDescription)
                
                // There has been an error receiving data
                if let delegate = device.delegate {
                    let nsError = NSError(domain: TxRxDeviceManagerErrors.S_TERTIUM_TXRX_ERROR_DOMAIN, code: TxRxDeviceManagerErrors.ErrorCodes.ERROR_IOS_ERROR.rawValue, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription])
                    _callbackQueue.async {
                        delegate.deviceReadError(device: device, error: nsError)
                    }
                }
                
                // Device read error, stop WatchDogTimer
                device.invalidateWatchDogTimer()
                return
            }
            
            if characteristic == device.txChar {
                // We received data from peripheral
                if let value = characteristic.value {
                    let data: Data = Data(value)
                    
                    //
                    //print("didUpdateNotificationStateFor, data received: ", String(data: data, encoding: .ascii)!)
                    
                    //
                    device.receivedData.append(data)
                    
                    //
                    //print("didUpdateNotificationStateFor, data so far: ", String(data: device.receivedData, encoding: .ascii)!)
                    
                    if device.watchDogTimer == nil {
                        //
                        //print("didUpdateNotificationStateFor, passive receive")

                        // Passive receive
                        if let delegate = device.delegate {
                            _callbackQueue.async {
                                delegate.receivedData(device: device, data: data)
                            }
                        }
                    } else {
                        // Schedule a new watchdog timer for receiving data packets
                        device.scheduleWatchdogTimer(inPhase: TxRxDeviceManagerPhase.PHASE_RECEIVING_DATA, withTimeInterval: _receivePacketsTimeout, withTargetFunc: self.watchDogTimerTickReceivingData)
                    }
                }
            } else {
                //print("Data received from unknown characteristic")
            }
        }
    }
    
    /// Disconnect a previously connected device
    ///
    /// - parameter device: The device to disconnect, MUST be non null
    public func disconnectDevice(device: TxRxDevice) {
        // Verify BlueTooth is powered on
        guard _blueToothPoweredOn == true else {
            sendBlueToothNotReadyOrLost()
            return
        }
        
        // We can't disconnect while scanning for devices
        guard _isScanning == false else {
            sendUnabletoPerformDuringScan(device: device)
            return
        }
        
        // Verify device is truly connected
        guard _connectedDevices.contains(where: { $0 === device}) == true else {
            sendNotConnectedError(device: device)
            return
        }
        
        // Verify we aren't disconnecting already from the device (we may be waiting for disconnect ack)
        guard _disconnectingDevices.contains(where: { $0 === device}) == false else {
            sendDeviceConnectError(device: device, errorCode: TxRxDeviceManagerErrors.ErrorCodes.ERROR_DEVICE_ALREADY_DISCONNECTING, errorText: TxRxDeviceManagerErrors.S_ERROR_ALREADY_DISCONNECTING)
            return
        }
        
        // Create a disconnect watchdog timer
        device.scheduleWatchdogTimer(inPhase: TxRxDeviceManagerPhase.PHASE_DISCONNECTING, withTimeInterval: _connectTimeout, withTargetFunc:  self.watchDogTimerForDisconnectTick)
        
        // Add the device to the list of disconnecting devices
        _disconnectingDevices.append(device);
        
        // Ask CoreBlueTooth to disconnect the device
        _centralManager.cancelPeripheralConnection(device.cbPeripheral)
    }
    
    /// Verifies disconnecting a device happens is in a timely fashion
    ///
    /// - parameter timer: the timer instance which fires the check function
    /// - parameter device: the device which didn't disconnect in time
    private func watchDogTimerForDisconnectTick(_ timer: TxRxWatchDogTimer, device: TxRxDevice) {
        // Disconnecting device timed out, we received no feedback. We consider the device disconnected anyway.
        removeDeviceFromCollection(collection: &_disconnectingDevices, device: device)
        removeDeviceFromCollection(collection: &_connectedDevices, device: device)
        removeDeviceFromCollection(collection: &_connectingDevices, device: device)
        
        //
        device.resetStates()
        
        // Inform delegate device disconnet timed out
        sendDeviceConnectError(device: device, errorCode: TxRxDeviceManagerErrors.ErrorCodes.ERROR_DEVICE_DISCONNECT_TIMED_OUT, errorText: TxRxDeviceManagerErrors.S_ERROR_DEVICE_DISCONNECT_TIMED_OUT)
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        var device: TxRxDevice?
        
        device = deviceFromKnownPeripheral(peripheral)
        if let device = device {
            if let error = error {
                // There has been an error disconnecting the device
                if let delegate = device.delegate {
                    let nsError = NSError(domain: TxRxDeviceManagerErrors.S_TERTIUM_TXRX_ERROR_DOMAIN, code: TxRxDeviceManagerErrors.ErrorCodes.ERROR_IOS_ERROR.rawValue, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription])
                    _callbackQueue.async {
                        delegate.deviceConnectError(device: device, error: nsError)
                    }
                }
                
                // Consider the device disconnected anyway
            }
            
            // A peripheral has been disconnected. Remove device from internal validation arrays and inform delegate of the disconnection
            device.invalidateWatchDogTimer()
            device.resetStates()

            removeDeviceFromCollection(collection: &_connectedDevices, device: device)
            removeDeviceFromCollection(collection: &_connectingDevices, device: device)
            removeDeviceFromCollection(collection: &_disconnectingDevices, device: device)
            
            if let delegate = device.delegate {
                _callbackQueue.async {
                    delegate.deviceDisconnected(device: device)
                }
            }
        }
    }
    
    /// Verifies if the data received from BLE devices has the correct terminator (whether a command is finished)
    ///
    /// - parameter device: the device which received data
    /// - parameter text: the data received in ASCII format
    private func isTerminatorOK(device: TxRxDevice, text: String?) -> Bool {
        if (text == nil || text!.count == 0) {
            return false;
        }
        
        return text!.hasSuffix(device.deviceProfile!.commandEnd)
    }
    
    /// Retrieves the TxRxManagerDevice instance from CoreBlueTooth CBPeripheral class from connecting devices
    ///
    /// - parameter peripheral: the CoreBlueTooth peripheral
    private func deviceFromConnectingPeripheral(_ peripheral: CBPeripheral) -> TxRxDevice? {
        for device: (TxRxDevice) in _connectingDevices {
            if (device.cbPeripheral == peripheral) {
                return device;
            }
        }
        
        return nil;
    }
    
    /// Retrieves the TxRxManagerDevice instance from CoreBlueTooth CBPeripheral class from connected devices
    ///
    /// - parameter peripheral: the CoreBlueTooth peripheral
    private func deviceFromConnectedPeripheral(_ peripheral: CBPeripheral) -> TxRxDevice? {
        for device: (TxRxDevice) in _connectedDevices {
            if (device.cbPeripheral == peripheral) {
                return device;
            }
        }
        
        return nil;
    }
    
    /// Retrieves the TxRxManagerDevice instance from CoreBlueTooth CBPeripheral class from disconnecting devices
    ///
    /// - parameter peripheral: the CoreBlueTooth peripheral
    private func deviceFromDisconnectingPeripheral(_ peripheral: CBPeripheral) -> TxRxDevice? {
        for device: (TxRxDevice) in _connectedDevices {
            if (device.cbPeripheral == peripheral) {
                return device;
            }
        }
        
        return nil;
    }
    
    /// Retrieves the TxRxManagerDevice instance from CoreBlueTooth CBPeripheral class from connecting and connected collections
    ///
    /// - parameter peripheral: the CoreBlueTooth peripheral
    private func deviceFromKnownPeripheral(_ peripheral: CBPeripheral) -> TxRxDevice? {
        for device: (TxRxDevice) in _connectedDevices {
            if (device.cbPeripheral == peripheral) {
                return device;
            }
        }
        
        for device: (TxRxDevice) in _connectingDevices {
            if (device.cbPeripheral == peripheral) {
                return device;
            }
        }
        
        for device: (TxRxDevice) in _disconnectingDevices {
            if (device.cbPeripheral == peripheral) {
                return device;
            }
        }
        
        return nil;
    }

    /// Destroys every TxRxDevice instance, usually called when and if CoreBluetooth shuts down
    private func masterCleanUp() {
        for device: (TxRxDevice) in _scannedDevices {
            device.invalidateWatchDogTimer()
            device.resetStates()
        }
        _scannedDevices.removeAll()
        
        for device: (TxRxDevice) in _connectingDevices {
            device.invalidateWatchDogTimer()
            device.resetStates()
        }
        _connectingDevices.removeAll()
        
        for device: (TxRxDevice) in _connectedDevices {
            device.invalidateWatchDogTimer()
            device.resetStates()
        }
        _connectedDevices.removeAll()
        
        for device: (TxRxDevice) in _disconnectingDevices {
            device.invalidateWatchDogTimer()
            device.resetStates()
        }
        _disconnectingDevices.removeAll()
        
        _isScanning = false
        if _blueToothPoweredOn == true {
            sendBlueToothNotReadyOrLost()
        }
    }
    
    /// Safely remove a device from a collection
    private func removeDeviceFromCollection(collection: inout [TxRxDevice], device: TxRxDevice) {
        if let idx = collection.firstIndex(of: device) {
            collection.remove(at: idx)
        }
    }
    
    /// Informs the delegate CoreBluetooth or BlueTooth hardware is not ready or lost
    private func sendBlueToothNotReadyOrLost() {
        sendInternalError(errorCode: TxRxDeviceManagerErrors.ErrorCodes.ERROR_BLUETOOTH_NOT_READY_OR_LOST, errorText: TxRxDeviceManagerErrors.S_ERROR_BLUETOOTH_NOT_READY_OR_LOST)
    }

    /// Informs the delegate a device scanning error occoured
    ///
    /// - parameter errorCode: the errorcode
    /// - parameter errorText: a human readable error text
    private func sendScanError(errorCode: TxRxDeviceManagerErrors.ErrorCodes, errorText: String) {
        if let delegate = _delegate {
            let error = NSError(domain: TxRxDeviceManagerErrors.S_TERTIUM_TXRX_ERROR_DOMAIN, code: errorCode.rawValue, userInfo: [NSLocalizedDescriptionKey: errorText])
            _callbackQueue.async {
                delegate.deviceScanError(error: error)
            }
        }
    }

    /// Informs the delegate a device connect error occoured
    ///
    /// - parameter device: the device on which the error occoured
    /// - parameter errorCode: the errorcode
    /// - parameter errorText: a human readable error text
    private func sendDeviceConnectError(device: TxRxDevice, errorCode: TxRxDeviceManagerErrors.ErrorCodes, errorText: String) {
        if let delegate = device.delegate {
            let error = NSError(domain: TxRxDeviceManagerErrors.S_TERTIUM_TXRX_ERROR_DOMAIN, code: errorCode.rawValue, userInfo: [NSLocalizedDescriptionKey: errorText])
            _callbackQueue.async {
                delegate.deviceConnectError(device: device, error: error);
            }
        }
    }
    
    /// Informs the delegate a device write error occoured
    ///
    /// - parameter device: the device on which the error occoured
    /// - parameter errorCode: the errorcode
    /// - parameter errorText: a human readable error text
    private func sendDeviceWriteError(device: TxRxDevice, errorCode: TxRxDeviceManagerErrors.ErrorCodes, errorText: String) {
        if let delegate = device.delegate {
            let error = NSError(domain: TxRxDeviceManagerErrors.S_TERTIUM_TXRX_ERROR_DOMAIN, code: errorCode.rawValue, userInfo: [NSLocalizedDescriptionKey: errorText])
            _callbackQueue.async {
                delegate.deviceWriteError(device: device, error: error);
            }
        }
    }
    
    /// Informs the delegate an operation which needed the device to be connected has been called on a not connected device
    ///
    /// - parameter device: the device on which the error occoured
    private func sendNotConnectedError(device: TxRxDevice) {
        if let delegate = device.delegate {
            let error = NSError(domain: TxRxDeviceManagerErrors.S_TERTIUM_TXRX_ERROR_DOMAIN, code: TxRxDeviceManagerErrors.ErrorCodes.ERROR_DEVICE_NOT_CONNECTED.rawValue, userInfo: [NSLocalizedDescriptionKey: TxRxDeviceManagerErrors.S_ERROR_DEVICE_NOT_CONNECTED])
            _callbackQueue.async {
                delegate.deviceConnectError(device: device, error: error);
            }
        }
    }
    
    /// Informs the delegate an operation which is not possibile to be done under device scan has been requested
    ///
    /// - parameter device: the device on which the error occoured
    private func sendUnabletoPerformDuringScan(device: TxRxDevice) {
        if let delegate = device.delegate {
            let error = NSError(domain: TxRxDeviceManagerErrors.S_TERTIUM_TXRX_ERROR_DOMAIN, code: TxRxDeviceManagerErrors.ErrorCodes.ERROR_DEVICE_UNABLE_TO_PERFORM_DURING_SCAN.rawValue, userInfo: [NSLocalizedDescriptionKey: TxRxDeviceManagerErrors.S_ERROR_DEVICE_UNABLE_TO_PERFORM_DURING_SCAN])
            _callbackQueue.async {
                delegate.deviceConnectError(device: device, error: error);
            }
        }
    }
        
    /// Informs the delegate a device read error occoured
    ///
    /// - parameter device: the device on which the error occoured
    /// - parameter errorCode: the errorcode
    /// - parameter errorText: a human readable error text
    private func sendDeviceReadError(device: TxRxDevice, errorCode: TxRxDeviceManagerErrors.ErrorCodes, errorText: String) {
        if let delegate = device.delegate {
            let error = NSError(domain: TxRxDeviceManagerErrors.S_TERTIUM_TXRX_ERROR_DOMAIN, code: errorCode.rawValue, userInfo: [NSLocalizedDescriptionKey: errorText])
            _callbackQueue.async {
                delegate.deviceReadError(device: device, error: error);
            }
        }
    }
    
    /// Informs the delegate a critical error occoured
    ///
    /// - parameter errorCode: the errorcode
    /// - parameter errorText: a human readable error text
    private func sendInternalError(errorCode: TxRxDeviceManagerErrors.ErrorCodes, errorText: String) {
        if let delegate = _delegate {
            let error = NSError(domain: TxRxDeviceManagerErrors.S_TERTIUM_TXRX_ERROR_DOMAIN, code: errorCode.rawValue, userInfo: [NSLocalizedDescriptionKey: errorText])
            _callbackQueue.async {
                delegate.deviceScanError(error: error)
            }
        }
    }
    
    /// Informs the device delegate a critical error occoured on a device
    ///
    /// - parameter device: the device on which the error occoured
    /// - parameter errorCode: the errorcode
    /// - parameter errorText: a human readable error text
    private func sendInternalError(device: TxRxDevice, errorCode: TxRxDeviceManagerErrors.ErrorCodes, errorText: String) {
        if let delegate = device.delegate {
            let error = NSError(domain: TxRxDeviceManagerErrors.S_TERTIUM_TXRX_ERROR_DOMAIN, code: errorCode.rawValue, userInfo: [NSLocalizedDescriptionKey: errorText])
            _callbackQueue.async {
                delegate.deviceError(device:device, error: error)
            }
        }
    }
    
    /// Returns an instance of TxRxDevice from device's name
    ///
    /// - parameter device: the device name
    /// - returns: the device instance, if found, otherwise nil
    public func deviceFromDeviceName(name: String) -> TxRxDevice? {
        for device in _scannedDevices {
            if device.name.caseInsensitiveCompare(name) == ComparisonResult.orderedSame {
                return device
            }
        }
        
        return nil
    }
    
    /// Returns the device name from an instance of TxRxDevice
    ///
    /// - parameter device: the device instance
    /// - returns: the device name
    public func getDeviceName(device: TxRxDevice) -> String {
        return device.name;
    }
    
    ///
    /// Set the operation mode to use during the communication with the device.
    ///
    /// A callback will be invoked when the operation will reporting the result of the SetMode operation
    ///
    /// Otherwise a callback will be invoked on SetMode error.
    ///
    /// @param mode UInt the operation mode to apply
    /// @return true if the operation mode can be set and the SetMode operation was initiated successfully, false
    /// otherwise
    public func setMode(device: TxRxDevice, mode: UInt) {
        // Verify BlueTooth is powered on
        guard _blueToothPoweredOn == true else {
            sendBlueToothNotReadyOrLost()
            return
        }
        
        // Verify we arent't scanning for devices, we cannot interact with a device while in scanning mode
        guard _isScanning == false else {
            sendUnabletoPerformDuringScan(device: device)
            return
        }
        
        // Verify supplied devices is connected, we may only send data to connected devices
        guard _connectedDevices.contains(where: { $0 === device}) else {
            sendNotConnectedError(device: device)
            return
        }
        
        // Verify we have discovered required characteristics
        guard device.setModeChar != nil else {
            if let delegate = device.delegate {
                delegate.setModeError(device: device, errorCode: TxRxDeviceManagerErrors.ErrorCodes.ERROR_SET_MODE_INVALID_CHARACTERISTIC.rawValue)
            }
            return
        }
        
        // Verify if we aren't already sending data to the device
        guard device.sendingData == false else {
            sendDeviceWriteError(device: device, errorCode: TxRxDeviceManagerErrors.ErrorCodes.ERROR_DEVICE_SENDING_DATA_ALREADY, errorText: TxRxDeviceManagerErrors.S_ERROR_DEVICE_SENDING_DATA_ALREADY)

            return
        }
        
        // Verify we aren't already waiting for an answer
        guard device.waitingAnswer == false else {
            sendDeviceWriteError(device: device, errorCode: TxRxDeviceManagerErrors.ErrorCodes.ERROR_DEVICE_WAITING_COMMAND_ANSWER, errorText: TxRxDeviceManagerErrors.S_ERROR_DEVICE_WAITING_COMMAND_ANSWER)

            return
        }
        
        // Verify we aren't setting mode already
        guard device.settingMode == false else {
            if let delegate = device.delegate {
                delegate.setModeError(device: device, errorCode: TxRxDeviceManagerErrors.ErrorCodes.ERROR_SET_MODE_OPERATION_IN_PROGRESS.rawValue)
            }

            return
        }
        
        // Send data to device with bluetooth response feedback
        // Setting device operational mode
        device.settingMode = true
        device.cbPeripheral.writeValue(Data([UInt8(mode)]), for: device.setModeChar!, type: .withResponse)
        
        //
        device.scheduleWatchdogTimer(inPhase: TxRxDeviceManagerPhase.PHASE_WAITING_SEND_ACK, withTimeInterval: _receiveFirstPacketTimeout, withTargetFunc: self.watchDogTimerTickReceivingSendAck)
        return
    }
    
    // APACHE CORDOVA UTILITY METHODS
    
    /// Returns an instance of TxRxDevice from device's indexed name
    ///
    /// - parameter device: the device indexed name
    /// - returns: the device instance, if found, otherwise nil
    public func deviceFromIndexedName(name: String) -> TxRxDevice? {
        for device in _scannedDevices {
            if device.indexedName.caseInsensitiveCompare(name) == ComparisonResult.orderedSame {
                return device
            }
        }
        
        return nil
    }
    
    /// Returns an instance of TxRxDevice from device's indexed name
    ///
    /// - parameter device: the device to get indexed name from
    /// - returns: the device instance, if found, otherwise nil
    public func getDeviceIndexedName(device: TxRxDevice) -> String {
        return device.indexedName
    }
    
    /// Resets timeout values to default values
    public func setTimeOutDefaults() {
        _connectTimeout = 20.0
        _receiveFirstPacketTimeout = 2
        _receivePacketsTimeout = 0.2
        _writePacketTimeout = 1.5
    }
    
    /// Returns the timeout value for the specified timeout event
    ///
    /// - parameter timeOutType: the timeout event
    /// - returns: the event timeout value, in MILLISECONDS
    public func getTimeOutValue(timeOutType: String) -> UInt32 {
        switch (timeOutType) {
            case TxRxDeviceManagerTimeouts.S_TERTIUM_TIMEOUT_CONNECT:
                return UInt32(_connectTimeout * 1000.0)
            
            case TxRxDeviceManagerTimeouts.S_TERITUM_TIMEOUT_RECEIVE_FIRST_PACKET:
                return UInt32(_receiveFirstPacketTimeout * 1000.0)

            case TxRxDeviceManagerTimeouts.S_TERTIUM_TIMEOUT_RECEIVE_PACKETS:
                return UInt32(_receivePacketsTimeout * 1000.0)

            case TxRxDeviceManagerTimeouts.S_TERTIUM_TIMEOUT_SEND_PACKET:
                return UInt32(_writePacketTimeout * 1000.0)
            
            default:
                return 0
        }
    }
    
    /// Sets the current timeout value for the specified timeout event
    ///
    /// - parameter timeOutValue: the timeout value, in MILLISECONDS
    /// - parameter timeOutType: the timeout event
    public func setTimeOutValue(timeOutValue: UInt32, timeOutType: String) {
        switch (timeOutType) {
            case TxRxDeviceManagerTimeouts.S_TERTIUM_TIMEOUT_CONNECT:
                _connectTimeout = Double(timeOutValue) / 1000.0
            
            case TxRxDeviceManagerTimeouts.S_TERITUM_TIMEOUT_RECEIVE_FIRST_PACKET:
                _receiveFirstPacketTimeout = Double(timeOutValue) / 1000.0
            
            case TxRxDeviceManagerTimeouts.S_TERTIUM_TIMEOUT_RECEIVE_PACKETS:
                _receivePacketsTimeout = Double(timeOutValue) / 1000.0
            
            case TxRxDeviceManagerTimeouts.S_TERTIUM_TIMEOUT_SEND_PACKET:
                _writePacketTimeout = Double(timeOutValue) / 1000.0
            
            default:
                return
        }
    }
}
