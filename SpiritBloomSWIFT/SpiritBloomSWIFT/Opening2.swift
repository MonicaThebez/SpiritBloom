//
//  Opening2.swift
//  SpiritBloomSWIFT
//
//  Created by Livanty Efatania Dendy on 20/06/25.
//

import SpriteKit
import CoreMotion

class Opening2: SKScene {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    var hasShaken = false
    let motionManager = CMMotionManager()
    let shakeThreshold: Double = 1.5
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        MusicManager.shared.playBackgroundMusic()

        // Misal kamu ingin ambil karakter dari .sks
        if let character = childNode(withName: "character") as? SKSpriteNode {
            character.physicsBody?.isDynamic = false  // Tidak terpengaruh gravitasi
            character.physicsBody?.affectedByGravity = false
        }

        #if targetEnvironment(simulator)
        print("🖥️ Running on Simulator - shake will use motionEnded")
        #else
        startMonitoringShake()
        #endif
    }


    // MARK: - Shake for Real Device
    func startMonitoringShake() {
        if motionManager.isAccelerometerAvailable {
            print("📡 Accelerometer available. Starting monitoring...")
            motionManager.accelerometerUpdateInterval = 0.2
            motionManager.startAccelerometerUpdates(to: OperationQueue.main) { [weak self] data, error in
                guard let self = self, let acceleration = data?.acceleration else { return }

                let totalAcceleration = sqrt(acceleration.x * acceleration.x +
                                             acceleration.y * acceleration.y +
                                             acceleration.z * acceleration.z)
                print("📊 Acceleration: \(totalAcceleration)")

                if totalAcceleration > self.shakeThreshold && !self.hasShaken {
                    print("📱 Shake detected!")
                    self.hasShaken = true
                    self.motionManager.stopAccelerometerUpdates()
                    self.goToGameScene()
                }
            }
        } else {
            print("❌ Accelerometer not available.")
        }
    }

    // MARK: - Shake for Simulator
    #if targetEnvironment(simulator)
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake && !hasShaken {
            print("🖥️ Simulated shake detected!")
            hasShaken = true
            goToGameScene()
        }
    }
    #endif

    func goToGameScene() {
        if let gameScene = GameScene(fileNamed: "MyScene 2") {
            gameScene.scaleMode = .aspectFill
            let transition = SKTransition.fade(withDuration: 1.0)
            self.view?.presentScene(gameScene, transition: transition)
        }
    }

    override func willMove(from view: SKView) {
        motionManager.stopAccelerometerUpdates()
    }
}
