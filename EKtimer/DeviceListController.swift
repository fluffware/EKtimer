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
        return AppData.getDevices().count;
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "deviceCellStyle", for: indexPath) as! DeviceCell
        cell.context = AppData.getDevices()[indexPath.row]
        cell.device_index = indexPath.row
        cell.editButton.tag = indexPath.row;
      
        cell.updateCell()
        
        return cell;
    }
    
    }

