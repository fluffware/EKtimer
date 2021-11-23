//
//  TimerEdit.swift
//  EKtimer
//
//  Created by Simon on 2021-11-22.
//

import Foundation
import UIKit
class TimerEditController: UIViewController
{
    var time_str = "000000";
    var timer_index = 0
    var first_entry = true
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
    
    private func get_preset_time() -> TimeInterval
    {
        let i1 = time_str.index(time_str.startIndex, offsetBy: 2)
        let i2 = time_str.index(i1, offsetBy: 2)
        let h_str = time_str[..<i1]
        let m_str = time_str[i1..<i2]
        let s_str = time_str[i2...]
        let preset = (Int(h_str)! * 60 + Int(m_str)!) * 60 + Int(s_str)!
        return TimeInterval(preset)
    }
    
    private func saveTimer() -> AppData
    {
        let app_data = AppData.getAppdata()
        print("Updating timer \(timer_index)")
        app_data.timers[timer_index].preset = get_preset_time()
        app_data.timers[timer_index].name = nameField.text ?? ""
        do {
            try AppData.save_app_data()
        } catch {
            let alert = UIAlertController(title: "Failed to save timer settings", message: "Changes made to timer may be lost", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
        
        return app_data
    }
   
    @IBAction func resetPressed(_ sender: UIButton) {
        saveTimer().timers[timer_index].reset()
        self.navigationController?.popViewController(animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("Editor will apear")
        super.viewWillAppear(animated)
        let app_data = AppData.getAppdata()
        let timer = app_data.timers[timer_index]
        nameField.text = timer.name
        
        let seconds = Int(abs(timer.preset))
        let minutes = seconds / 60
        let hours = minutes / 60
        
        time_str = String(format: "%02d%02d%02d", hours%100, minutes%60, seconds%60)
        timeField.text = String(format: "%02d%02d%02d", hours%100, minutes%60, seconds%60)
        first_entry = true
        updatePresetField()
    }
}
    
