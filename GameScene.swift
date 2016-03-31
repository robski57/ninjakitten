//
//  GameScene.swift
//  Ninja3
//
//  Created by Robert Williams on 3/21/16.
//  Copyright (c) 2016 Robert Williams. All rights reserved.
//

import SpriteKit


//swift operation overloading
// Shooting projectiles

func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func * (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func / (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

#if !(arch(x86_64) || arch(arm64))
    func sqrt(a: CGFloat) -> CGFloat {
        return CGFloat(sqrtf(Float(a)))
    }
#endif

extension CGPoint {
    func length() -> CGFloat {
        return sqrt(x*x + y*y)
    }
    
    func normalized() -> CGPoint {
        return self / length()
    }
    
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    struct PhysicsCategory {
        static let None      : UInt32 = 0
        static let All       : UInt32 = UInt32.max
        static let ninjaCat   : UInt32 = 0b1       // 1
        static let Projectile: UInt32 = 0b10      // 2
    }
    //var backgroundMusic: SKAudioNode!
      //let background = SKSpriteNode(imageNamed: "city")
      //let projectile = SKSpriteNode(imageNamed: "projectile")
    
      let player = SKSpriteNode(imageNamed: "ninja")
      let ninjaCat = SKSpriteNode(imageNamed: "ninjaCat")
      var ninjaCatDestroyed = 0
    
    override func didMoveToView(view: SKView) {
        
        
    //  let backgroundMusic = SKAudioNode(fileNamed: "Cyborg Ninja")
    //  backgroundMusic.autoplayLooped = true
    //  addChild(backgroundMusic)
        
        //let player = SKSpriteNode(imageNamed: "ninja")
        backgroundColor = SKColor.blueColor()
        //let background = SKSpriteNode(imageNamed: "city")
        //background.size = self.frame.size;
        //background.position = CGPoint(x: size.width/2, y: size.height/2)
      //ninjaCat.position = CGPoint(x: size.width * 0.2, y: size.height * 0.8)
      //addChild(ninjaCat)
        player.position = CGPoint(x: size.width * 0.1, y: size.height * 0.5)
        addChild(player)
        physicsWorld.gravity = CGVectorMake(0, 0)
        physicsWorld.contactDelegate = self
       // background.size = CGSize(width: 2048, height: 1536)
        //addChild(background)
        //method to create monsters that continuously spawn
        runAction(SKAction.repeatActionForever(
            SKAction.sequence([
                SKAction.runBlock(addninjaCat),
                SKAction.waitForDuration(4.0)
                ])
            ))
        

    }
    

    
        
func random() -> CGFloat {
    return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
}

func random(min min: CGFloat, max: CGFloat) -> CGFloat {
    return random() * (max - min) + min
}

func addninjaCat() {
    
    // Create sprite
    
    let ninjaCat = SKSpriteNode(imageNamed: "ninjaCat")
    
    // Determine where to spawn the monster along the Y axis
    let actualY = random(min: ninjaCat.size.height/3, max: size.height - ninjaCat.size.height/3)
    
    // Position the monster slightly off-screen along the right edge,
    // and along a random position along the Y axis as calculated above
    ninjaCat.position = CGPoint(x: size.width + ninjaCat.size.width/2, y: actualY)
    
    // Add the monster to the scene
    addChild(ninjaCat)
    ninjaCat.physicsBody = SKPhysicsBody(rectangleOfSize: ninjaCat.size) // 1
    ninjaCat.physicsBody?.dynamic = true // 2
    ninjaCat.physicsBody?.categoryBitMask = PhysicsCategory.ninjaCat // 3
    ninjaCat.physicsBody?.contactTestBitMask = PhysicsCategory.Projectile // 4
    ninjaCat.physicsBody?.collisionBitMask = PhysicsCategory.None // 5
    
    // Determine speed of the monster
    let actualDuration = random(min: CGFloat(10), max: CGFloat(10))
    
    // Create the actions
    let actionMove = SKAction.moveTo(CGPoint(x: -ninjaCat.size.width/2, y: actualY), duration: NSTimeInterval(actualDuration))
    let actionMoveDone = SKAction.removeFromParent()
   // Monster.runAction(SKAction.sequence([actionMove, actionMoveDone]))
    let loseAction = SKAction.runBlock() {
        let reveal = SKTransition.flipHorizontalWithDuration(0.5)
        let gameOverScene = GameOverScene(size: self.size, won: false)
        self.view?.presentScene(gameOverScene, transition: reveal)
    }
    ninjaCat.runAction(SKAction.sequence([actionMove, loseAction, actionMoveDone]))
    
}
    
override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
   // runAction(SKAction.playSoundFileNamed("pew-pew-lei.caf", waitForCompletion: false))
    
    // 1 - Choose one of the touches to work with
    guard let touch = touches.first else {
        return
    }
    let touchLocation = touch.locationInNode(self)
    
    // 2 - Set up initial location of projectile
    let projectile = SKSpriteNode(imageNamed: "projectile")
    projectile.position = player.position
    projectile.physicsBody = SKPhysicsBody(circleOfRadius: projectile.size.width/2)
    projectile.physicsBody?.dynamic = true
    projectile.physicsBody?.categoryBitMask = PhysicsCategory.Projectile
    projectile.physicsBody?.contactTestBitMask = PhysicsCategory.ninjaCat
    projectile.physicsBody?.collisionBitMask = PhysicsCategory.None
    projectile.physicsBody?.usesPreciseCollisionDetection = true
    
    // 3 - Determine offset of location to projectile
    let offset = touchLocation - projectile.position
    
    // 4 - Bail out if you are shooting down or backwards
    if (offset.x < 0) { return }
    
    // 5 - OK to add now - you've double checked position
    addChild(projectile)
    
    // 6 - Get the direction of where to shoot
    let direction = offset.normalized()
    
    // 7 - Make it shoot far enough to be guaranteed off screen
    let shootAmount = direction * 1000
    
    // 8 - Add the shoot amount to the current position
    let realDest = shootAmount + projectile.position
    
    // 9 - Create the actions
    let actionMove = SKAction.moveTo(realDest, duration: 2.0)
    let actionMoveDone = SKAction.removeFromParent()
    projectile.runAction(SKAction.sequence([actionMove, actionMoveDone]))
    
}
    func projectileDidCollideWithninjaCat(projectile:SKSpriteNode, ninjaCat:SKSpriteNode) {
        print("Hit")
        projectile.removeFromParent()
        ninjaCat.removeFromParent()
        ninjaCatDestroyed++
        if (ninjaCatDestroyed > 30) {
            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
            let gameOverScene = GameOverScene(size: self.size, won: true)
            self.view?.presentScene(gameOverScene, transition: reveal)
        }
    }
    func didBeginContact(contact: SKPhysicsContact) {
        
        // 1
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        // 2
        if ((firstBody.categoryBitMask & PhysicsCategory.ninjaCat != 0) &&
            (secondBody.categoryBitMask & PhysicsCategory.Projectile != 0)) {
                projectileDidCollideWithninjaCat(firstBody.node as! SKSpriteNode, ninjaCat: secondBody.node as! SKSpriteNode)
        }
        //Working on adding a score count to game.
            let score = SKNode()
            let increaseScoreAction = SKAction.runBlock {score++}
            let waitAction = SKAction.waitForDuration(1)
            let groupAction = SKAction.group([increaseScoreAction])
            let  repeatAction = SKAction.repeatActionForever(groupAction)
            runAction(repeatAction)
        }
    }


    
    

    

