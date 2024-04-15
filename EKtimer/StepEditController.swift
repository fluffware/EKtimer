//
//  TimerEdit.swift
//  EKtimer
//
//  Created by Simon on 2021-11-22.
//

import Foundation
import UIKit

class StepNameField: UITextField, UITextFieldDelegate
{
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        delegate = self
    }
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.selectAll(nil)
    }
}

class SoundButton: UIButton
{
    @IBOutlet weak var controller: TimerController?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
    }
    
    private func select_action(name: String, at index: Int) -> UIAction
    {
        return UIAction(title: name) {_ in
            print(name)
            self.setTitle(name, for: UIControl.State.normal)
            self.tag = index
            
        }
    }
    
    func build_sound_elements() -> [UIMenuElement]
    {
        
        var new_elems: [UIMenuElement] = []
        for (i,name) in TimerSounds.getNames().enumerated() {
            
            new_elems.append(select_action(name: name, at: i))
        }
        return new_elems
    }
    
    
    override func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        print("contextMenuInteraction")
        
        return UIContextMenuConfiguration.init(identifier: nil, previewProvider: nil, actionProvider: {elems in
            UIMenu(title:"Sound", children: self.build_sound_elements())
        })
    }
    
    
}

class StepEditController: UIViewController
{
    var time_str = "000000";
    var timer_index = 0
    var first_entry = true
    weak var step: TimerStep? = nil
    var repeatCount:UInt = 1
    
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var timeField: UILabel!
    @IBOutlet weak var soundButton: UIButton!
    @IBOutlet weak var repeatButton: UIButton!
    
    
    @IBAction func setRepeats(_ action: UICommand) {
     
        repeatCount = UInt(action.propertyList as! String) ?? 1
    }
    
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
            timeField.textColor = UIColor.white
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
            step.sound = soundButton.tag
            step.repeats = repeatCount
        }
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func cancelPressed(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        print("Step editor will appear")
        super.viewWillAppear(animated)
        if let step = step {
            nameField.text = step.name
            let time = step.duration
            time_str = TimeUtils.format_edit(interval: time)
            first_entry = true
            updatePresetField()
            soundButton.setTitle(TimerSounds.getName(step.sound), for: .normal)
            soundButton.tag = step.sound
            
            repeatCount = step.repeats
            let item = repeatButton.menu!.children.first(where: { item in
                if let command = item as? UICommand {
                    let count = Int(command.propertyList as! String)!
                    return count == step.repeats
                }
                return false
            })
            print(step)
            let command = item as? UICommand ?? repeatButton.menu!.children[0] as! UICommand
                
       
            repeatButton.setTitle(command.title, for: .normal)
        }
    }
}
    
