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
import Foundation

/// Implements a WatchDog timer to make sure communication which Teritum BLE Devices happen in a timely fashion
public class TxRxWatchDogTimer: NSObject {
    /// The device handled by this WatchDog timer
    let _device: TxRxDevice
    
    /// The phase in which the device is (connecting, connected, writing to, receiving from, disconnecting, etc)
    let _phase: TxRxDeviceManagerPhase
    
    /// The timer's interval. Maxium time the device has to answer to a commands
    let _interval: Double
    
    /// The iOS timer class instance
    private var _timer: Timer = Timer()
    
    /// The method which will be notified when a timeout elapses
    let _targetFunc: (TxRxWatchDogTimer, TxRxDevice) -> ()
    
    /// Creates a NSTimer with specified parameters including TxRxDevice reference and operational phase (purpose of the watchdog timer)
    ///
    /// NOTE: this is a CLASS method, not an INSTANCE method
    ///
    /// - parameter withDevice: The TxRxDevice handled
    /// - parameter inPhase: The purpose of the timer
    /// - parameter withTimeInterval: The interval after which the timer fires
    /// - parameter withTargetFunc: the function to invoke when timer fires
    /// - returns: A newly created instance of TxRxWatchDogTimer
    internal class func scheduledTimer(withDevice: TxRxDevice, inPhase: TxRxDeviceManagerPhase, withTimeInterval: TimeInterval, withTargetFunc: @escaping (TxRxWatchDogTimer, TxRxDevice) -> ()) -> TxRxWatchDogTimer {
        return TxRxWatchDogTimer(device: withDevice, phase: inPhase, timeInterval: withTimeInterval, targetFunc: withTargetFunc)
    }
    
    public init(device: TxRxDevice, phase: TxRxDeviceManagerPhase, timeInterval: TimeInterval, targetFunc: @escaping (TxRxWatchDogTimer, TxRxDevice) -> ()) {
        _device = device
        _phase = phase
        _interval = timeInterval
        _targetFunc = targetFunc;
        super.init()
        _timer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(self.watchDogTimerTick), userInfo: nil, repeats: false)
    }
    
    /// Handles iOS native Timer tick method. Calls the target function
    ///
    /// - parameter timer: The iOS native timer which handles the timeout
    @objc func watchDogTimerTick(timer: Timer!) {
        _targetFunc(self, _device)
    }
    
    /// Stops the timer. Usually this happends when an operation succeeded in a timely fashion
    internal func stop() {
        _timer.invalidate()
    }
}
