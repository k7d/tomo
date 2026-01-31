import AVFoundation

class SoundPlayer {
    static let shared = SoundPlayer()
    private var player: AVAudioPlayer?

    func play(_ sound: Sound) {
        guard sound != .none else { return }
        guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "mp3", subdirectory: "Sounds") else { return }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.play()
        } catch {
            print("Sound playback error: \(error)")
        }
    }
}
