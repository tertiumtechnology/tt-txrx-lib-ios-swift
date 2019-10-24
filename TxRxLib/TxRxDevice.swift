/*
 * The MIT License
 *
 * Copyright 2017 Tertium Technology.
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

/// Implements an instance of Tertium BLE device
public class TxRxDevice: NSObject {
    /// This device's delegate. Delegate will receive data exchange information specified in TxRxDeviceDataProtocol
    public var delegate: TxRxDeviceDataProtocol? = nil
    
    /// This device's name. When a device doesn't supply a name "Unnamed device" will be used
    public internal(set) var name: String = "Unnamed device"
    
    /// This device's indexed name. When a device doesn't supply a name "Unnamed device_index" will be used
    public internal(set) var indexedName: String = "Unnamed device"

    /// A reference to CoreBluetooth Peripheral class instance. Holds device bluetooth information
    public internal(set) var cbPeripheral: CBPeripheral
    
    /// Reference to CoreBluetooth CBCharacteristic class instance. Holds RECEIVE device information
    public internal(set) var rxChar: CBCharacteristic? = nil
    
    /// Reference to CoreBluetooth CBCharacteristic class instance. Holds TRANSMIT device information
    public internal(set) var txChar: CBCharacteristic? = nil
    
    /// This device's profile. Please refer to TxRxDeviceProfile class for details
    public internal(set) var deviceProfile: TxRxDeviceProfile? = nil
    
    /// If the device is connected
    public internal(set) var isConnected = false
    
    /// If device is sending data (a sendData has been issued)
    public internal(set) var sendingData = false;
    
    /// If device is waiting a command answer in [timeout] time
    public internal(set) var waitingAnswer = false;
    
    /// The instace of TxRxWatchDogTimer class handling the timeouts of this TxRxDevice for a particular phase
    public internal(set) var watchDogTimer: TxRxWatchDogTimer? = nil
    
    /// The data and data description and states TxRxManager's sendData:device:data: method attaches to the TxRxDevice when sending data to a Tertium Device
    public internal(set) var bytesToSend: Int = 0

    /// The data and data description and states TxRxManager's sendData:device:data: method attaches to the TxRxDevice when sending data to a Tertium Device
    public internal(set) var bytesSent: Int = 0

    /// The data and data description and states TxRxManager's sendData:device:data: method attaches to the TxRxDevice when sending data to a Tertium Device
    public internal(set) var totalBytesSent: Int = 0

    /// The data and data description and states TxRxManager's sendData:device:data: method attaches to the TxRxDevice when sending data to a Tertium Device
    public internal(set) var dataToSend: Data? = nil

    /// The data and data description and states TxRxManager's sendData:device:data: method attaches to the TxRxDevice when sending data to a Tertium Device
    public internal(set) var deviceDescription: String = ""
    
    /// A Data class instance hodling the bytes received from the Tertium BLE device
    ///
    /// NOTE: Commands may NOT be received in a single transfer. Data is accumulated by TxRxManager on CoreBluetooth callbacks.
    public internal(set) var receivedData: Data = Data()
    
    internal init(CBPeripheral: CBPeripheral) {
        cbPeripheral = CBPeripheral
    }
    
    /// Proxy utility method to schedule a watchdog timer. Invalidates previous timer and creates a new instance
    ///
    /// - parameter inPhase: The phase in which the TxRxDevice is into
    /// - parameter withTimeInterval: The timeout value in seconds (double)
    /// - parameter withTargetFunc: the method to call when timer interval elapses
    internal func scheduleWatchdogTimer(inPhase: TxRxManagerPhase, withTimeInterval: TimeInterval, withTargetFunc: @escaping (TxRxWatchDogTimer, TxRxDevice) -> ()) {
        invalidateWatchDogTimer()
        watchDogTimer = TxRxWatchDogTimer.scheduledTimer(withDevice: self, inPhase: inPhase, withTimeInterval: withTimeInterval, withTargetFunc: withTargetFunc)
    }
    
    /// Method to associate a Data buffer to the device. Also prepares length variables
    ///
    /// - parameter data: a Data class instance holding data to send to the device
    internal func setDataToSend(data: Data) {
        dataToSend = data
        bytesToSend = data.count
        totalBytesSent = 0
        bytesSent = 0
    }
    
    /// Resets device's accumulated received data buffer
    internal func resetReceivedData() {
        receivedData.count = 0
    }
    
    /// Resets device states, used when device is disconnected, reconnecting, a critical error occoured, CoreBlueTooth went down
    internal func resetStates() {
        isConnected = false
        txChar = nil
        rxChar = nil
        sendingData = false
        waitingAnswer = false
        deviceProfile = nil
        resetReceivedData()
    }
    
    /// Invalidates the current device's WatchDog timer
    internal func invalidateWatchDogTimer() {
        if watchDogTimer != nil {
            watchDogTimer?.stop()
        }
    }
}
