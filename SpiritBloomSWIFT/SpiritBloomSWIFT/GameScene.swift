//
//  GameScene.swift
//  SpiritBloomSWIFT
//
//  Created by Livanty Efatania Dendy on 17/06/25.
//
import SpriteKit
import CoreHaptics


class GameScene: SKScene, SKPhysicsContactDelegate {
    var character: SKSpriteNode!
    var cameraNode: SKCameraNode!
    var isMovingLeft = false
    var isMovingRight = false
    var isJumping = false
    var isOnGround = false
    var groundContactCount = 0
    
    var activeLeftTouches = Set<UITouch>()
    var activeRightTouches = Set<UITouch>()
    var activeJumpTouches = Set<UITouch>()
    var lastHitTime: TimeInterval = 0
    
    var hearts: [SKSpriteNode] = []
    var lives = 3
    var bubbleCount = 0
    
    var door: SKSpriteNode?
    let targetBubbles = 1
    
    var walkTextures: [SKTexture] = []
    var isWalking = false
    
    
    var hapticEngine: CHHapticEngine?
    
    
    override func didMove(to view: SKView) {
//        MusicManager.shared.playBackgroundMusic()
        createEngine()
        
        view.isMultipleTouchEnabled = true
        physicsWorld.contactDelegate = self
        
        guard let charNode = childNode(withName: "character") as? SKSpriteNode else {
            fatalError("❌ character node not found!")
        }
        character = charNode
        
        if character.physicsBody == nil {
            character.physicsBody = SKPhysicsBody(rectangleOf: character.size)
        }
        
        
        // 🧠 Konfigurasi physics karakter
        character.physicsBody?.isDynamic = true
        character.physicsBody?.allowsRotation = false
        character.physicsBody?.restitution = 0
        character.physicsBody?.friction = 1.0
        character.physicsBody?.categoryBitMask = 1
        character.physicsBody?.collisionBitMask = 2
        character.physicsBody?.contactTestBitMask = 2 | 4  // ⬅️ ground dan enemy
        
        walkTextures = [
            SKTexture(imageNamed: "character"),
            SKTexture(imageNamed: "character1")
        ]
        
        // Mengatur karakter dengan animasi jalan yang berulang
        let walkAnimation = SKAction.animate(with: walkTextures, timePerFrame: 0.2)
        
        
        character = self.childNode(withName: "character") as? SKSpriteNode
        
        
        // 🧱 Ground
        enumerateChildNodes(withName: "ground") { node, _ in
            if node.physicsBody == nil {
                node.physicsBody = SKPhysicsBody(rectangleOf: node.frame.size)
            }
            node.physicsBody?.isDynamic = false
            node.physicsBody?.affectedByGravity = false
            node.physicsBody?.categoryBitMask = 2
            node.physicsBody?.collisionBitMask = 1
            node.physicsBody?.contactTestBitMask = 1
        }
        
        // 🚧 enemy
        
        enumerateChildNodes(withName: "enemy") { node, _ in
            if let sprite = node as? SKSpriteNode {
                sprite.physicsBody = SKPhysicsBody(rectangleOf: sprite.size)
                sprite.physicsBody?.isDynamic = false
                sprite.physicsBody?.categoryBitMask = 4
                sprite.physicsBody?.collisionBitMask = 1
                sprite.physicsBody?.contactTestBitMask = 1
                
                // Tambahkan aksi bergerak otomatis
                let moveRight = SKAction.group([
                    SKAction.moveBy(x: -200, y: 0, duration: 1.5),
                    SKAction.run { sprite.xScale = abs(sprite.xScale) }  // Hadap kanan
                ])
                
                let moveLeft = SKAction.group([
                    SKAction.moveBy(x: 200, y: 0, duration: 1.5),
                    SKAction.run { sprite.xScale = -abs(sprite.xScale) }  // Hadap kiri (flip)
                ])
                
                let sequence = SKAction.sequence([moveRight, moveLeft])
                let loop = SKAction.repeatForever(sequence)
                sprite.run(loop)
                
                sprite.userData = NSMutableDictionary()
                sprite.userData?.setValue(false, forKey: "isFriendly") // default: jahat
                
            }
        }
        
        // bubble
        enumerateChildNodes(withName: "bubble") { node, _ in
            // Efek naik-turun
            let moveUp = SKAction.moveBy(x: 0, y: 30, duration: 1)
            let moveDown = SKAction.moveBy(x: 0, y: -30, duration: 1)
            let float = SKAction.sequence([moveUp, moveDown])
            node.run(SKAction.repeatForever(float))
            
            // Setup physics
            if let bubble = node as? SKSpriteNode {
                bubble.physicsBody = SKPhysicsBody(circleOfRadius: bubble.size.width / 2)
                bubble.physicsBody?.isDynamic = false
                bubble.physicsBody?.categoryBitMask = 8
                bubble.physicsBody?.contactTestBitMask = 1
                bubble.physicsBody?.collisionBitMask = 0
            }
        }
        
        // ❤️ Nyawa
        if let h1 = childNode(withName: "//nyawa1") as? SKSpriteNode,
           let h2 = childNode(withName: "//nyawa2") as? SKSpriteNode,
           let h3 = childNode(withName: "//nyawa3") as? SKSpriteNode {
            hearts = [h1, h2, h3]
        }
        // pintu
        
        if let hiddenDoor = self.childNode(withName: "door") as? SKSpriteNode {
            hiddenDoor.isHidden = true
        }
        
        
        // 📷 Kamera
        if let cam = childNode(withName: "cameraNode") as? SKCameraNode {
            self.camera = cam
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        guard let physicsBody = character.physicsBody else { return }
        
        // Hanya perbarui gerakan jika ada input
        var dx: CGFloat = 0
        
        if isMovingRight {
            dx = 150
            character.xScale = abs(character.xScale)  // Menghadap kanan
        } else if isMovingLeft {
            dx = -150
            character.xScale = -abs(character.xScale)  // Menghadap kiri
        } else {
            stopWalking()  // Hentikan animasi jalan jika tidak ada gerakan
        }
        
        // Update gerakan horizontal (velocity)
        physicsBody.velocity = CGVector(dx: dx, dy: physicsBody.velocity.dy)
        
        // Jika tidak ada gerakan horizontal, setel ke 0
        if dx == 0 {
            physicsBody.velocity = CGVector(dx: 0, dy: physicsBody.velocity.dy)
        }
        
        camera?.position.x = character.position.x
    }
    
    
    // MARK: - TOUCH HANDLING
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let nodesAtPoint = nodes(at: location)
            
            for node in nodesAtPoint {
                switch node.name {
                case "leftButton":
                    activeLeftTouches.insert(touch)
                    isMovingLeft = true
                    startWalking() // Mulai animasi jalan kiri
                case "rightButton":
                    activeRightTouches.insert(touch)
                    isMovingRight = true
                    startWalking() // Mulai animasi jalan kanan
                case "jumpButton":
                    activeJumpTouches.insert(touch)
                    if isOnGround {
                        character.physicsBody?.applyImpulse(CGVector(dx: 50, dy: 800))
                        isJumping = true
                        isOnGround = false
                        
                        
                    }
                default:
                    break
                }
            }
        }
        
        
    }
    
    
    func createEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch let error {
            print("Engine Error: \(error)")
        }
    }
    
    func playCustomHaptic() {
        guard let engine = hapticEngine else { return }
        
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 5)
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
        
        let event1 = CHHapticEvent(eventType: .hapticTransient, parameters: [sharpness, intensity], relativeTime: 0)
        let event2 = CHHapticEvent(eventType: .hapticTransient, parameters: [sharpness, intensity], relativeTime: 0.2)
        let event3 = CHHapticEvent(eventType: .hapticTransient, parameters: [sharpness, intensity], relativeTime: 0.4)
        
        do {
            let pattern = try CHHapticPattern(events: [event1, event2, event3], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("❌ Failed to play pattern: \(error.localizedDescription)")
        }
    }
    
    func triggerJumpOnEnemy() {
        // Memeriksa apakah karakter melompat di atas musuh
        enumerateChildNodes(withName: "enemy") { node, _ in
            if let enemy = node as? SKSpriteNode {
                let isFriendly = enemy.userData?.value(forKey: "isFriendly") as? Bool ?? false
                
                // Periksa posisi karakter relatif dengan musuh (melompat di atas musuh)
                let dx = abs(enemy.position.x - self.character.position.x)
                let dy = self.character.position.y - enemy.position.y  // Periksa apakah karakter di atas musuh
                
                // Jika karakter berada di atas musuh (jarak vertikal), dan belum menjadi teman, maka ubah jadi friendly
                if dy > 0 && dy < 100 && !isFriendly {
                    self.transformEnemyToFriendly(enemy) // Mengubah musuh menjadi friendly
                    print("Musuh berubah jadi baik setelah karakter melompat di atasnya!")
                }
            }
        }
    }
    
    // Fungsi untuk mengubah musuh menjadi friendly (hijau)
    func transformEnemyToFriendly(_ enemy: SKSpriteNode) {
        enemy.texture = SKTexture(imageNamed: "enemy 2")  // Ubah dengan nama sprite musuh yang sudah jadi baik (hijau)
        enemy.userData?.setValue(true, forKey: "isFriendly") // Tandai musuh sebagai friendly
        print("✨ Musuh berubah jadi baik!")
    }
    
    
    func showGameOver() {
        // Hentikan semua aksi
        self.isPaused = true
        
        let overlay = SKShapeNode(rectOf: CGSize(width: 300, height: 200), cornerRadius: 20)
        overlay.fillColor = .black
        overlay.alpha = 0.8
        overlay.zPosition = 1000
        overlay.name = "gameOverOverlay"
        overlay.position = CGPoint(x: character.position.x, y: character.position.y + 100)
        addChild(overlay)
        
        let label = SKLabelNode(text: "Game Over")
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 36
        label.position = CGPoint(x: 0, y: 40)
        label.zPosition = 1001
        overlay.addChild(label)
        
        let restartLabel = SKLabelNode(text: "Main Ulang")
        restartLabel.name = "restartButton"
        restartLabel.fontName = "AvenirNext-Bold"
        restartLabel.fontSize = 28
        restartLabel.position = CGPoint(x: 0, y: -30)
        restartLabel.zPosition = 1001
        overlay.addChild(restartLabel)
    }
    
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            
            // Cek apakah tombol restart ditekan
            if let node = atPoint(location) as? SKLabelNode, node.name == "restartButton" {
                restartGame()  // Jika tombol restart ditekan, panggil fungsi restartGame
            }
            
            if activeLeftTouches.contains(touch) {
                activeLeftTouches.remove(touch)
                isMovingLeft = !activeLeftTouches.isEmpty
            }
            if activeRightTouches.contains(touch) {
                activeRightTouches.remove(touch)
                isMovingRight = !activeRightTouches.isEmpty
            }
            if activeJumpTouches.contains(touch) {
                activeJumpTouches.remove(touch)
            }
        }
        
        // Jika karakter berhenti bergerak, hentikan animasi jalan
        if !isMovingLeft && !isMovingRight {
            stopWalking()
        }
    }
    
    func restartGame() {
        // Reset nyawa dan bubble
        lives = 3
        bubbleCount = 0
        hearts.forEach { $0.isHidden = false }  // Menampilkan kembali hearts
        
        // Reset posisi karakter dan hentikan gerakan
        character.position = CGPoint(x: 0, y: 0)  // Posisi awal karakter
        character.physicsBody?.velocity = CGVector(dx: 0, dy: 0)  // Menghentikan gerakan horizontal
        
        // Hapus overlay "Game Over"
        if let overlay = childNode(withName: "gameOverOverlay") {
            overlay.removeFromParent()
        }
        
        // Pindahkan ke scene permainan awal
        if let startScene = SKScene(fileNamed: "MyScene 2") {  // Ganti "GameScene" dengan nama scene permainan Anda
            startScene.scaleMode = .aspectFill
            let transition = SKTransition.fade(withDuration: 1.0)
            self.view?.presentScene(startScene, transition: transition)
        }
    }
    
    
    func startWalking() {
        if !isWalking {
            // Menambahkan animasi jalan saat karakter bergerak
            let walkAnimation = SKAction.animate(with: walkTextures, timePerFrame: 0.2)
            let walkRepeatForever = SKAction.repeatForever(walkAnimation)
            character.run(walkRepeatForever, withKey: "walking")
            isWalking = true
        }
    }
    
    func stopWalking() {
        if isWalking {
            // Menghentikan animasi jalan dan mengganti ke gambar diam
            character.removeAction(forKey: "walking")
            character.texture = SKTexture(imageNamed: "character1")  // Ganti ke gambar diam
            isWalking = false
            
            // Menghentikan gerakan karakter
            if let physicsBody = character.physicsBody {
                physicsBody.velocity = CGVector(dx: 0, dy: physicsBody.velocity.dy)  // Menghentikan gerakan horizontal
            }
        }
    }
    
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
    
    // MARK: - PHYSICS CONTACT
    
    func didBegin(_ contact: SKPhysicsContact) {
        let contactA = contact.bodyA
        let contactB = contact.bodyB
        
        let maskA = contactA.categoryBitMask
        let maskB = contactB.categoryBitMask
        
        // Kontak dengan tanah
        if (maskA == 1 && maskB == 2) || (maskA == 2 && maskB == 1) {
            groundContactCount += 1
            isOnGround = true
            print("✅ Contacted ground, count: \(groundContactCount)")
            
            
            
        }
        
        // Kontak dengan musuh (periksa apakah karakter melompat di atas musuh)
        if (maskA == 1 && maskB == 4) || (maskA == 4 && maskB == 1) {
            let enemyNode = (maskA == 4 ? contactA.node : contactB.node) as? SKSpriteNode
            let isFriendly = enemyNode?.userData?.value(forKey: "isFriendly") as? Bool ?? false
            
            // Hitung jarak horizontal dan vertikal
            let dx = abs(enemyNode!.position.x - self.character.position.x)
            let dy = self.character.position.y - enemyNode!.position.y // Posisi vertikal
            
            // Karakter hanya berubah musuh menjadi friendly jika berada di atas musuh
            print("Sapiman DY: \(dy)")
            //            if dy > 0 && dy < 100 && !isFriendly {
            
            if dy > 50  && !isFriendly {
                // Karakter melompat dari atas musuh, musuh berubah menjadi friendly
                self.transformEnemyToFriendly(enemyNode!)
                print("🟢 Karakter melompat di atas musuh, musuh berubah jadi baik!")
            } else if !isFriendly {
                // Jika karakter menyentuh musuh dari sisi kiri/kanan, kurangi nyawa
                let currentTime = CACurrentMediaTime()
                if currentTime - lastHitTime > 1.0 {
                    print("💥 Character hit enemy!")
                    lastHitTime = currentTime
                    
                    if lives > 0 {
                        lives -= 1
                        if let heartToRemove = hearts.popLast() {
                            heartToRemove.removeFromParent()
                            playCustomHaptic()
                            makePlayerBlink()
                        }
                        print("❤️ Remaining lives: \(lives)")
                        if lives == 0 {
                            print("☠️ Game Over")
                            playCustomHaptic()
                            makePlayerBlink()
                            showGameOver()
                            
                        }
                    }
                }
            }
        }
        
        // Bubble memiliki categoryBitMask = 8
        if (maskA == 1 && maskB == 8) || (maskA == 8 && maskB == 1) {
            print("🫧 Bubble claimed!")
            
            guard let bubble = (maskA == 8 ? contactA.node : contactB.node) as? SKSpriteNode else { return }
            
            print("Showing Bubble on top right")
            
            // 💨 Bubble hilang dari tempat awal
            let fadeOut = SKAction.fadeOut(withDuration: 0.2)
            let scaleDown = SKAction.scale(to: 0.1, duration: 0.2)
            let disappear = SKAction.group([fadeOut, scaleDown])
            
            // ✅ Munculkan kembali di pojok kanan atas kamera
            let wait = SKAction.wait(forDuration: 0.2)
            let reappear = SKAction.run {
                guard let cam = self.camera else {
                    print("⚠️ Camera not found.")
                    return
                }
                
                let collected = SKSpriteNode(texture: bubble.texture)
                collected.size = CGSize(width: bubble.size.width * 1, height: bubble.size.height * 1)
                collected.alpha = 1
                collected.zPosition = 999
                
                // Koordinat relatif terhadap kamera (misalnya pojok kanan atas)
                let spacing: CGFloat = 60
                let offsetX: CGFloat = 200 - CGFloat(self.bubbleCount) * spacing
                let offsetY: CGFloat = 120  // Jarak dari atas kamera
                
                collected.position = CGPoint(x: offsetX, y: offsetY)
                cam.addChild(collected)
                
                print("✅ Collected bubble placed at \(collected.position) in camera")
            }
            bubble.run(SKAction.sequence([reappear, disappear, SKAction.removeFromParent(), wait]))
            
            self.bubbleCount += 1
            
            if self.bubbleCount == self.targetBubbles {
                print("🔓 All bubbles collected! Showing the door.")
                
                // Munculkan node pintu (pastikan sudah ada di scene dengan name "door", tapi hidden dulu)
                if let doorNode = self.childNode(withName: "door") as? SKSpriteNode {
                    doorNode.isHidden = false
                    self.door = doorNode
                    
                    // Tambahkan physics untuk deteksi tabrakan
                    if doorNode.physicsBody == nil {
                        doorNode.physicsBody = SKPhysicsBody(rectangleOf: doorNode.size)
                        doorNode.physicsBody?.isDynamic = false
                        doorNode.physicsBody?.categoryBitMask = 16
                        doorNode.physicsBody?.contactTestBitMask = 1
                        doorNode.physicsBody?.collisionBitMask = 0
                    }
                }
            }
        }
        
        if (maskA == 1 && maskB == 16) || (maskA == 16 && maskB == 1) {
            print("🚪 Character reached the door! Transitioning...")
            
            // Ganti ke scene lain (pastikan kamu punya file scene baru bernama NextLevelScene.swift)
            if let nextScene = SKScene(fileNamed: "LastScene") {
                nextScene.scaleMode = .aspectFill
                let transition = SKTransition.fade(withDuration: 1.0)
                self.view?.presentScene(nextScene, transition: transition)
            }
        }
    }
    // Fungsi untuk membuat karakter berkedip
    func makePlayerBlink() {
        // Pastikan karakter ada
        guard let character = self.character else { return }

        // Membuat animasi kedip dengan perubahan alpha (transparansi)
        let fadeOut = SKAction.fadeAlpha(to: 0.0, duration: 0.2)  // Mengurangi transparansi ke 0 (tak terlihat)
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.2)   // Mengembalikan transparansi ke 1 (terlihat)
        let blinkSequence = SKAction.sequence([fadeOut, fadeIn])    // Gabungkan fadeOut dan fadeIn menjadi satu urutan

        // Ulangi animasi kedip sebanyak 3 kali
        let blinkRepeat = SKAction.repeat(blinkSequence, count: 3)

        // Jalankan animasi kedip pada karakter
        character.run(blinkRepeat)
    }

    
    func didEnd(_ contact: SKPhysicsContact) {
        let categoryA = contact.bodyA.categoryBitMask
        let categoryB = contact.bodyB.categoryBitMask
        
        if (categoryA == 1 && categoryB == 2) || (categoryA == 2 && categoryB == 1) {
            groundContactCount -= 1
            if groundContactCount <= 0 {
                isOnGround = false
                groundContactCount = 0
            }
        }
    }
}
