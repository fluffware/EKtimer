//
//  DeviceEditController.swift
//  EKtimer
//
//  Created by Simon on 2021-11-24.
//

import Foundation
import UIKit


class DeviceEditController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource
{
    
    
   
    @IBOutlet weak var timerPicker: UIPickerView!
    
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var hostField: UITextField!
    @IBOutlet weak var intensityField: UILabel!
    @IBOutlet weak var intensityStepper: UIStepper!
    @IBOutlet weak var signalTimeField: UILabel!
    @IBOutlet weak var signalTimeStepper: UIStepper!
    
    var device_index = 0
    var first_entry = true
    
    var timerNames: [String] = []
    private func saveDevice()
    {
        
        
        let app_data = AppData.getAppdata()
        print("Updating device \(device_index)")
        let device = app_data.devices[device_index]
        device.close()
        device.connectedTimer?.devices.removeAll(where: {dev in return dev.device === device})
        device.host = hostField.text ?? ""
        device.name = nameField.text ?? ""
        device.connectedTimer = app_data.timers[timerPicker.selectedRow(inComponent: 0)]
        device.connectedTimer?.devices.append(WeakDevice(device))
        device.connection = WesterstrandConnection(to: device.host)
        do {
            try AppData.save_app_data()
        } catch {
            let alert = UIAlertController(title: "Failed to save timer settings", message: "Changes made to timer may be lost", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    @IBAction func intensityChanged(_ sender: UIStepper) {
        intensityField.text = String(Int(sender.value))
    }
    
    @IBAction func signalTimeChanged(_ sender: UIStepper) {
        signalTimeField.text = String(Int(sender.value))
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        print("Editor will apear")
        super.viewWillAppear(animated)
        let app_data = AppData.getAppdata()
        let device = app_data.devices[device_index]
        nameField.text = device.name
        hostField.text = device.host
        
       
        
        timerNames = []
        for timer in app_data.timers {
            timerNames.append(timer.name)
        }
        
        first_entry = true
        
        let timer_index = app_data.getTimerIndex(forDevice: device) ?? 0
        timerPicker.selectRow(timer_index, inComponent: 0, animated: false)
    }
    @IBAction func okPressed(_ sender: UIButton) {
        saveDevice()
        self.navigationController?.popViewController(animated: true)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let sender = sender else {
            return
        }
        if let s = sender as? UIButton {
            if let device = segue.destination as? DeviceEditController {
                device.device_index = s.tag;
            }
        }
       
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return timerNames.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return timerNames[row]
    }
   
}
