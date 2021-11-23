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
    var connection: NWConnection! = nil
    var end_point:NWEndpoint;
    var poll_timer: Timer? = nil
    init(to host: String)
    {
        end_point = NWEndpoint.hostPort(host: NWEndpoint.Host.name(host, nil), port: NWEndpoint.Port(rawValue: 1080)!)
        setupConnection()
    }
    
    func setupConnection()
    {
        connection = NWConnection(to: end_point, using: NWParameters.tcp)
      
        connection.stateUpdateHandler = stateChanged
        connection.start(queue: DispatchQueue.main)
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1024, completion: receiveData)
    }
    
    func delayedRestart(_:Timer)
    {
        switch connection.state {
        case .waiting(_):
            connection.restart()
        default:
          setupConnection()
        }
        connection.restart()
    }
    
    func pollTime(_: Timer)
    {
            send(toChannel: 0x3f, withData: [])
    }
    func stateChanged(state: NWConnection.State)
    {
        print("Connection state changed; \(state)")
        if let timer = poll_timer {
            timer.invalidate()
            poll_timer = nil
        }
        switch state {
            case .waiting(_), .cancelled:
            Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: delayedRestart)
        case .ready:
            poll_timer = Timer.scheduledTimer(withTimeInterval: 1.3, repeats: true, block: pollTime)
        default:
            break
        }
    }
    
    func receiveData(_ content: Data?, _ contentContext: NWConnection.ContentContext?, _ isComplete: Bool, _ error: NWError?)
    {
        if let error = error {
            print("Error: \(error)")
            connection.cancel();
            return;
        }
        if let content = content {
            print("Receieved: \(content)")
            
        }
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1024, completion: receiveData)
    }
    
    private func send(toChannel: UInt8,withData data: [UInt8])
    {
        var tx_data = Data([2,0,UInt8(data.count+7), 0x43, 0x48,
                            toChannel])
        tx_data.append(contentsOf: data)
        tx_data.append(contentsOf: [3, 0x20])
        connection?.send(content: tx_data, completion: NWConnection.SendCompletion.contentProcessed({(error) -> Void in return}))
    }
    func start()
    {
        send(toChannel: 0x33, withData: [0x31])
    }
    
    func stop()
    {
        send(toChannel: 0x33, withData: [0x30])
    }
    func reset()
    {
        send(toChannel: 0x33, withData: [0x32])
    }
}
