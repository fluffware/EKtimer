//
//  AppData.swift
//  EKtimer
//
//  Created by Simon on 2021-11-19.
//

import Foundation
enum TimerCountState
{
    case running(TimeInterval) // Time when
    case stopped(TimeInterval)
    
    func setDict(dict: inout [String: Any]) {
        switch(self) {
        case .running(let count):
            dict["State"] = "running"
            dict["Count"] = count
        case .stopped(let count):
            dict["State"] = "stopped"
            dict["Count"] = count
        }
    }
}
class Device
{
    var name: String = "Device"
    var host: String = "127.0.0.1"
    var intensity = 5;
    var beep_interval = 2;
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
class TimerStep{
    var name: String
    var duration: TimeInterval
    var sound: Int
    var repeats: UInt
    required init(name: String, duration: TimeInterval, 
                  sound: Int = 0, repeats: UInt = 1)
    {
        self.name = name
        self.duration = duration
        self.sound = sound
        self.repeats = repeats
    }
    required init(from: [String : Any]) {
        name = from["Name"] as? String ?? "No name"
        duration = from["Duration"] as? Double ?? 1.0
        sound = from["Sound"] as? Int ?? 0
        repeats = from["Repeats"] as? UInt ?? 1
    }
    func toDict() -> [String : Any]{
        let dict: [String: Any] = ["Name": name, "Duration": duration, "Sound": sound, "Repeats": repeats]
        return dict
    }
}
class TimerSequence
{
    var name: String
    var countUp: Bool = true
    var steps: [TimerStep] = []
  
    
    required init(name: String, countUp: Bool = true,  steps: [TimerStep] = [])
    {
        self.name = name
        self.countUp = countUp
        self.steps = steps
    }
    
    required init(from: [String : Any]) {
        name = from["Name"] as? String ?? "No name"
        countUp = from["CountUp"] as? Bool ?? true
        steps = (from["Steps"] as? [[String: Any]] ?? []).map({TimerStep(from: $0)})
    }
    
   
    
    func toDict() ->[String : Any]{
        let dict: [String: Any] = [
            "Name": name,
            "CountUp": countUp,
            "Steps": steps.map({$0.toDict()})
        ]
        return dict
    }
}

class TimerState
{
    var count: TimerCountState = TimerCountState.stopped(0.0)
    weak var sequence: TimerSequence? = nil
    var sequence_index = 0;
    var devices: [WeakDevice] = []
    
    
    required init(from: [String: Any]) {
        let state_name: String? = from["State"] as? String
        let state_count: TimeInterval? = from["Count"] as? Double
        if let state_name = state_name, let state_count = state_count {
            if state_name == "running" {
                let now = ProcessInfo.processInfo.systemUptime
                if state_count >= now {
                    count = TimerCountState.running(state_count)
                } else {
                    count = TimerCountState.stopped(0.0)
                }
            } else {
                count = TimerCountState.stopped(state_count)
            }
        }
    }
    
    
    init()
    {
    }
    
    func preset() -> TimeInterval {
        if let sequence = sequence {
            if !sequence.countUp {
                return sequence.steps.reduce(0.0, {$0+$1.duration})
            }
        }
        return 0.0
    }
    
    func countUp() -> Bool {
        return sequence?.countUp ?? true
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
        count = TimerCountState.stopped(0.0)
        for d in devices {
            d.device?.reset(to: preset())
        }
    }
}


class AppData
{
   
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let TimersURL = DocumentsDirectory.appendingPathComponent("timers")
    
    private static var sequences: [TimerSequence]? = nil
    private static let initial_sequencies = [
        TimerSequence(name: String(localized: "Count up"), countUp: true,
                      steps: []),
        TimerSequence(name: String(localized: "Count down"), countUp: false,
                      steps:[TimerStep(name: String(localized: "Duration"), duration: 60, sound:0)]),
    ]
    
    private static var timer: TimerState = TimerState()
    private static var devices:[Device] = []

    
    class func destroy()
    {
            }
    
    class func getDevices() -> [Device] {
        return AppData.devices
    }
    
    class func getSequences() -> [TimerSequence] {
        if AppData.sequences == nil {
            AppData.sequences = initial_sequencies
        }
        return AppData.sequences!
    }
    
    class func add(sequence: TimerSequence) {
        AppData.sequences?.append(sequence)
    }
    
    class func remove(sequence: TimerSequence) {
        if let sequences = AppData.sequences {
            for (i,s) in sequences.enumerated() {
                if s === sequence {
                    AppData.sequences?.remove(at: i)
                    break
                }
            }
        }
    }
    
    class func getTimer() -> TimerState
    {
        return AppData.timer
    }
    
    class func decode_devices(from devices_defaults: UserDefaults) throws
    {
        AppData.devices.removeAll()
        
        for i in 1...4 {
            let prefix = "Device"+String(i)+"_";
            let name = devices_defaults.string(forKey: prefix + "Name")
            let ip = devices_defaults.string(forKey: prefix+"IP")
            if let ip = ip, var name = name {
                if ip != "0.0.0.0" {
                    if name == "" {
                        name = String(i)
                    }
                    let device = Device()
                    device.name = name
                    device.host = ip
                    device.intensity = Int(devices_defaults.string(forKey: prefix+"Intensity") ?? "") ?? 5
                    device.beep_interval = Int(devices_defaults.string(forKey: prefix+"BeepLength") ?? "") ?? 2
                    AppData.devices.append(device)
                    device.connectedTimer?.devices.append(WeakDevice(device))
                }
            }
        }
     }
    
    class func encode_sequences(to defaults: UserDefaults) throws
    {
        var array: [Any] = []
        
        for sequence in AppData.getSequences() {
            array.append(sequence.toDict())
        }
        defaults.set(array, forKey: "Sequencies")
    }
    
    class func decode_sequencies(from defaults: UserDefaults) throws
    {
        if AppData.sequences == nil {
            AppData.sequences = initial_sequencies
        }
        if let array = defaults.array(forKey: "Sequencies") {
            AppData.sequences!.removeAll()
            for sequence in array {
                if let sequence = sequence as? [String: Any] {
                    AppData.sequences!.append(TimerSequence(from: sequence))
                }
            }
        }
    }

    
    
    class func save_state() throws
    {
        
    }
    
    class func save_preferences() throws
    {
        try encode_sequences(to: UserDefaults.standard)
        print("Saving preferences")
    }
    
    class func load_preferences() throws {
        try decode_devices(from: UserDefaults.standard)
        // Since the sequencies can only be changed from within the app, there is no reason to load the if we already have them
        if AppData.sequences == nil {
            try decode_sequencies(from: UserDefaults.standard)
        }
        print("Loading preferences")
    }
}
