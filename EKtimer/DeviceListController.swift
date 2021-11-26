//
//  DeviceListController.swift
//  EKtimer
//
//  Created by Simon on 2021-11-24.
//

import Foundation
import UIKit

class DeviceCell: UITableViewCell
{
    @IBOutlet weak var nameText: UILabel!
    @IBOutlet weak var editButton: UIButton!

    weak var context: Device?;
    var device_index = 0
    
    func updateCell()
    {
        nameText.text = context?.name
    }
}
class DeviceListController: UITableViewController
{
    required init?(coder: NSCoder)
        {
            super.init(coder: coder)
            
        }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        for cell in tableView.visibleCells as! [DeviceCell] {
            cell.updateCell()
        }
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return AppData.getAppdata().devices.count;
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "deviceCellStyle", for: indexPath) as! DeviceCell
        cell.context = AppData.getAppdata().devices[indexPath.row]
        cell.device_index = indexPath.row
        cell.editButton.tag = indexPath.row;
      
        cell.updateCell()
        
        return cell;
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let app_data = AppData.getAppdata()
        switch editingStyle {
        case .delete:
            app_data.devices[indexPath.row].close()
            app_data.devices.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
            do {
            try AppData.save_app_data()
            } catch {}
        case .insert:
            app_data.devices.insert(Device(), at: indexPath.row)
            do {
            try AppData.save_app_data()
            } catch {}
        default:
            break
        }
    }
    
    
    @IBAction func addDevice(_ sender: UIBarButtonItem) {
        let app_data = AppData.getAppdata()
        app_data.devices.append(Device())
        tableView.insertRows(at: [IndexPath(row: app_data.devices.count - 1, section: 0)], with: UITableView.RowAnimation.none)
    }
}
