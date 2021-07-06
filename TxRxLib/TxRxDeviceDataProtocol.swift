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

/// Defines the methods that will be called on Tertium BLE device events
public protocol TxRxDeviceDataProtocol {
    /// Informs delegate a device has been connected
    ///
    /// - parameter device: The TxRxDevice on which the error occoured
    func deviceConnected(device: TxRxDevice)
    
    /// Informs delegate a device has been successfully disconnected
    /// - parameter device: The TxRxDevice disconnected
    func deviceDisconnected(device: TxRxDevice)
    
    /// Informs delegate an error while connecting device happened
    ///
    /// - parameter device: The TxRxDevice on which the error occoured
    /// - parameter error: An NSError class instance describing the error
    func deviceConnectError(device: TxRxDevice, error: NSError)
    
    /// Informs a connected device is ready to operate and has been identified as a Tertium BLE device
    ///
    /// - parameter device: The TxRxDevice on which the error occoured
    func deviceReady(device: TxRxDevice)

    /// Informs a connected device can also set operational mode
    ///
    /// - parameter device: The TxRxDevice on which the error occoured
    func setModeCharacteristicDiscovered(device: TxRxDevice)
    
    /// Informs delegate a Tertium BLE device has sent data
    ///
    /// NOTE: This can even happen PASSIVELY without issuing a command
    ///
    /// - parameter device: The TxRxDevice which sent the data
    /// - parameter data: the data received from the device (usually ASCII bytes)
    func receivedData(device: TxRxDevice, data: Data)

    /// Informs delegate the last sendData operation has succeeded
    ///
    /// - parameter device: The TxRxDevice which successfully received the data
    func sentData(device: TxRxDevice)
    
    /// Informs delegate the last setMode operation has succeeded
    ///
    /// - parameter device: The TxRxDevice which successfully switched operational mode
    func hasSetMode(device: TxRxDevice, operationalMode: UInt)
    
    /// Informs delegate the last setMode operation has succeeded
    ///
    /// - parameter device: The TxRxDevice which successfully switched operational mode
    func setModeError(device: TxRxDevice, errorCode: Int)
    
    /// Informs delegate we received event data
    ///
    /// - parameter device: The TxRxDevice which successfully switched operational mode
    func receivedEventData(device: TxRxDevice, data: Data)
    
    /// Informs delegate there has been an error receiving data from device
    ///
    /// - parameter device: The TxRxDevice on which the error occoured
    /// - parameter error: An NSError class instance describing the error
    func deviceReadError(device: TxRxDevice, error: NSError)
    
    /// Informs delegate there has been an error sending data to device
    ///
    /// - parameter device: The TxRxDevice on which the error occoured
    /// - parameter error: An NSError class instance describing the error
    func deviceWriteError(device: TxRxDevice, error: NSError)
    
    /// Informs delegate a device critical error happened. NO further interaction with this TxRxDevice class should be done
    /// - parameter device: The TxRxDevice on which the error occoured
    /// - parameter error: An NSError class instance describing the error
    func deviceError(device: TxRxDevice, error: NSError)
}
