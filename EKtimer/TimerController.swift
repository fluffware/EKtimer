//
//  TimerController.swift
//  EKtimer
//
//  Created by Simon Berg on 2024-03-25.
//

import Foundation
import UIKit

class SequenceButton: UIButton
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
            if let controller = self.controller {
                controller.sequenceChanged(index: index)
            }
            
        }
    }
    
    func build_sequence_elements(from: [UIMenuElement]) -> [UIMenuElement]
    {
        
        var new_elems = from
        for (i,seq) in AppData.getSequences().enumerated() {
            
            new_elems.append(select_action(name: seq.name, at: i))
        }
        return new_elems
    }
    
    
    override func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        print("contextMenuInteraction")
        return UIContextMenuConfiguration.init(identifier: nil, previewProvider: nil, actionProvider: {elems in
            UIMenu(title:"Sequence", children: self.build_sequence_elements(from: elems))
        })
    }
    
    
}

class StepCell: UITableViewCell
{
    
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var elapsedLabel: UILabel!
    @IBOutlet weak var remainingLabel: UILabel!
    @IBOutlet weak var progress: UIProgressView!
    
    weak var step: TimerStep?
    
    
    
    
}

class TimerController: UIViewController, UITableViewDataSource {
    @IBOutlet weak var count: UILabel?;
    @IBOutlet weak var button_box: UIStackView?;
    weak var timer: Timer? = nil;
    
    @IBOutlet weak var timeText: UILabel!
    @IBOutlet weak var countUpIndicator: UIView!
    @IBOutlet weak var countDownIndicator: UIView!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var addButton: UIButton!
    
    @IBOutlet weak var sequenceButton: UIButton?
    @IBOutlet weak var stepList: UITableView?
    
    weak var context: TimerState?;
    
    var currentStep: Int = 0
  
    @IBAction func startPressed(_ sender: UIButton) {
    
        if let ctxt = context {
            ctxt.start()
            updateTime()
            let _ = updateStepList()
            ClockDevices.start()
            print("Start")
        }
    }
    @IBAction func stopPressed(_ sender: UIButton) {
        if let ctxt = context {
            
            ctxt.stop()
            updateTime()
            let _ = updateStepList()
            ClockDevices.stop()
            TimerSounds.stop()
            print("Stop")
        }
    }
    var reset_timer: Timer? = nil
    
    
    
