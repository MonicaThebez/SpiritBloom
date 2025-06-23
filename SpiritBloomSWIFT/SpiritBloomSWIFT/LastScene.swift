//
//  LastScene.swift
//  SpiritBloomSWIFT
//
//  Created by Monica Thebez on 23/06/25.
//

import SpriteKit
import AVFoundation

class LastScene: SKScene {
    private var endingLabel: SKLabelNode!
    private var endingPlayer: AVPlayer?

    override func didMove(to view: SKView) {
        backgroundColor = .black

        // 1. Tampilkan teks
        endingLabel = SKLabelNode(text: "Bloomy finally found its spirit.")
        endingLabel.fontName = "AvenirNext-Bold"
        endingLabel.fontSize = 32
        endingLabel.fontColor = .white
        endingLabel.position = CGPoint(x: frame.midX, y: frame.midY)
        endingLabel.alpha = 0
        addChild(endingLabel)

        let fadeIn = SKAction.fadeIn(withDuration: 2.0)
        let wait = SKAction.wait(forDuration: 5.0)
        let fadeOut = SKAction.fadeOut(withDuration: 2.0)
        endingLabel.run(SKAction.sequence([fadeIn, wait, fadeOut]))

        // 2. Mainkan musik ending
        playEndingMusic()
    }

    func playEndingMusic() {
        if let url = Bundle.main.url(forResource: "Sound ending", withExtension: "mp4") {
            endingPlayer = AVPlayer(url: url)
            endingPlayer?.play()
        } else {
            print("❌ Sound ending.mp4 tidak ditemukan!")
        }
    }

    override func willMove(from view: SKView) {
        // Stop music if leaving scene
        endingPlayer?.pause()
        endingPlayer = nil
    }
}
