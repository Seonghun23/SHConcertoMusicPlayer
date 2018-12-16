//
//  ConsertoMusicPlayer.swift
//  SHConcertoMusicPlayer
//
//  Created by Seonghun Kim on 12/12/2018.
//  Copyright © 2018 Seonghun Kim. All rights reserved.
//

import Foundation
import AVFoundation

open class ConsertoMusicPlayer {
    // MARK:- Singleton
    /**
     Concerto Music Player Singleton Class.
     
     This class include every properties ans method for Concerto Music Player.
     */
    static let shared = ConsertoMusicPlayer()
    
    // MARK:- Notification Name Properties
    public let StartPlaySongNotification = Notification.Name("StartPlaySong")
    public let EndPlaySongNotification = Notification.Name("EndPlaySong")
    
    // MARK:- Player Properties
    private var player = [AVPlayer]()
    private var keyPlayerItem: AVPlayerItem?
    private var playTime = CMTimeMake(value: 1, timescale: 600)
    private var playRate: Float = 0.1
    
    // MARK:- Observer Properties
    private let playbackLikelyToKeepUpKeyPath = \AVPlayerItem.isPlaybackLikelyToKeepUp
    private var playbackLikelyToKeepUpKeyPathObserver = [Int:NSKeyValueObservation]()
    
    private let statusKeyPath = \AVPlayerItem.status
    private var statusKeyPathObserver = [Int:NSKeyValueObservation]()
    
    // MARK:- play Status
    /**
     Play status Property.
     
     When Music Player is Playing, It's true.
     */
    public var nowPlaying = false
    private var readyToPlay = false
    
    // MARK:- Initialize
    /**
     Change View to Grade View.
     
     This Method change layout, background color and text about UIView.
     
     ```
     let keySong = URL(string: "https://UrlAddress")
     let songList = [URL(string: "https://UrlAddress"), URL(string: "https://UrlAddress"), URL(string: "https://UrlAddress")]
     
     let songs = SongList(keySong: URL(), songList: [URL()])
     let play = true
     
     initializePlayer(songs: songs, play: play, completion: { (playInfo: PlayInfo?) in
        if let playInfo = playInfo {
            // Success Initialize Conserto Music Player
        } else {
            // Fail Initialize Conserto Music Player
        }
     })
     
     ```
     
     - parameters:
        - songs: Play Song List.
        - play: If it's true, Play Song immediately after ready.
        - completion: It's include Play Information.
     */
    final func initializePlayer(songs: SongList, play: Bool, completion: (PlayInfo?) -> Void) {
        stopPlay()
        player = []
        playTime = CMTimeMake(value: 1, timescale: 600)
        playRate = 0.1
        nowPlaying = play
        readyToPlay = false
        
        setPlayer(url: songs.playList)
        
        for i in player.indices {
            if let item = player[i].currentItem {
                keyPlayerItem = item
                
                let playInfo = PlayInfo(duration: item.asset.duration.seconds, currentTime: item.currentTime().seconds)
                
                completion(playInfo)
                return
            }
        }
        
        print("Fail to Initialize Conserto Music Player")
        completion(nil)
    }
    
