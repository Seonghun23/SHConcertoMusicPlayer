# SHConcertoMusicPlayer


This is Multiple Music Player in a Same Time with Perfect Sync. SHConcertoMusicPlayer is support Streaming. 

## Requirements

- iOS 10.0+
- Xcode 8


#### Initializers:
* `ConsertoMusicPlayer.shared.initializePlayer(songs: SongList, play: Bool, completion: (PlayInfo?) -> Void)`

#### properties:
* `var nowPlaying: Bool`
    * if true, Player is Playing Song
* `let StartPlaySongNotification: Notification.Name`
    * When Start Play song, Notification will post with this Notification Name
* `let EndPlaySongNotification: Notification.Name`
    * When End Play song, Notification will post with this Notification Name

#### method:
* `public func currentTime() -> Double?`
    * Retun to key song's Current Play Time.
* `public func duration() -> Double?`
    * Return to key song's duration Time.
* `final func Play(isPlaying: Bool)`
    * When isPlaying is true, Start prepare for Play. After then, Start Play and Post Notification
    * When isPlaying is false,  Pause Play immediately.
* `final func chagePlayTime(second: Float)`
    * It is possible to process before, during, and after the value change.

#### struct:
 * `PlayInfo(duration: Float = 0.0, currentTime: Float = 0.0)`
    * After Initailize Player, Completion Handler give Duration and Current Time.
 * `SongList(keySong: URL?, songList: [URL])`
    * Play based on Key Song. if it is nil, First Song to songList become Key Song


#### Example:
```
ConsertoMusicPlayer.shared.initializePlayer(songs: songList, play: true) { (playInfo) in
    let duration = playInfo.duration
    let currentTime = playInfo.currentTime
}

let playing: Bool = ConsertoMusicPlayer.shared.nowPlaying

NotificationCenter.default.addObserver(self, selector: #selector(self.StartPlayMusic(_:)), name: ConsertoMusicPlayer.shared.StartPlaySongNotification, object: nil)
NotificationCenter.default.addObserver(self, selector: #selector(self.EndPlayMusic(_:)), name: ConsertoMusicPlayer.shared.EndPlaySongNotification, object: nil)

ConsertoMusicPlayer.shared.switchPlayOrPause(isPlaying: true)
ConsertoMusicPlayer.shared.chagePlayTime(second: 60.0)
```


&nbsp;
&nbsp;      
### [by. Seonghun Kim](https://github.com/Seonghun23) email: <kim.seonghun23@gmail.com>