    func doReset(_: Timer) {
        if let ctxt = context {
            reset_timer = nil
            ctxt.reset()
            updateTime()
            let _ = updateStepList()
            ClockDevices.set(function: ctxt.countUp() ? .count_up : .count_down)
            ClockDevices.reset(to: ctxt.preset())
            TimerSounds.stop()
            currentStep = 0
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
    
    @IBAction func editSequence(_ sender: UIButton) {
        if context?.sequence_index == 1 {
            performSegue(withIdentifier: "ToStepEdit", sender: editButton)
        } else {
            performSegue(withIdentifier: "ToSequenceEdit", sender: editButton)
        }
    }
    @IBAction func silenceSound(_ sender: UIButton) {
        TimerSounds.stop()
    }
    
    func updateCell()
    {
        updateTime()
        let _ = updateStepList()
     
    }
    
    // Currently elapsed time
    func elapsed(state: TimerState) -> TimeInterval
    {
        
        switch state.count {
        case .running(let zero):
            let now = ProcessInfo.processInfo.systemUptime;
            return now - zero
        case .stopped(let t):
            return t
            
        }
        
    }
    
    func updateTime()
    {
        
        if let ctxt = context {
            var time = elapsed(state: ctxt)
            
            if let sequence = ctxt.sequence {
                if !sequence.countUp {
                    time = ctxt.preset() - time
                }
            }
            timeText.text = TimeUtils.format(interval: time)
        }
    }
    
    func updateTime(_ timer: Timer)
    {
        updateTime();
        let step = updateStepList()
        if let steps = context?.sequence?.steps {
            if step > currentStep && step <= steps.count {
                print("Next step")
                TimerSounds.play(withIndex: steps[step-1].sound, times: steps[step-1].repeats)
            }
        }
        currentStep = step
    }
    
    func updateStepList() -> Int
    {
        if let state = context {
            if let sequence = state.sequence {
                let time = elapsed(state: state)
                // Find the active step
                var sum = 0.0;
                var active_index = 0;
                var active_start = 0.0;
                for step in sequence.steps {
                    sum += step.duration;
                    if sum < time {
                        active_index += 1
                        active_start = sum
                    }
                }
                if let list = stepList {
                    for cell in list.visibleCells {
                        let cell = cell as! StepCell
                        let index = list.indexPath(for: cell)?.row ?? 0
                        if index < sequence.steps.count {
                            let duration = sequence.steps[index].duration
                            let step_time: TimeInterval
                            if index == active_index {
                                step_time = time - active_start
                                cell.backgroundColor = UIColor.yellow
                            } else if index > active_index {
                                step_time = 0.0
                                cell.backgroundColor = UIColor.white
                            } else {
                                step_time = sequence.steps[index].duration
                                cell.backgroundColor = UIColor.lightGray
                            }
                            cell.remainingLabel.text = TimeUtils.format(interval: duration - step_time)
                            cell.elapsedLabel.text = TimeUtils.format(interval: step_time)
                            if duration > 0.0 {
                                cell.progress.setProgress(Float(step_time / duration), animated: false)
                            }
                            
                        }
                    }
                }
                return active_index
            }
        }
        return 0
    }
    required init?(coder: NSCoder)
    {
        
        super.init(coder: coder)
        context = AppData.getTimer()
        
        
        
        
    }
    override func viewDidAppear(_ animated: Bool) {
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true, block: updateTime);
        sequenceButton?.showsMenuAsPrimaryAction = true
        var children : [UIAction] = []
        var index = context?.sequence_index ?? 0
        
        let sequencies = AppData.getSequences();
        if index >= sequencies.count {
            index = 0
            context?.sequence_index = 0
        }
        if index >= 0 && index < sequencies.count {
            context?.sequence = sequencies[index]
        }
        children.append(UIAction(title: context?.sequence?.name ?? "<Unknown>") {_ in
        })
        sequenceButton?.menu = UIMenu(title: "Sequences", children: children)
        sequenceChanged(index: index)
    }
    override func viewWillDisappear(_ animated: Bool) {
        if let timer = timer {
            timer.invalidate();
        }
        timer = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    func updateCountDirection() {
        if let count_up = context?.sequence?.countUp {
            countUpIndicator.isHidden = !count_up
            countDownIndicator.isHidden = count_up
        }
    }
    func sequenceChanged(index: Int) {
        print("Sequence \(index) selected")
        let sequencies = AppData.getSequences();
        if index >= 0 && index < sequencies.count {
            context?.sequence_index = index
            context?.sequence = sequencies[index]
            
            // First timer is special and can't be edited
            editButton?.isEnabled = index >= 1
            
        }
        if let context = context {
            context.reset()
            ClockDevices.set(function: context.countUp() ? .count_up : .count_down)
            ClockDevices.reset(to: context.preset())
        }
        updateTime()
        stepList?.reloadData()
        updateCountDirection()
        
    }
    
    // Return the number of rows for the table.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("Step count: \(context?.sequence?.steps.count ?? 0)")
        return context?.sequence?.steps.count ?? 0
    }
    
    
    // Provide a cell object for each row.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Fetch a cell of the appropriate type.
        let cell = tableView.dequeueReusableCell(withIdentifier: "stepCellStyle", for: indexPath)
        let index = indexPath.item
        // Configure the cell’s contents.
        if let cell = cell as? StepCell {
            if let steps = context?.sequence?.steps {
                if index >= 0 && index < steps.count {
                    let step = steps[index]
                    cell.nameLabel.text = step.name
                    cell.durationLabel.text = TimeUtils.format(interval: step.duration)
                    cell.elapsedLabel.text = TimeUtils.format(interval: 0.0)
                    cell.remainingLabel.text = TimeUtils.format(interval: step.duration)
                }
            }
        }
        return cell
    }
    
    override func viewWillLayoutSubviews() {
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let editor = segue.destination as? SequenceEditController {
            if let button = sender as? UIButton {
                if button === addButton {
                    let sequence = TimerSequence(name: String(localized: "New sequence"))
                    context?.sequence = sequence
                    context?.sequence_index = AppData.getSequences().count
                    AppData.add(sequence: sequence)
                }
            }
            editor.sequence = context?.sequence
        }
        if let editor = segue.destination as? StepEditController {
            editor.step = context?.sequence?.steps[0]
        }
    }
}
