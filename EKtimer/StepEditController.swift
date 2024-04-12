//
//  TimerEdit.swift
//  EKtimer
//
//  Created by Simon on 2021-11-22.
//

import Foundation
import UIKit
class StepEditController: UIViewController
{
    var time_str = "000000";
    var timer_index = 0
    var first_entry = true
    weak var step: TimerStep? = nil
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var timeField: UILabel!
    
    private func updatePresetField()
    {
        let i1 = time_str.index(time_str.startIndex, offsetBy: 2)
        let i2 = time_str.index(i1, offsetBy: 2)
        let h_str = time_str[..<i1]
        let m_str = time_str[i1..<i2]
        let s_str = time_str[i2...]
        
        let m = Int(m_str)!
        let s = Int(s_str)!
        if s >= 60 || m >= 60 {
            timeField.textColor = UIColor.red
        } else {
            timeField.textColor = nil
        }
        timeField?.text = h_str+":"+m_str+":"+s_str
    }
    
    @IBAction func ButtonPressed(_ sender: UIButton) {
        print("Tag: \(sender.tag)")
        if first_entry {
            first_entry = false
            time_str = "000000"
        }
        switch sender.tag {
        case 100:
            time_str = String(time_str.dropFirst(2)) + "00"
        case 11:
            time_str = "000000"
        case 0...9:
            time_str = String(time_str.dropFirst(1)) + String(UnicodeScalar(48+sender.tag)!)
        default:
            break
        }
        updatePresetField()
        
    }
    
    @IBAction func presetFieldDone(_ sender: UITextField) {
        sender.resignFirstResponder()
    }
    
    
    @IBAction func nameFieldStartEdit(_ text: UITextField) {
        text.selectedTextRange = text.textRange(from: text.beginningOfDocument, to: text.endOfDocument)
    }
    
   
    private func getTime() -> TimeInterval
    {
        let i1 = time_str.index(time_str.startIndex, offsetBy: 2)
        let i2 = time_str.index(i1, offsetBy: 2)
        let h_str = time_str[..<i1]
        let m_str = time_str[i1..<i2]
        let s_str = time_str[i2...]
        let preset = (Int(h_str)! * 60 + Int(m_str)!) * 60 + Int(s_str)!
        return TimeInterval(preset)
    }
   
    @IBAction func okPressed(_ sender: UIButton) {
        if let step = step {
            step.name = nameField.text ?? ""
            step.duration = getTime()
            
        }
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func cancelPressed(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        print("Step editor will apear")
        super.viewWillAppear(animated)
        if let step = step {
            nameField.text = step.name
            
            let time = step.duration
            
            timeField.text = TimeUtils.format(interval: time)
            first_entry = true
            updatePresetField()
        }
    }
}
    
