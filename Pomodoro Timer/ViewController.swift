//
//  ViewController.swift
//  Pomodoro Timer
//
//  Created by Adam Parr on 03/12/2016.
//  Copyright © 2016 Adam Parr. All rights reserved.
//

import UIKit
import UserNotifications

class ViewController: UIViewController {
    
    // MARK: Properties -------------------------------------
    
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stateLabel: UILabel!
    
    var timer = Timer()
    var timerExpirationDate = NSDate()
    
    var workLength = 999
    var breakLength = 999
    var timerCountdown = 0 {
        didSet {
            timerLabel.text = timerCountdown.timeFormatted()
        }
    }
    
    var onBreak = false {
        didSet {
            if onBreak {
                stateLabel.text = "Break time!"
            } else {
                stateLabel.text = "Working!"
            }
        }
    }
    
    var totalWorkTime = 0
    var totalBreakTime = 0
    
    // MARK: Actions ----------------------------------------
    
    @IBAction func startButton(_ sender: Any) {
        
        if startButton.titleLabel?.text == "START" {
            startButton.setTitle("GIVE UP", for: .normal)
            
            if onBreak {
                stateLabel.text = "Break time!"
                
            } else {
                stateLabel.text = "Working!"
            }
            startTimer(for: .work)
            
        } else if startButton.titleLabel?.text == "GIVE UP" {
            startButton.setTitle("START", for: .normal)
            
            timer.invalidate()
            
            giveUp()
            
        } else if startButton.titleLabel?.text == "STOP BREAK" {
            startButton.setTitle("GIVE UP", for: .normal)
            
            timer.invalidate()
            
            getBackToWork()
        }
    }
    
    // MARK: Overrides --------------------------------------
    
    override func viewDidLoad() {
        
        // if in simulator, configure time intervals
        #if (arch(i386) || arch(x86_64))
            workLength = 10 // easier to debug
            breakLength = 10 // ^^^^^^^^^^^^^^
        #else
            workLength = 10 //1500 // 25 minutes
            breakLength = 10 //300 // 5 minutes
        #endif
        
        // request user to use notifications
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge], completionHandler: {didAllow, error in})
        } else {
            
        }
        
        timerCountdown = workLength
        
        timerLabel.text = timerCountdown.timeFormatted()
    }
    
    // MARK: Segue ------------------------------------------
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let vc = segue.destination as? FinishedSessionVC {
            print(totalWorkTime, totalBreakTime)
            vc.totalWorkTime = totalWorkTime
            vc.totalBreakTime = totalBreakTime
        }
    }
    
    // MARK: Methods ----------------------------------------
    
    func updateCounter() {
        
        if onBreak {
            totalBreakTime += 1
        } else {
            totalWorkTime += 1
        }
        
        timerCountdown -= 1
        
        if timerCountdown == 0 {
            timer.invalidate()
            
            if onBreak {
                getBackToWork()
            
            } else {
                takeABreak()
            }
        }
    }
    
    
    func startTimer(for state: WorkingState) {
        
        if state == .work {
            timerCountdown = workLength
        } else if state == .rest {
            timerCountdown = breakLength
        }

        timerExpirationDate = NSDate(timeIntervalSinceNow: TimeInterval(timerCountdown))
        
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateCounter), userInfo: nil, repeats: true)
    }
    
    
    func takeABreak(_ cowardBreak: Bool = false) {
        
        onBreak = true
        timerCountdown = breakLength
        
        startButton.setTitle("STOP BREAK", for: .normal)
        
        let ac: UIAlertController
        
        if cowardBreak {
            ac = UIAlertController(title: "You coward", message: "Here's your 5 minute break", preferredStyle: .alert)
            
        } else {
            ac = UIAlertController(title: "Well done!", message: "Take a 5 minute break. \nYou've earned it!", preferredStyle: .alert)
        }
        
        ac.addAction(UIAlertAction(title: "Start break", style: .default) { [unowned self]_ in
            self.startTimer(for: .rest)
        })
        
        presentNotification(for: .rest)
        
        present(ac, animated: true)
    }
    
    
    func getBackToWork() {
        
        onBreak = false
        timerCountdown = workLength
        
        let ac = UIAlertController(title: "Breaks up!", message: "You have worked for \(totalWorkTime.timeFormatted()) minutes today! Continue?", preferredStyle: .alert)
        
        ac.addAction(UIAlertAction(title: "Start working", style: .default) { [unowned self]_ in
            self.startTimer(for: .work)
        })
        
        ac.addAction(UIAlertAction(title: "That's enough", style: .default) { [unowned self]_ in
            self.presentFinishScreen()
        })
        
        presentNotification(for: .work)
        
        present(ac, animated: true)
    }
    
    
    func giveUp() {
        
        let ac = UIAlertController(title: "Give up?", message: "Are you sure you want to give up?", preferredStyle: .alert)
        
        ac.addAction(UIAlertAction(title: "I'm a coward", style: .default) { [unowned self]_ in
            self.presentFinishScreen()
        })
        
        ac.addAction(UIAlertAction(title: "No! I can do this!", style: .default) { [unowned self]_ in
            self.startTimer(for: .pass)
            self.startButton.setTitle("GIVE UP", for: .normal)
        })
        
        ac.addAction(UIAlertAction(title: "I need a break", style: .default) { [unowned self]_ in
            self.takeABreak(true)
        })
    
        present(ac, animated: true)
    }
    
    
    func presentFinishScreen() {
        
        performSegue(withIdentifier: "finishedWorking", sender: self)
    }
    
    // MARK: Notifications ----------------------------------
    
    func presentNotification(for state: WorkingState) {
        if #available(iOS 10.0, *) {
            let content = UNMutableNotificationContent()
            
            if state == .work {
                // Tell user to get back to work
                content.title = "Breaks up!"
                content.body = "Get back to work!"
                content.sound = UNNotificationSound.default()
                content.badge = 1
                
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                let request = UNNotificationRequest(identifier: "timeForWork", content: content, trigger: trigger)
                
                UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                
            } else if state == .rest {
                // Tell user it's time for a break
                content.title = "Time for a break!"
                content.body = "Well done! Take a 5 minute break."
                content.sound = UNNotificationSound.default()
                content.badge = 1
                
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                let request = UNNotificationRequest(identifier: "timeForBreak", content: content, trigger: trigger)
                
                UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
            }
        } else {
            let notification = UILocalNotification()
            
            if state == .work {
                // Tell user to get back to work
                notification.alertTitle = "Breaks up!"
                notification.alertBody = "Get back to work!"
                notification.soundName = UILocalNotificationDefaultSoundName
                notification.applicationIconBadgeNumber = 1
                
                UIApplication.shared.scheduleLocalNotification(notification)
                
            } else if state == .rest {
                // Tell user it's time for a break
                notification.alertTitle = "Time for a break!"
                notification.alertBody = "Well done! Take a 5 minute break."
                notification.soundName = UILocalNotificationDefaultSoundName
                notification.applicationIconBadgeNumber = 1
                
                UIApplication.shared.scheduleLocalNotification(notification)
            }
        }
    }
    
    
    
}

