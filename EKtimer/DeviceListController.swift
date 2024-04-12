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
    @IBOutlet weak var hostText: UILabel!
    weak var context: Device?;
    var device_index = 0
    
    func updateCell()
    {
        nameText.text = context?.name
        hostText.text = context?.host
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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        for cell in tableView.visibleCells as! [DeviceCell] {
            cell.updateCell()
        }
    }
  
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print(String(format: "Device count: %d", AppData.getDevices().count))
        return AppData.getDevices().count;
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "deviceCellStyle", for: indexPath) as! DeviceCell
        cell.context = AppData.getDevices()[indexPath.row]
        cell.device_index = indexPath.row
     
        cell.updateCell()
        
        return cell;
    }
    
    final let HEADER_SIZE = 40.0
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView(frame: CGRect.init(x: 0, y:0,width: tableView.frame.width, height: 50))
        let name = UILabel(frame: CGRect.init(x: 5,y: 5, width: header.frame.width/2-10, height: header.frame.height-10))
        name.text = String(localized: "Name")
        name.font = .systemFont(ofSize: HEADER_SIZE)
        header.addSubview(name)
        let host = UILabel(frame: CGRect.init(x: header.frame.width/2 + 5,y: 5, width: header.frame.width/2-10, height: header.frame.height-10))
        host.text = String(localized: "IP-address")
        host.font = .systemFont(ofSize: HEADER_SIZE)
        header.addSubview(host)
        return header
    }
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    }

