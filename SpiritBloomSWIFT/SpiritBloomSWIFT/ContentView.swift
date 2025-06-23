//
//  ContentView.swift
//  SpiritBloomSWIFT
//
//  Created by Livanty Efatania Dendy on 09/06/25.
//

import SwiftUI
import SpriteKit

struct ContentView: View {
    var openingScene: SKScene {
        guard let scene = SKScene(fileNamed: "Opening") else {
            fatalError("Couldn't load Opening.sks")
        }
        scene.scaleMode = .aspectFill
        return scene
    }

    var body: some View {
        SpriteView(scene: openingScene)
            .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
