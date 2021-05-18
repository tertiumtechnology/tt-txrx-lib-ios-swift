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

/// A structure describing a Tertium bluetooth device
///
/// NOTE: Each device has its own particular characteristics
public struct TxRxDeviceProfile {
    public enum TerminatorType: String {
        case NONE = ""
        case CR = "\r"
        case LF = "\n"
        case CRLF = "\r\n"
        case ZERO = "\0"
    }
    
    /// The Service UUID of the Tertium BLE Device
    public let txRxServiceUUID: String
    
    /// write characteristic
    public let txCharacteristicUUID: String

    ///  read characteristic
    public let rxCharacteristicUUID: String
    
    /// setmode characteristic
    public let setModeCharacteristicUUID: String
    
    /// The terminator of the Tertium BLE Device. Tells when a command is finished
    public let commandEnd: String
    
    /// The maximum number of bytes this device class can receive in a single read statement
    public var rxPacketSize: Int

    /// The maximum number of bytes this device class can send in a single write statement
    public var txPacketSize: Int
    
    init(inServiceUUID: String, withRxUUID inRxUUID: String, withTxUUID inTxUUID: String, withSetModeUUID setModeUUID: String, withCommandEnd inCommandEnd: String, withRxPacketSize inRxPacketSize: Int, withTxPacketSize inTxPacketSize: Int) {
        
        txRxServiceUUID = inServiceUUID
        rxCharacteristicUUID = inRxUUID
        txCharacteristicUUID = inTxUUID
        setModeCharacteristicUUID = setModeUUID
        commandEnd = inCommandEnd
        rxPacketSize = inRxPacketSize
        txPacketSize = inTxPacketSize
    }
}
