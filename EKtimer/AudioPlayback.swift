//
//  AudioPlayback.swift
//  EKtimer
//
//  Created by Simon Berg on 2024-04-02.
//

import Foundation
import AVFoundation

class TimerSounds
{
    static let SILENT_INDEX = 0
    static private let SILENT_URL: URL = URL(string: "sound://silent")!
    static private let sounds: [(String, URL)] = [
        (String(localized: "SoundSilent", defaultValue: "Silent"), SILENT_URL),
        (String(localized: "SoundBeepBeep", defaultValue: "Beep Beep"), Bundle.main.url(forResource: "BeepBeep", withExtension: "wav")!),
        (String(localized: "SoundBuzzer", defaultValue: "Buzzer"), Bundle.main.url(forResource: "Buzzer", withExtension: "wav")!),
        (String(localized: "SoundChirp", defaultValue: "Chirp"), Bundle.main.url(forResource: "Chirp", withExtension: "wav")!)
    ]
    
    static private var players = [AVAudioPlayer?](repeating: nil, count: sounds.count)
    static private var activePlayer: AVAudioPlayer? = nil
    static let REPEAT_FOREVER = 0
    static private var repeatTimer: Timer? = nil
    class func getNames() -> [String]
    {
        return sounds.map({$0.0})
    }
    
    class func getName(_ index: Int) -> String
    {
        if index >= 0 && index < sounds.count {
            return sounds[index].0
        } else {
            return "?"
        }
    }
    
    class func getIndex(_ name: String) -> Int?
    {
        return (sounds.firstIndex { $0.0 == name })
    }
    
    class func play(withIndex index: Int, times: UInt = 1) {
        if index < 0 || index >= sounds.count {
            return
        }
        let player: AVAudioPlayer
        if let p = players[index] {
            player = p
        } else {
            let url =  sounds[index].1
            if url == SILENT_URL {
                return
            }
            do {
                player = try AVAudioPlayer(contentsOf: url)
                players[index] = player
            } catch {
                print("Audio playback failed: \(error)")
                return
            }
        }
        
        activePlayer?.stop()
        activePlayer = player
        repeatTimer?.invalidate()
        player.play()
        var times = times
        if times > 1 {
            repeatTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true, block: {_ in
                player.play();
                if times != REPEAT_FOREVER {
                    if times >= 3 {
                        times -= 1
                    } else {
                        activePlayer = nil
                        repeatTimer?.invalidate()
                        repeatTimer = nil
                    }
                }})
            
        }
    }
    
    class func play(withName name: String){
        if let index = getIndex(name) {
            play(withIndex: index)
        }
        
    }
    class func stop()
    {
        activePlayer?.stop()
        repeatTimer?.invalidate()
        repeatTimer = nil
    }
}

