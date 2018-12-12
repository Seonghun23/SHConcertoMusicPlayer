//
//  PlayInfo.swift
//  SHConcertoMusicPlayer
//
//  Created by Seonghun Kim on 12/12/2018.
//  Copyright © 2018 Seonghun Kim. All rights reserved.
//

import Foundation

// MARK:- Play Information Model
public struct PlayInfo {
    let duration: Double
    let currentTime: Double
    
    init(duration: Double = 0.0, currentTime: Double = 0.0) {
        self.duration = duration
        self.currentTime = currentTime
    }
}
