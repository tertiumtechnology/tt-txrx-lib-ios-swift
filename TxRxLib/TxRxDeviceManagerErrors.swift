/*
 * The MIT License
 *
 * Copyright 2017-2023 Tertium Technology.
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

public class TxRxDeviceManagerErrors {
    public enum ErrorCodes: Int {
        case ERROR_BLUETOOTH_NOT_READY_OR_LOST
        case ERROR_UNABLE_TO_SCAN_BLUETOOTH_DISABLED
        case ERROR_DEVICE_SCAN_ALREADY_STARTED
        case ERROR_DEVICE_SCAN_NOT_STARTED
        case ERROR_DEVICE_UNABLE_TO_PERFORM_DURING_SCAN
        case ERROR_DEVICE_CONNECT_TIMED_OUT
        case ERROR_DEVICE_ALREADY_CONNECTING
        case ERROR_DEVICE_ALREADY_CONNECTED
        case ERROR_DEVICE_SERVICE_OR_CHARACTERISTICS_NOT_DISCOVERED_YET
        case ERROR_DEVICE_SERVICE_OR_CHARACTERISTICS_NOT_FOUND
        case ERROR_DEVICE_ALREADY_DISCONNECTING
        case ERROR_DEVICE_DISCONNECT_TIMED_OUT
        case ERROR_DEVICE_NOT_CONNECTED
        case ERROR_DEVICE_NOT_SENDING_DATA
        case ERROR_DEVICE_SENDING_DATA_ALREADY
        case ERROR_DEVICE_SENDING_DATA_PARAMETER_ERROR
        case ERROR_DEVICE_SENDING_DATA_TIMEOUT
        case ERROR_DEVICE_WAITING_COMMAND_ANSWER
        case ERROR_DEVICE_RECEIVING_DATA_TIMEOUT
        case ERROR_DEVICE_RECEIVING_EVENT_DATA_TIMEOUT
        case ERROR_DEVICE_ALREADY_SETTING_MODE
        case ERROR_DEVICE_NOT_FOUND
        case ERROR_IOS_ERROR
        case ERROR_INTERNAL_ERROR
        
        // to be used with setModeError notification only
        case ERROR_SET_MODE
        case ERROR_SET_MODE_TIMEOUT
        case ERROR_SET_MODE_BLE_DEVICE_ERROR
        case ERROR_SET_MODE_INVALID_CHARACTERISTIC
        case ERROR_SET_MODE_OPERATION_IN_PROGRESS
    }
    
    public static let S_TERTIUM_TXRX_ERROR_DOMAIN = "Tertium TxRx BLE device library"
    public static let S_ERROR_BLUETOOTH_NOT_READY_OR_LOST = "Bluetooth hardware is not ready or lost!"
    public static let S_ERROR_UNABLE_TO_SCAN_BLUETOOTH_DISABLED = "Unable to scan, bluetooth is disabled!"
    public static let S_ERROR_DEVICE_SCAN_ALREADY_STARTED = "Device scan already started!"
    public static let S_ERROR_DEVICE_SCAN_NOT_STARTED = "Device scan not started!"
    public static let S_ERROR_DEVICE_UNABLE_TO_PERFORM_DURING_SCAN = "Operation is not permitted during device scan!"
    public static let S_ERROR_DEVICE_CONNECT_TIMED_OUT = "Timeout while connecting to device!"
    public static let S_ERROR_DEVICE_ALREADY_CONNECTING = "Error, already connecting to device!"
    public static let S_ERROR_DEVICE_ALREADY_CONNECTED = "Error, already connected to device!"
    public static let S_ERROR_DEVICE_SERVICE_OR_CHARACTERISTICS_NOT_DISCOVERED_YET = "Tertium service UUIDs not present or not discovered yet!"
    public static let S_ERROR_DEVICE_SERVICE_OR_CHARACTERISTICS_NOT_FOUND = "Tertium service UUIDs not found!"
    public static let S_ERROR_DEVICE_DISCONNECT_TIMED_OUT = "Error, device disconnection timed out!"
    public static let S_ERROR_ALREADY_DISCONNECTING = "Already trying to disconnect device!"
    public static let S_ERROR_DEVICE_NOT_CONNECTED = "Error, device not connected!"
    public static let S_ERROR_DEVICE_NOT_SENDING_DATA = "Error, data send hasn't been commenced!"
    public static let S_ERROR_DEVICE_ALREADY_SETTING_MODE = "Error, already trying to change operational mode!"
    public static let S_ERROR_DEVICE_SENDING_DATA_ALREADY = "Error, already trying to send data to device!"
    public static let S_ERROR_DEVICE_SENDING_DATA_PARAMETER_ERROR = "One or more parameters are wrong!"
    public static let S_ERROR_DEVICE_SENDING_DATA_TIMEOUT = "Timeout while sending data to device!"
    public static let S_ERROR_DEVICE_WAITING_COMMAND_ANSWER = "Device is waiting an answer to a previously issued command !"
    public static let S_ERROR_DEVICE_RECEIVING_DATA_TIMEOUT = "Error, timeout while receiving data!"
    public static let S_ERROR_DEVICE_RECEIVING_EVENT_DATA_TIMEOUT = "Error, timeout while receiving event data!"
    public static let S_ERROR_DEVICE_NOT_FOUND = "Device not found in internal data structures!"
    public static let S_ERROR_INTERNAL_ERROR = "Unspecified internal error!"
}
