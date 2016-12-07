//
//  Helper.swift
//  Pomodoro Timer
//
//  Created by Adam Parr on 05/12/2016.
//  Copyright © 2016 Adam Parr. All rights reserved.
//

import Foundation

extension Int {
    func timeFormatted() -> String {
        
        let seconds: Int = self % 60
        let minutes: Int = (self / 60) % 60
        
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

enum WorkingState {
    case work, rest
}