    private func setPlayer(url: [URL]) {
        for i in url.indices {
            let playItem = AVPlayerItem(url: url[i])
            
            setAVPlayerItemObserver(key: i, item: playItem)
            
            let vPlayer = AVPlayer(playerItem: playItem)
            vPlayer.volume = 1.0
            vPlayer.actionAtItemEnd = .pause
            vPlayer.automaticallyWaitsToMinimizeStalling = false
            
            player.append(vPlayer)
            
            if i == 0 {
                NotificationCenter.default.addObserver(self, selector: #selector(finishMusic(note:)), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: playItem)
            }
        }
    }
    
    // MARK:- Observe AVPlayerItem
    private func setAVPlayerItemObserver(key: Int, item playItem: AVPlayerItem) {
        if playItem.status != .readyToPlay {
            statusKeyPathObserver[key] = playItem.observe(statusKeyPath, options: [.new]) { [weak self] (item, _) in
                guard let VC = self else { return }
                
                if item.status == .readyToPlay {
                    VC.statusKeyPathObserver.removeValue(forKey: key)
                    VC.checkObserver()
                } else if item.status == .failed {
                    VC.statusKeyPathObserver.removeValue(forKey: key)
                    VC.playbackLikelyToKeepUpKeyPathObserver.removeValue(forKey: key)
                    VC.checkObserver()
                }
            }
        }
        
        if !playItem.isPlaybackLikelyToKeepUp {
            playbackLikelyToKeepUpKeyPathObserver[key] = playItem.observe(playbackLikelyToKeepUpKeyPath, options: [.new]) { [weak self] (item, _) in
                guard let VC = self else { return }
                
                if item.isPlaybackLikelyToKeepUp {
                    VC.playbackLikelyToKeepUpKeyPathObserver.removeValue(forKey: key)
                    VC.checkObserver()
                }
            }
        }
    }
    
    // MARK:- Check Observer And Preroll Player
    private func checkObserver() {
        if statusKeyPathObserver.count == 0 && playbackLikelyToKeepUpKeyPathObserver.count == 0 && !readyToPlay {
            readyToPlay = true
            
            var count = 0
            for i in player {
                i.preroll(atRate: playRate) { (bool) in
                    count += 1
                    if count == 8, self.nowPlaying {
                        self.startPlay()
                    }
                }
            }
        }
    }
    
    // MARK:- Start Play
    private func startPlay() {
        NotificationCenter.default.post(name: ConsertoMusicPlayer.shared.StartPlaySongNotification, object: nil)
        let masterClock = CMClockGetTime(CMClockGetHostTimeClock())
        
        for i in self.player {
            i.setRate(1.0, time: playTime, atHostTime: masterClock)
        }
        for i in player {
            i.play()
        }
    }
    
    // MARK:- Stop Play
    private func stopPlay() {
        for i in player {
            i.pause()
        }
    }
    
    // MARK:- Return Current Time
    /**
     Return Key Song's current time.
     
     When you need to current tiem to Key Song, Call this method. And then, Return current time in Double.
     */
    public func currentTime() -> Double? {
        return keyPlayerItem?.currentTime().seconds
    }
    
    // MARK:- Return Duration
    /**
     Return Key Song's duration.
     
     When you need to duration to Key Song, Call this method. And then, Return duration in Double.
     */
    public func duration() -> Double? {
        return keyPlayerItem?.asset.duration.seconds
    }
    
    // MARK:- Play And Pause Method
    /**
     Play or Pause Concerto Music Player.
     
     This method handle Play and Pause to Concerto Music Player.
     
     - parameters:
        - isPlaying: If it's true, Start to Concerto Music Player. otherwise, Pause to Concerto Music Player.
     */
    final func Play(isPlaying: Bool) {
        if isPlaying {
            setPlay()
        } else {
            setPause()
        }
    }
    
    private func setPlay() {
        nowPlaying = true
        for i in player.indices {
            setAVPlayerItemObserver(key: i, item: player[i].currentItem!)
        }
        checkObserver()
    }
    private func setPause() {
        nowPlaying = false
        readyToPlay = false
        stopPlay()
        playTime = keyPlayerItem?.currentTime() ?? CMTimeMake(value: 1, timescale: 600)
    }
    
    // MARK:- Change Current Play Time
    /**
     Set Play tiem to Concerto Music Player.
     
     This method change current time to Concerto Music Player, If Player need to prepare for play music, Pause music and Play after ready to play.
     
     - parameters:
        - second: Play time in second.
     */
    final func chagePlayTime(second: Float) {
        if let duration = keyPlayerItem?.asset.duration.seconds {
            playRate = min((second / Float(duration)) + 0.1, 1.0)
        } else {
            playRate = 1.0
        }
        
        stopPlay()
        readyToPlay = false
        
        for i in player.indices {
            let vplayer = player[i]
            playTime = CMTimeMake(value: Int64(second), timescale: 1)
            
            vplayer.seek(to: playTime) { (bool) in
                self.setAVPlayerItemObserver(key: i, item: vplayer.currentItem!)
                if i == 7 {
                    self.checkObserver()
                }
            }
        }
    }
    
    // MARK:- After End Music
    @objc private func finishMusic(note: Notification) {
        guard let item = keyPlayerItem, let noti = note.object as? AVPlayerItem, item == noti else { return }
        NotificationCenter.default.post(name: ConsertoMusicPlayer.shared.EndPlaySongNotification, object: item)
        
        stopPlay()
        playTime = CMTimeMake(value: 1, timescale: 600)
        nowPlaying = false
    }
}
