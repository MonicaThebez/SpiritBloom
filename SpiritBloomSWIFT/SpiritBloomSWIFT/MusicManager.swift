//
//  MusicManager.swift
//  SpiritBloomSWIFT
//
//  Created by Jennifer Evelyn on 23/06/25.
//

import AVFoundation

class MusicManager {
    static let shared = MusicManager()

    private var player: AVPlayer?

    private init() {}

    func playBackgroundMusic() {
        guard player == nil else { return } // Jangan putar ulang kalau sudah main

        if let url = Bundle.main.url(forResource: "backsound", withExtension: "mp4") {
            player = AVPlayer(url: url)
            player?.actionAtItemEnd = .none
            player?.play()

            // Looping saat selesai
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: player?.currentItem,
                queue: .main
            ) { [weak self] _ in
                self?.player?.seek(to: .zero)
                self?.player?.play()
            }
        } else {
            print("❌ File backsound.mp4 tidak ditemukan di bundle!")
        }
    }

    func stop() {
        player?.pause()
        player = nil
    }
}
