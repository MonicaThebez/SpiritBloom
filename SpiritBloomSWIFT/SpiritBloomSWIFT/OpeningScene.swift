//
//  OpeningScene.swift
//  SpiritBloomSWIFT
//
//  Created by Livanty Efatania Dendy on 20/06/25.
//

import Foundation
import SpriteKit

class OpeningScene: SKScene, SKPhysicsContactDelegate {

    struct PhysicsCategory {
        static let player: UInt32 = 0x1 << 0
        static let door: UInt32 = 0x1 << 1
        static let ground: UInt32 = 0x1 << 2
    }

    var character: SKSpriteNode!
    var doorNode: SKSpriteNode?
    var isMovingLeft = false
    var isMovingRight = false
    var activeLeftTouches = Set<UITouch>()
    var activeRightTouches = Set<UITouch>()
    var hasTouchedDoor = false
    var canWalk = false

    let textureSedih = SKTexture(imageNamed: "characterSedih")
    let textureNormal = SKTexture(imageNamed: "character")

    var walkFrames: [SKTexture] = []
    var isWalkingAnimationRunning = false

    override func didMove(to view: SKView) {
        MusicManager.shared.playBackgroundMusic()
        backgroundColor = .black
        physicsWorld.contactDelegate = self

        guard let charNode = childNode(withName: "//character") as? SKSpriteNode else {
            fatalError("❌ character not found in scene!")
        }
        character = charNode
        character.physicsBody?.categoryBitMask = PhysicsCategory.player
        character.physicsBody?.contactTestBitMask = PhysicsCategory.door
        character.physicsBody?.collisionBitMask = PhysicsCategory.ground | PhysicsCategory.door

        if let door = childNode(withName: "//door") as? SKSpriteNode {
            doorNode = door
            door.alpha = 0
            door.isHidden = true
            door.physicsBody = nil
        }

        enumerateChildNodes(withName: "ground") { node, _ in
            if node.physicsBody == nil {
                node.physicsBody = SKPhysicsBody(rectangleOf: node.frame.size)
            }
            node.physicsBody?.isDynamic = false
            node.physicsBody?.affectedByGravity = false
            node.physicsBody?.categoryBitMask = PhysicsCategory.ground
            node.physicsBody?.collisionBitMask = PhysicsCategory.player
            node.physicsBody?.contactTestBitMask = PhysicsCategory.player
        }

        resizeCharacter(with: textureSedih, height: 80)

        // Tempel karakter dan pintu di atas ground
        let groundNodes = self["//ground"]
        if let groundForCharacter = groundNodes.min(by: { abs($0.position.x - character.position.x) < abs($1.position.x - character.position.x) }) {
            character.position.y = groundForCharacter.frame.maxY + character.size.height / 2
        }

        if let door = doorNode {
            if let groundForDoor = groundNodes.min(by: { abs($0.position.x - door.position.x) < abs($1.position.x - door.position.x) }) {
                door.position.y = groundForDoor.frame.maxY + door.size.height / 2
            }
        }

        childNode(withName: "//leftButton")?.isHidden = true
        childNode(withName: "//rightButton")?.isHidden = true

        setupWalkAnimation()
        showOpeningText()
    }

    func setupWalkAnimation() {
        let frame1 = SKTexture(imageNamed: "character")
        let frame2 = SKTexture(imageNamed: "character1")
        walkFrames = [frame1, frame2]
        SKTexture.preload(walkFrames, withCompletionHandler: {})
    }

    func resizeCharacter(with texture: SKTexture, height: CGFloat) {
        character.texture = texture
        let originalSize = texture.size()
        let aspectRatio = originalSize.width / originalSize.height
        character.size = CGSize(width: height * aspectRatio, height: height)
    }

    func transitionCharacterTexture(to newTexture: SKTexture, height: CGFloat = 80, duration: TimeInterval = 0.3) {
        let fadeOut = SKAction.fadeOut(withDuration: duration / 2)
        let changeTexture = SKAction.run {
            self.resizeCharacter(with: newTexture, height: height)
        }
        let fadeIn = SKAction.fadeIn(withDuration: duration / 2)
        let sequence = SKAction.sequence([fadeOut, changeTexture, fadeIn])
        character.run(sequence)
    }

