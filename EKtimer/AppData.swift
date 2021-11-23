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
class Device: Codable
{
    var name: String = "Device"
    var ipAddr: String = "127.0.0.1"
    var connection: WesterstrandConnection? = nil
    weak var connectedTimer: TimerState? = nil
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        name = try container.decode(String.self, forKey: .name)
        ipAddr = try container.decode(String.self, forKey: .ip_addr)
        
    }
    
    init()
    {
        
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encode(name, forKey: .name)
        try container.encode(ipAddr, forKey: .ip_addr)
        let connected = connectedTimer?.name
        try container.encode(connected, forKey: .connected)
    }
    
    func start()
    {
        connection?.start()
    }
    
    func stop()
    {
        connection?.stop()
    }
    
    func reset()
    {
        connection?.reset()
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

class TimerState: Codable
{
    var count: TimerCountState = TimerCountState.stopped(0.0)
    var preset: TimeInterval = 0
    var name: String = "Timer"
    var devices: [Device] = []
    
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
            d.start()
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
            d.stop()
        }
    }
    ß
    func reset()
    {
        count = TimerCountState.stopped(-abs(preset))
        for d in devices {
            d.reset()
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
    
    init()
    {
    
    }
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        timers = try container.decode([TimerState].self, forKey: .timers)
        devices = try container.decode([Device].self, forKey: .devices)
       
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encode(timers, forKey: .timers)
        try container.encode(devices, forKey: .devices)
        
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
    
}
