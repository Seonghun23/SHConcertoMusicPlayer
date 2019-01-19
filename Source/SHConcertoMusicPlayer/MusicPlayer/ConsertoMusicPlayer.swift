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
    private var playTime = CMTimeMake(value: 0, timescale: 1)
    
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
    private var isLoading = false
    
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
        deleteCurrentPlayer(play: play)
        
        isLoading = true
        setPlayer(url: songs.playList)
        
        for p in player {
            if let item = p.currentItem {
                keyPlayerItem = item
                
                let playInfo = PlayInfo(duration: item.asset.duration.seconds, currentTime: item.currentTime().seconds)
                
                completion(playInfo)
                return
            }
        }
        
        print("Fail to Initialize Conserto Music Player")
        completion(nil)
    }
    
    public func deleteCurrentPlayer(play: Bool = false) {
        stopPlay()
        player = []
        playTime = CMTimeMake(value: 0, timescale: 1)
        nowPlaying = play
    }
    
    private func setPlayer(url: [URL]) {
        url.enumerated().forEach { (i, url) in
            let playItem = AVPlayerItem(url: url)
            
            setAVPlayerItemObserver(key: i, item: playItem, time: playTime)
            
            let vPlayer = AVPlayer(playerItem: playItem)
            vPlayer.volume = 1.0
            vPlayer.actionAtItemEnd = .pause
            vPlayer.automaticallyWaitsToMinimizeStalling = false
            
            player.append(vPlayer)
            
            if i == 0 {
                NotificationCenter.default.addObserver(self,
                                                       selector: #selector(finishMusic(note:)),
                                                       name: Notification.Name.AVPlayerItemDidPlayToEndTime,
                                                       object: playItem)
            }
        }
    }
    
    // MARK:- Observe AVPlayerItem
    private func setAVPlayerItemObserver(key: Int, item playItem: AVPlayerItem, time: CMTime) {
        if playItem.status != .readyToPlay {
            statusKeyPathObserver[key] = playItem.observe(statusKeyPath, options: [.new])
            { [unowned self] (item, value) in
                if value.newValue == .readyToPlay {
                    self.statusKeyPathObserver.removeValue(forKey: key)
                    self.setPreroll(time: time)
                } else if value.newValue == .failed {
                    self.statusKeyPathObserver.removeValue(forKey: key)
                    self.playbackLikelyToKeepUpKeyPathObserver.removeValue(forKey: key)
                    self.setPreroll(time: time)
                }
            }
        }
        
        if !playItem.isPlaybackLikelyToKeepUp {
            playbackLikelyToKeepUpKeyPathObserver[key] = playItem.observe(playbackLikelyToKeepUpKeyPath, options: [.new])
            { [unowned self] (item, value) in
                if value.newValue ?? false {
                    self.playbackLikelyToKeepUpKeyPathObserver.removeValue(forKey: key)
                    self.setPreroll(time: time)
                }
            }
        }
    }
    
    private func checkReadyToPreroll(time: CMTime) -> Bool {
        for (i, p) in player.enumerated() {
            guard let item = p.currentItem, item.status == .readyToPlay else { return false }
            if !item.isPlaybackLikelyToKeepUp || !item.isPlaybackBufferFull {
                setAVPlayerItemObserver(key: i, item: item, time: time)
                return false
            }
        }
        return true
    }
    
    // MARK:- Check Observer And Preroll Player
    private func setPreroll(time: CMTime) {
        guard checkReadyToPreroll(time: time) else { return }
        
        var count = 0
        let current = Float(currentTime() ?? 0.0)
        let duration = Float(keyPlayerItem?.asset.duration.seconds ?? 0.0)
        let rate = min((current / duration) + 0.1, 1.0)
        
        player.enumerated().forEach { (i, p) in
            p.preroll(atRate: rate) { bool in
                count += 1
                if count == self.player.count {
                    self.startPlay()
                } else {
                    self.isLoading = false
                }
                if !bool { print("Fail preroll : \(i)") }
            }
        }
    }
    
    // MARK:- Start Play
    private func startPlay() {
        print("Ready To Play")
        if playTime == keyPlayerItem?.currentTime() {
            let masterClock = CMClockGetTime(CMClockGetHostTimeClock())
            print("Start Play")
            player.enumerated().forEach{ (i, p) in
                p.setRate(1.0, time: playTime, atHostTime: masterClock)
                p.play()
                print("Play index : \(i) Player")
            }
            NotificationCenter.default.post(name: ConsertoMusicPlayer.shared.StartPlaySongNotification, object: nil)
            isLoading = false
        } else {
            print("Fail To Play Music")
            seekPlayer(time: playTime, true)
        }
    }
    
    // MARK:- Stop Play
    private func stopPlay() {
        player.forEach { $0.pause() }
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
        guard !player.isEmpty else { return }
        
        nowPlaying = isPlaying
        
        if isPlaying {
            setPlay()
        } else {
            setPause()
        }
    }
    
    private func setPlay() {
        seekPlayer(time: playTime)
    }
    private func setPause() {
        stopPlay()
        playTime = keyPlayerItem?.currentTime() ?? CMTimeMake(value: 0, timescale: 600)
    }
    
    // MARK:- Change Current Play Time
    /**
     Set Play tiem to Concerto Music Player.
     
     This method change current time to Concerto Music Player, If Player need to prepare for play music, Pause music and Play after ready to play.
     
     - parameters:
     - second: Play time in second.
     */
    final func chagePlayTime(second: Float) {
        guard !player.isEmpty else { return }
        
        stopPlay()
        playTime = CMTimeMake(value: Int64(second), timescale: 1)
        seekPlayer(time: playTime)
    }
    
    private func seekPlayer(time: CMTime, _ fire: Bool = false) {
        guard (!isLoading || fire) else { return }
        print("Start Seek Player")
        isLoading = true
        
        var count = 0
        
        player.enumerated().forEach { (i, p) in
            p.seek(to: time) { bool in
                count += 1
                self.setAVPlayerItemObserver(key: i, item: p.currentItem!, time: time)
                if count == self.player.count { self.setPreroll(time: time) }
            }
        }
    }
    
    // MARK:- After End Music
    @objc private func finishMusic(note: Notification) {
        guard let item = keyPlayerItem, let noti = note.object as? AVPlayerItem, item == noti else { return }
        NotificationCenter.default.post(name: ConsertoMusicPlayer.shared.EndPlaySongNotification, object: item)
        
        stopPlay()
        playTime = CMTimeMake(value: 1, timescale: 600)
        player.forEach{ $0.cancelPendingPrerolls() }
        nowPlaying = false
        isLoading = false
    }
}