    func startWalkingAnimation() {
        guard !isWalkingAnimationRunning else { return }
        isWalkingAnimationRunning = true
        let walkAction = SKAction.animate(with: walkFrames, timePerFrame: 0.15, resize: false, restore: true)
        let repeatWalk = SKAction.repeatForever(walkAction)
        character.run(repeatWalk, withKey: "walk")
    }

    func stopWalkingAnimation() {
        character.removeAction(forKey: "walk")
        isWalkingAnimationRunning = false
        resizeCharacter(with: textureNormal, height: 80)
    }

    func showOpeningText() {
        let openingText = SKLabelNode(text: "I lost my spark")
        openingText.fontName = "AvenirNext-Bold"
        openingText.fontSize = 32
        openingText.fontColor = .white
        openingText.alpha = 0
        openingText.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(openingText)

        openingText.run(SKAction.sequence([
            .fadeIn(withDuration: 1.0),
            .wait(forDuration: 1.0),
            .fadeOut(withDuration: 1.0)
        ])) {
            self.showSecondText()
        }
    }

    func showSecondText() {
        let secondText = SKLabelNode(text: "Only you can help me.")
        secondText.fontName = "AvenirNext-Bold"
        secondText.fontSize = 28
        secondText.fontColor = .white
        secondText.alpha = 0
        secondText.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(secondText)

        secondText.run(SKAction.sequence([
            .fadeIn(withDuration: 1.0),
            .wait(forDuration: 1.0),
            .fadeOut(withDuration: 1.0)
        ])) {
            self.revealDoor()
            self.canWalk = true
            self.transitionCharacterTexture(to: self.textureNormal)

            self.childNode(withName: "//leftButton")?.isHidden = false
            self.childNode(withName: "//rightButton")?.isHidden = false
        }
    }

    func revealDoor() {
        guard let door = doorNode else { return }
        door.isHidden = false
        door.alpha = 0

        let body = SKPhysicsBody(rectangleOf: door.size)
        body.isDynamic = false
        body.categoryBitMask = PhysicsCategory.door
        body.contactTestBitMask = PhysicsCategory.player
        body.collisionBitMask = 0
        door.physicsBody = body

        door.run(.fadeIn(withDuration: 1.0))
    }

    override func update(_ currentTime: TimeInterval) {
        guard let body = character.physicsBody else { return }
        let dx: CGFloat = isMovingRight ? 60 : isMovingLeft ? -60 : 0
        body.velocity = CGVector(dx: dx, dy: 0)

        if dx != 0 {
            startWalkingAnimation()
        } else {
            stopWalkingAnimation()
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard canWalk else { return }

        for touch in touches {
            let location = touch.location(in: self)
            let nodesAtPoint = nodes(at: location)

            for node in nodesAtPoint {
                switch node.name {
                case "leftButton":
                    activeLeftTouches.insert(touch)
                    isMovingLeft = true
                case "rightButton":
                    activeRightTouches.insert(touch)
                    isMovingRight = true
                default:
                    break
                }
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if activeLeftTouches.contains(touch) {
                activeLeftTouches.remove(touch)
                isMovingLeft = !activeLeftTouches.isEmpty
            }
            if activeRightTouches.contains(touch) {
                activeRightTouches.remove(touch)
                isMovingRight = !activeRightTouches.isEmpty
            }
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }

    func didBegin(_ contact: SKPhysicsContact) {
        var playerBody: SKPhysicsBody
        var doorBody: SKPhysicsBody

        if contact.bodyA.categoryBitMask == PhysicsCategory.player {
            playerBody = contact.bodyA
            doorBody = contact.bodyB
        } else {
            playerBody = contact.bodyB
            doorBody = contact.bodyA
        }

        if doorBody.categoryBitMask == PhysicsCategory.door && !hasTouchedDoor {
            hasTouchedDoor = true
            character.physicsBody?.velocity = .zero
            character.removeAllActions()

            run(.wait(forDuration: 0.3)) {
                self.goToOpening2()
            }
        }
    }

    func goToOpening2() {
        let transition = SKTransition.fade(withDuration: 1.0)
        if let opening2 = SKScene(fileNamed: "Opening2") {
            opening2.scaleMode = .aspectFill
            self.view?.presentScene(opening2, transition: transition)
        } else {
            print("❌ Opening2.sks not found!")
        }
    }
}
