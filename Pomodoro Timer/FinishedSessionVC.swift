//
//  FinishedSessionVC.swift
//  Pomodoro Timer
//
//  Created by Adam Parr on 04/12/2016.
//  Copyright © 2016 Adam Parr. All rights reserved.
//

import UIKit

class FinishedSessionVC: UIViewController {
    
    // MARK: Properties -------------------------------------
    
    @IBOutlet weak var totalWorkTimeLabel: UILabel!
    @IBOutlet weak var totalBreakTimeLabel: UILabel!
    
    var totalWorkTime = 0
    var totalBreakTime = 0
    
    // MARK: Overrides --------------------------------------
    
    override func viewDidLoad() {
        
        totalWorkTimeLabel.text = "You have worked for \(totalWorkTime.timeFormatted()) minutes."
        totalBreakTimeLabel.text = "You have taken \(totalBreakTime.timeFormatted()) minutes in breaks."
    }
    
}
