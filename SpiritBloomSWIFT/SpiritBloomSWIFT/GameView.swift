//
//  GameView.swift
//  SpiritBloomSWIFT
//
//  Created by Livanty Efatania Dendy on 18/06/25.
//

import SwiftUI
import SpriteKit

struct GameView: UIViewRepresentable {
    func makeUIView(context: Context) -> SKView {
        let skView = SKView()
        skView.isMultipleTouchEnabled = true  // ✅ INI YANG KITA BUTUH

        if let scene = SKScene(fileNamed: "OpeningScene") as? GameScene {
            scene.scaleMode = .aspectFill
            skView.presentScene(scene)
        }

        return skView
    }

    func updateUIView(_ uiView: SKView, context: Context) {}
}

