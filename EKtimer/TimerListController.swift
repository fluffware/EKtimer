//
//  ViewController.swift
//  EKtimer
//
//  Created by Simon on 2021-11-17.
//

import UIKit
import Foundation



func format(interval time: TimeInterval) -> String
{
    let sign = time >= 0 ? " " : "-";
    let seconds = Int(abs(time))
    let minutes = seconds / 60
    let hours = minutes / 60
    return String(format: "%@%02d:%02d:%02d", sign, hours%100, minutes%60, seconds%60)
}

class TimerCell: UITableViewCell
{
    @IBOutlet weak var nameText: UILabel!
    @IBOutlet weak var timeText: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
    
    weak var context: TimerState?;
    var timer_index = 0
    @IBAction func startPressed(_ sender: UIButton) {
        if let ctxt = context {
            ctxt.start()
            updateTime()
            print("Start")
        }
    }
    @IBAction func stopPressed(_ sender: UIButton) {
        if let ctxt = context {
           
            ctxt.stop()
            updateTime()
            print("Stop")
        }
    }
    var reset_timer: Timer? = nil
    
    
    
    func doReset(_: Timer) {
        if let ctxt = context {
            reset_timer = nil
            ctxt.reset()
            updateTime()
        }
    }
    
    @IBAction func resetReleased(_ sender: UIButton) {
        if let timer = reset_timer {
            timer.invalidate()
        }
        reset_timer = nil
    }
    @IBAction func resetPressed(_ sender: UIButton) {
        reset_timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block:doReset)
    }
    
    override func willTransition(to state: UITableViewCell.StateMask) {
        switch(state)
        {
        default:
            break;
        }
    }
    
    func updateCell()
    {
        updateTime()
    }
    
    func updateTime()
    {
        if let ctxt = context {
            var time: TimeInterval
            switch ctxt.count {
            case .running(let zero):
                let now = ProcessInfo.processInfo.systemUptime;
                time = now - zero
            case .stopped(let t):
                time = t
                
            }
            if let sequence = ctxt.sequence {
                if !sequence.countUp {
                    time = ctxt.preset() - time
                }
            }
           
            
            timeText.text = format(interval: time)
        }
    }
    
    
}

class ViewController: UITableViewController {
    weak var timer: Timer? = nil;
    
    required init?(coder: NSCoder)
        {
            super.init(coder: coder)
            
        }
    
    func updateTime(_ timer: Timer)
    {
        let cells = tableView.visibleCells;
        for cell  in cells {
            let timer = cell as! TimerCell;
            timer.updateTime();
        }
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //print("ViewController")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true, block: updateTime);
    }
    override func viewWillDisappear(_ animated: Bool) {
        if let timer = timer {
            timer.invalidate();
        }
        timer = nil
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        for cell in tableView.visibleCells as! [TimerCell] {
            cell.updateCell()
        }
    }
    
   
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "timerCellStyle", for: indexPath) as! TimerCell
        cell.context = AppData.getTimer()
        cell.timer_index = indexPath.row
        cell.editButton.tag = indexPath.row;
      
        cell.updateCell()
        
        return cell;
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let sender = sender else {
            return
        }
        if let s = sender as? UIButton {
            if let editor = segue.destination as? TimerEditController {
                editor.timer_index = s.tag;
            }
        }
        print("Sender: \(sender)")
    }
    
}

