//
//  ClockDevices.swift
//  EKtimer
//
//  Created by Simon Berg on 2024-04-11.
//

import Foundation

class ClockDevices
{
    
    private static var connections: [WesterstrandConnection] = []
    
    class func connect(to: [String]) {
        for device in AppData.getDevices() {
            connections.append(WesterstrandConnection(to: device.host))
        }
        for (i, device) in AppData.getDevices().enumerated() {
            if i >= connections.count {
                connections.append(WesterstrandConnection(to: device.host))
            }
            connections[i].connect(to: device.host)
        }
    }
    

    class func start()
    {
        for conn in connections {
            conn.start()
        }
    }
    
    class func stop()
    {
        for conn in connections {
            conn.stop()
        }
        
    }
    class func reset(to preset:TimeInterval)
    {
        for conn in connections {
            conn.reset(to: preset)
        }
    }
    
    class func set(function: WesterstrandConnection.Function)
    {
        for conn in connections {
            conn.set(function: function)
        }
    }
}
