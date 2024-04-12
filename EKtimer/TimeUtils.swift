//
//  TimeUtils.swift
//  EKtimer
//
//  Created by Simon Berg on 2024-03-27.
//

import Foundation

class TimeUtils
{
    class func format(interval time: TimeInterval) -> String
    {
        let sign = time >= 0 ? " " : "-";
        let seconds = Int(abs(time)+0.5)
        let minutes = seconds / 60
        let hours = minutes / 60
        return String(format: "%@%02d:%02d:%02d", sign, hours%100, minutes%60, seconds%60)
    }
    
    class func format_edit(interval time: TimeInterval) -> String
    {
        let seconds = Int(abs(time)+0.5)
        let minutes = seconds / 60
        let hours = minutes / 60
        return String(format: "%02d%02d%02d", hours%100, minutes%60, seconds%60)
    }
    
    
    
}
