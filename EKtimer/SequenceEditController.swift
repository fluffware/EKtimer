//
//  SequenceEditController.swift
//  EKtimer
//
//  Created by Simon Berg on 2024-03-29.
//

import Foundation
import UIKit

class SequenceNameField: UITextField, UITextFieldDelegate
{
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        delegate = self
    }
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.selectAll(nil)
    }
}

class EditStepCell: UITableViewCell
{
    
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var soundLabel: UILabel!
    @IBOutlet weak var editButton: UIButton!
    weak var controller: SequenceEditController?
 
    weak var step: TimerStep?
    
    @IBAction func editRow(action: UIAction)
    {
        print("editRow")
        if let controller = controller {
           
            controller.performSegue(withIdentifier: "ToStepEdit", sender: self)
        }
    }
    
    
}
class SequenceEditController: UIViewController, UITableViewDataSource 
{
    weak var sequence: TimerSequence? = nil // This is set by the controller initiating the seague
    @IBOutlet weak var sequenceField: UITextField!
    @IBOutlet weak var countDirection: UIButton!
    @IBOutlet weak var stepList: UITableView!
   
    
    @IBAction func countUpSelected(_ action: UIAction) {
        countDirection.setTitle(action.title, for: .normal)
        sequence?.countUp = true
    }
    
    @IBAction func countDownSelected(_ action: UIAction) {
        countDirection.setTitle(action.title, for: .normal)
        sequence?.countUp = false
    }

    @IBAction func addRow( action: UIAction)
    {
        if let sequence = sequence {
            let step = TimerStep(name: String(localized: "New step", comment: "Default name for newly created step"), duration: 90, sound: 0)
            // Insert after last step
            sequence.steps.append(step)
            let path = IndexPath(row: sequence.steps.count - 1, section: 0)
            stepList.insertRows(at: [path], with: .automatic)
            let new_cell = stepList.cellForRow(at: path)
            performSegue(withIdentifier: "ToStepEdit", sender: new_cell)
        }
    }
    
    @IBAction func editOK( action: UIAction)
    {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func editDelete( action: UIAction)
    {
        if let sequence = sequence {
            let title = String(localized: "DeleteConfirmTitle", defaultValue: "Delete sequence", comment: "Title for delete sequence alert")
            let message = String(localized: "Do you really want to delete sequence \(sequence.name)", comment: "Ask user to confirm deletion of sequence")
            let alertController = UIAlertController(
                title: title,
                message: message,
                preferredStyle: .alert)
            
            alertController.addAction(UIAlertAction(title: String(localized: "KeepSeq", defaultValue: "Keep", comment: "Choose to keep sequence"), style: .default, handler: nil))
            alertController.addAction(UIAlertAction(title: String(localized: "DeleteSeq", defaultValue: "Delete", comment: "Choose to delete sequence"), style: .destructive, handler: { _ in
                AppData.remove(sequence: sequence)
                self.navigationController?.popViewController(animated: true)
            }))

                   // Present the alert controller
            present(alertController, animated: true, completion: nil)
         
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let children = countDirection?.menu?.children {
            if children.count >= 2 {
                let index = (sequence?.countUp ?? true) ? 0 : 1
                countDirection.setTitle(children[index].title, for: .normal)
            }
        }
        if let sequence = sequence {
            sequenceField?.text = sequence.name
            
        }
        
        stepList.reloadData()
        stepList.setEditing(true, animated: false)
    }
    
    func showErrorDialog(message: String) {
        // Create an alert controller
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        
        // Add an action (button)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        // Present the alert controller
        present(alertController, animated: true, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if let sequence = sequence {
            sequence.name = sequenceField.text ?? ""
        }
        do {
            try AppData.save_preferences()
        } catch {
            showErrorDialog(message: "Failed to save sequence")
        }
    }
    func updateStepList()
    {
        
        if let sequence = sequence {
            
            let steps = sequence.steps
            for cell in stepList.visibleCells {
                let cell = cell as! EditStepCell
                let index = stepList.indexPath(for: cell)?.row ?? 0
                let step = steps[index]
                if index < sequence.steps.count {
                    
                  
                    cell.nameLabel.text = step.name
                    cell.durationLabel.text = TimeUtils.format(interval: step.duration)
                    cell.soundLabel.text = TimerSounds.getName(step.sound)
                }
            }
        }
    }
    
    // Return the number of rows for the table.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sequence?.steps.count ?? 0
    }
    
    // Provide a cell object for each row.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Fetch a cell of the appropriate type.
        let cell = tableView.dequeueReusableCell(withIdentifier: "editStepCellStyle", for: indexPath)
        let index = indexPath.item
        // Configure the cell’s contents.
        if let cell = cell as? EditStepCell {
            if let steps = sequence?.steps {
                if index >= 0 && index < steps.count {
                    let step = steps[index]
                    cell.nameLabel.text = step.name
                    cell.durationLabel.text = TimeUtils.format(interval: step.duration)
                    cell.soundLabel.text = TimerSounds.getName(step.sound)
                    cell.controller = self
                    cell.step = step
                }
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if let sequence = sequence {
            let step = sequence.steps.remove(at: sourceIndexPath.row)
            sequence.steps.insert(step, at: destinationIndexPath.row)
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath)
    {
        if let sequence = sequence {
            switch editingStyle {
            case .delete:
                sequence.steps.remove(at: indexPath.row)
                stepList.deleteRows(at: [indexPath], with: .automatic)
                break
            case .insert:
               break
            default:
                break
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("SequenceEditController.prepare")
        if let cell = sender as? EditStepCell {
            if let dest = segue.destination as? StepEditController {
                dest.step = cell.step
            }
        }
  
    }
}
