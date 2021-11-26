//
//  AppData.swift
//  EKtimer
//
//  Created by Simon on 2021-11-19.
//

import Foundation
enum TimerCountState
{
    case running(TimeInterval)
    case stopped(TimeInterval)
}
class Device
{
    var name: String = "Device"
    var host: String = "127.0.0.1"
    var connection: WesterstrandConnection? = nil
    weak var connectedTimer: TimerState? = nil
    
    
    
    init()
    {
        
    }
    
    
    func start()
    {
        connection?.start()
    }
    
    func stop()
    {
        connection?.stop()
    }
    
    func reset(to preset: TimeInterval)
    {
        connection?.reset(to: preset)
    }
    
    func close()
    {
        connection?.close()
    }
}

enum Keys: String, CodingKey
{
    case devices
    case name
    case ip_addr
    case connected
    
    case timers
    case timer_count
    case preset
}

class WeakDevice
{
    weak var device: Device? = nil
    
    init(_ device: Device)
    {
        self.device = device
    }
}

class TimerState: Codable
{
    var count: TimerCountState = TimerCountState.stopped(0.0)
    var preset: TimeInterval = 0
    var name: String = "Timer"
    var devices: [WeakDevice] = []
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        name = try container.decode(String.self, forKey: .name)
        preset = try container.decode(Double.self, forKey: .preset)
        count = TimerCountState.stopped(-abs(preset))
    }
    
    init()
    {
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encode(name, forKey: .name)
        try container.encode(preset, forKey: .preset)
    }
    
    func start()
    {
        switch count {
        case TimerCountState.stopped(let t):
            let now = ProcessInfo.processInfo.systemUptime;
            count = TimerCountState.running(now-t)
        default:
            break
        }
        for d in devices {
            d.device?.start()
        }
    }
    
    func stop()
    {
        switch count {
        case TimerCountState.running(let zero):
            let now = ProcessInfo.processInfo.systemUptime;
            count = TimerCountState.stopped(now-zero)
        default:
            break
        }
        for d in devices {
            d.device?.stop()
        }
    }
    
    func reset()
    {
        count = TimerCountState.stopped(-abs(preset))
        for d in devices {
            d.device?.reset(to: preset)
        }
    }
}


class AppData :Codable
{
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let TimersURL = DocumentsDirectory.appendingPathComponent("timers")
    
    var timers:[TimerState] = []
    var devices:[Device] = []
    static var appData: AppData? = nil
    class func getAppdata() -> AppData
    {
        if appData == nil {
            do {
                try load_app_data()
            } catch {
                print("Failed to load app data")
                appData = AppData();
            }
                    
            
        }
        return appData!
    }
    
    class func destroy()
    {
        if let app_data = AppData.appData {
            for d in app_data.devices {
                d.close()
            }
        }
        AppData.appData = nil
    }
    init()
    {
    
    }
    
    func decode_devices(from devices_container: inout UnkeyedDecodingContainer) throws
    {
        while !devices_container.isAtEnd {
            let container = try devices_container.nestedContainer(keyedBy: Keys.self)
            let device = Device()
            device.name = try container.decode(String.self, forKey: Keys.name)
            device.host = try container.decode(String.self, forKey: Keys.ip_addr)
            device.connection = WesterstrandConnection(to: device.host)
            let timer_index = try container.decode(Int.self, forKey: .connected)
            device.connectedTimer = timers[timer_index]
            devices.append(device)
            device.connectedTimer?.devices.append(WeakDevice(device))
        }
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        timers = try container.decode([TimerState].self, forKey: .timers)
        var devices_container = try container.nestedUnkeyedContainer(forKey: .devices)
        try decode_devices(from: &devices_container)
    }
    
    func encode_devices(to devices_container: inout UnkeyedEncodingContainer) throws {
        for device in devices {
            var container = devices_container.nestedContainer(keyedBy: Keys.self)
            try container.encode(device.name, forKey: .name)
            try container.encode(device.host, forKey: .ip_addr)
            
            let timer_index = getTimerIndex(forDevice: device)
            try container.encode(timer_index, forKey: .connected)
        
        }
        
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encode(timers, forKey: .timers)
        var devices_container = container.nestedUnkeyedContainer(forKey: .devices)
        try encode_devices(to: &devices_container)
    }
    
    class func save_app_data() throws
    {
        
        let enc = JSONEncoder();
        let data = try enc.encode(appData)
        try data.write(to: AppData.TimersURL)
        print("Wrote: \(String.init(decoding: data, as: UTF8.self))")
    }
    class func load_app_data() throws
    {
        
        let data = try Data(contentsOf: AppData.TimersURL)
        let dec = JSONDecoder();
        AppData.appData = try dec.decode(AppData.self, from: data)
         
    }
    
    func getTimerIndex(forDevice device: Device) -> Int?
    {
        for (ti, timer) in timers.enumerated() {
            if device.connectedTimer === timer {
                return ti
            }
        }
        return nil
    }
}
