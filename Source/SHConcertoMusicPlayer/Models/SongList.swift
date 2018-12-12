//
//  SongList.swift
//  SHConcertoMusicPlayer
//
//  Created by Seonghun Kim on 12/12/2018.
//  Copyright © 2018 Seonghun Kim. All rights reserved.
//

import Foundation

// MARK:- Song's URL List
public struct SongList {
    var playList = [URL]()
    
    mutating func addPlayList(url: URL) {
        playList.append(url)
    }
    
    init(keySong: URL?, songList: [URL]) {
        if let url = keySong {
            addPlayList(url: url)
        }
        for i in songList {
            addPlayList(url: i)
        }
    }
}
