import Foundation
import IOKit
import IOKit.hid

/// Reads the Apple Silicon IMU through its vendor HID interface.
/// This is undocumented hardware access; availability varies by Mac model and macOS version.
final class AccelerometerReader {
    private static let vendorUsagePage: UInt32 = 0xFF00
    private static let accelerometerUsage: UInt32 = 3
    private static let reportLength = 22
    private static let reportBufferSize = 4096

    private var device: IOHIDDevice?
    private var reportBuffer: UnsafeMutablePointer<UInt8>?
    private var worker: Thread?
    private var callback: ((Double, Double, Double) -> Void)?
    private var stateCallback: ((Bool, String) -> Void)?
    private let lock = NSLock()
    private var shouldStop = false

    private(set) var isRunning = false
    private(set) var status = "Ready"

    func start(
        onSample: @escaping (Double, Double, Double) -> Void,
        onStateChange: @escaping (Bool, String) -> Void
    ) {
        guard !isRunning else { return }
        callback = onSample
        stateCallback = onStateChange
        shouldStop = false
        let thread = Thread { [weak self] in self?.runSensorLoop() }
        thread.name = "com.tapflow.sensor"
        thread.qualityOfService = .utility
        worker = thread
        isRunning = true
        status = "Connecting to tap sensor..."
        stateCallback?(true, status)
        thread.start()
    }

    func stop() {
        lock.lock()
        shouldStop = true
        lock.unlock()
        isRunning = false
        status = "Tap detection is off"
        stateCallback?(false, status)
    }

    private func runSensorLoop() {
        guard let opened = openAccelerometer() else {
            DispatchQueue.main.async { [weak self] in
                self?.isRunning = false
                self?.status = "Accelerometer unavailable on this Mac."
                self?.stateCallback?(false, self?.status ?? "Accelerometer unavailable on this Mac.")
            }
            return
        }
        device = opened.device
        reportBuffer = opened.buffer
        DispatchQueue.main.async { [weak self] in
            self?.status = "Listening for taps"
            self?.stateCallback?(true, self?.status ?? "Listening for taps")
        }

        while !isStopRequested {
            let result = CFRunLoopRunInMode(.defaultMode, 0.5, false)
            if result == .finished || result == .stopped { break }
        }
        IOHIDDeviceClose(opened.device, IOOptionBits(kIOHIDOptionsTypeNone))
        opened.buffer.deallocate()
        device = nil
        reportBuffer = nil
    }

    private var isStopRequested: Bool {
        lock.lock()
        defer { lock.unlock() }
        return shouldStop
    }

    private func openAccelerometer() -> (device: IOHIDDevice, buffer: UnsafeMutablePointer<UInt8>)? {
        wakeSensorDriver()
        let matching = IOServiceMatching("AppleSPUHIDDevice") as NSDictionary as CFDictionary
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else { return nil }
        defer { IOObjectRelease(iterator) }

        var service = IOIteratorNext(iterator)
        while service != 0 {
            let usagePage = property(service, named: "PrimaryUsagePage")
            let usage = property(service, named: "PrimaryUsage")
            guard usagePage == Int(Self.vendorUsagePage), usage == Int(Self.accelerometerUsage),
                  let device = IOHIDDeviceCreate(kCFAllocatorDefault, service) as IOHIDDevice?,
                  IOHIDDeviceOpen(device, IOOptionBits(kIOHIDOptionsTypeNone)) == kIOReturnSuccess else {
                IOObjectRelease(service)
                service = IOIteratorNext(iterator)
                continue
            }

            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: Self.reportBufferSize)
            buffer.initialize(repeating: 0, count: Self.reportBufferSize)
            let context = Unmanaged.passUnretained(self).toOpaque()
            IOHIDDeviceRegisterInputReportWithTimeStampCallback(device, buffer, CFIndex(Self.reportBufferSize), reportCallback, context)
            IOHIDDeviceScheduleWithRunLoop(device, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
            IOObjectRelease(service)
            return (device, buffer)
        }
        return nil
    }

    private func wakeSensorDriver() {
        let matching = IOServiceMatching("AppleSPUHIDDriver") as NSDictionary as CFDictionary
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else { return }
        defer { IOObjectRelease(iterator) }
        var service = IOIteratorNext(iterator)
        while service != 0 {
            for (name, value) in [("SensorPropertyReportingState", 1), ("SensorPropertyPowerState", 1), ("ReportInterval", 1_000)] {
                IORegistryEntrySetCFProperty(service, name as CFString, NSNumber(value: value))
            }
            IOObjectRelease(service)
            service = IOIteratorNext(iterator)
        }
    }

    private func property(_ service: io_service_t, named name: String) -> Int? {
        guard let value = IORegistryEntryCreateCFProperty(service, name as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? NSNumber else { return nil }
        return value.intValue
    }

    fileprivate func receive(report: UnsafePointer<UInt8>, length: Int) {
        guard length == Self.reportLength else { return }
        func int32(at offset: Int) -> Int32 {
            // HID reports are byte-aligned; assemble the little-endian value safely.
            let b0 = UInt32(report[offset])
            let b1 = UInt32(report[offset + 1]) << 8
            let b2 = UInt32(report[offset + 2]) << 16
            let b3 = UInt32(report[offset + 3]) << 24
            return Int32(bitPattern: b0 | b1 | b2 | b3)
        }
        callback?(Double(int32(at: 6)) / 65_536, Double(int32(at: 10)) / 65_536, Double(int32(at: 14)) / 65_536)
    }
}

private func reportCallback(
    context: UnsafeMutableRawPointer?, result: IOReturn, sender: UnsafeMutableRawPointer?, type: IOHIDReportType,
    reportID: UInt32, report: UnsafeMutablePointer<UInt8>, reportLength: CFIndex, timestamp: UInt64
) {
    guard let context else { return }
    let reader = Unmanaged<AccelerometerReader>.fromOpaque(context).takeUnretainedValue()
    reader.receive(report: UnsafePointer(report), length: Int(reportLength))
}
