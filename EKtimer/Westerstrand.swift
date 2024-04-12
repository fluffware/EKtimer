//
//  Westerstrand.swift
//  EKtimer
//
//  Created by Simon on 2021-11-18.
//

import Foundation
import Network

class WesterstrandConnection
{
    var connection: NWConnection? = nil
    var end_point:NWEndpoint? = nil;
    var poll_timer: Timer? = nil
    var restart_timer: Timer? = nil
    var packet_delay: Timer? = nil
    
    var intensity: UInt8 = 5
    var signal_time: UInt8 = 3
    init(to host: String)
    {
        print("WesterstrandConnection")
    }
    
    func connect(to host: String) {
        let new_end_point = NWEndpoint.hostPort(host: NWEndpoint.Host.name(host, nil), port: NWEndpoint.Port(rawValue: 1080)!)
        if new_end_point == end_point {
            return
        }
        end_point = new_end_point
        setupConnection()

    }
    
    func setupConnection()
    {
        connection = NWConnection(to: end_point!, using: NWParameters.tcp)
      
        connection!.stateUpdateHandler = stateChanged
        connection!.start(queue: DispatchQueue.main)
        connection!.receive(minimumIncompleteLength: 1, maximumLength: 1024, completion: receiveData)
    }
    
    private func delayedRestart(_:Timer)
    {
        if let connection = connection {
            print("delayedRestart \(connection.state)")
            switch connection.state {
            case .waiting(_):
                connection.restart()
            case  .ready, .cancelled:
                setupConnection()
            default:
                break
            }
        }
    }
    
    private func pollTime(_: Timer)
    {
            send(toChannel: 0x3f, withData: [])
    }
    private func stateChanged(state: NWConnection.State)
    {
        print("Connection state changed; \(state)")
        if let timer = poll_timer {
            timer.invalidate()
            poll_timer = nil
        }
        switch state {
        case .waiting(_), .cancelled:
            restart_timer?.invalidate()
            restart_timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: delayedRestart)
        case .ready:
            poll_timer = Timer.scheduledTimer(withTimeInterval: 1.3, repeats: true, block: pollTime)
        default:
            break
        }
    }
    
    private func receiveData(_ content: Data?, _ contentContext: NWConnection.ContentContext?, _ isComplete: Bool, _ error: NWError?)
    {
        if let error = error {
            print("Error: \(error)")
            connection?.cancel();
            return;
        }
        if let content = content {
            print("Receieved: \(content)")
            
        }
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 1024, completion: receiveData)
    }
    
    func close()
    {
        
        connection?.stateUpdateHandler = nil
        connection?.cancel()
        connection = nil
        if let timer = poll_timer {
            timer.invalidate()
            poll_timer = nil
        }
    }
    
    private var pending: [Data] = []
    
    private func sendPending()
    {
        if packet_delay != nil {
            return
        }
        guard let data = pending.popLast() else {
            return
        }
       
        //print("Send: \(data) \(connection)")
        
        connection?.send(content: data, completion: NWConnection.SendCompletion.contentProcessed({(error) -> Void in return}))
        
        // Wait a while before sending next packet, if any
        packet_delay = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: false, block: {
            _ in
            //print("Delay end")
            self.packet_delay = nil
            self.sendPending()
        })
    }
    
    private func send(toChannel: UInt8,withData data: [UInt8])
    {
         var tx_data = Data([2,0,UInt8(data.count+4), 0x43, 0x48,
                            toChannel])
        tx_data.append(contentsOf: data)
        tx_data.append(contentsOf: [3, 0x20])
        pending.insert(tx_data, at: 0)
        sendPending()
    }
    func start()
    {
        send(toChannel: 0x33, withData: [0x31])
    }
    
    func stop()
    {
        send(toChannel: 0x33, withData: [0x30])
    }
    func reset(to preset:TimeInterval)
    {
        stop()
        set(time: preset)
        let function = preset > 0 ? Function.count_down:Function.count_up
        set(function: function)
        send(toChannel: 0x33, withData: [0x32])
    }
    
    func set(time interval: TimeInterval)
    {
        let v = Int(interval * 1000)
        let v_str = String(v)
        
        let data = v_str.utf8 + [0]
        send(toChannel: 0x31, withData: data)
    }
    enum Function:UInt8 {
        case count_up = 0x31
        case count_down = 0x32
        case count_down_auto_reset = 0x33
    }
    func set(function: Function)
    {
        let data = [function.rawValue, signal_time, intensity]
        send(toChannel: 0x32, withData: data)
    }
    
}
