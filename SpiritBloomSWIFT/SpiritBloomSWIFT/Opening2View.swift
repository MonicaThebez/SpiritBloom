//
//  Oening2View.swift
//  SpiritBloomSWIFT
//
//  Created by Jennifer Evelyn on 21/06/25.
//

import Foundation
import SwiftUI
import SpriteKit

struct Opening2View: View {
    var body: some View {
        SpriteView(scene: loadScene())
            .ignoresSafeArea()
    }

    func loadScene() -> SKScene {
        if let scene = SKScene(fileNamed: "Opening2") as? Opening2 {
            scene.scaleMode = .aspectFill
            return scene
        } else {
            // fallback ke scene kosong jika gagal load
            let fallback = SKScene(size: UIScreen.main.bounds.size)
            fallback.backgroundColor = .black
            return fallback
        }
    }
}
