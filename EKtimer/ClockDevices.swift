//
//  ClockDevices.swift
//  EKtimer
//
//  Created by Simon Berg on 2024-04-11.
//

import Foundation

class ClockDevices
{
    
    private static var connections: [String:WesterstrandConnection] = [:];
    
    class func connect(to: [String]) {
        var keep: [String: WesterstrandConnection] = [:];
        var connect = to;
        var disconnect : [WesterstrandConnection] = [];
        
        for (host, conn) in connections {
            if connect.contains(host) {
                connect.removeAll(where: {$0 == host})
                keep[host] = conn;
            } else {
                disconnect.append(conn);
            }
        }
        
        // Don't touch hosts that are already connecteds
        connections = keep;
        
        // Disconnect hosts no longer in the list
        for device in disconnect {
            device.disconnect();
        }
        
        // Connect new hosts in the list
        for new_host in connect {
            let conn = WesterstrandConnection();
            connections[new_host] = conn;
            conn.connect(to: new_host)
            
        }
    }
    

    class func start()
    {
        for conn in connections.values {
            conn.start()
        }
    }
    
    class func stop()
    {
        for conn in connections.values {
            conn.stop()
        }
        
    }
    class func reset(to preset:TimeInterval)
    {
        for conn in connections.values {
            conn.reset(to: preset)
        }
    }
    
    class func set(function: WesterstrandConnection.Function)
    {
        for conn in connections.values {
            conn.set(function: function)
        }
    }
    
    class func settings(for_host: String, values: [String: AnyObject])
    {
        if let conn = connections[for_host] {
            conn.settings(values: values)
        }
    }
}
