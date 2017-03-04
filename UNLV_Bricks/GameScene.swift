//
//  GameScene.swift
//  UNLV_Bricks
//
//  Created by Carlos Lemus on 3/2/17.
//  Copyright © 2017 Carlos Lemus. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate{
    
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    
    private var isFingerOnPaddle = false
    
    private var lives = 3
    //Create category bit maskes (identify the category a body belongs to)
    let BallCategory   : UInt32 = 0x1 << 0
    let BottomCategory : UInt32 = 0x1 << 1
    let BlockCategory  : UInt32 = 0x1 << 2
    let PaddleCategory : UInt32 = 0x1 << 3
    let BorderCategory : UInt32 = 0x1 << 4
    
    let brickHitSound = SKAction.playSoundFileNamed("break", waitForCompletion: false)
    let paddleHitSound  = SKAction.playSoundFileNamed("paddle_hit", waitForCompletion: false)
    let bottomHitSound  = SKAction.playSoundFileNamed("lose_live", waitForCompletion: false)
    
    var backgroundMusic: SKAudioNode!
    override func didMove(to view: SKView) {
       
        let borderBody = SKPhysicsBody(edgeLoopFrom: self.frame) //create an edge-based body, does not have mass or volume and is unnafected by forces
        
        borderBody.friction = 0 //The ball will not be slowed down when colliding with the border barrier
        
        self.physicsBody = borderBody //physics for the frame
        
        
        //Define blocks
        let numberOfBlocks = 71
       // let blockWidth = SKSpriteNode(imageNamed: "block").size.width
        let blockWidth = CGFloat(100)
        
        //calclulate offset between blocks
        var xOffset = CGFloat(25)
        var yOffset = CGFloat(1158.98)
        var counter = 0
        //create blocks
        for i in 1..<numberOfBlocks {
            let block = SKSpriteNode(imageNamed: "block.png")
            block.position = CGPoint(x: xOffset + CGFloat(CGFloat(counter) + 0.5) * blockWidth,
                                     y: yOffset)
            counter += 1
            block.physicsBody = SKPhysicsBody(rectangleOf: block.frame.size)
            block.physicsBody!.allowsRotation = false
            block.physicsBody!.friction = 0.0
            block.physicsBody!.affectedByGravity = false
            block.physicsBody!.isDynamic = false
            block.name = "block"
            block.physicsBody!.categoryBitMask = BlockCategory
            block.zPosition = 2
            block.size.width = 100
            block.size.height = 20
            addChild(block)
            
            
            if(i % 7 == 0){
                yOffset -= block.size.height //create a new row
                counter = 0
            }
        }
        
        
        
        //Removes all gravity from the scene
        physicsWorld.gravity = CGVector(dx: 0.0, dy: 0.0)
        physicsWorld.contactDelegate = self //allows collision notifications
        
        //Gets the ball from the scene's child nodes 
        let ball = childNode(withName: "ball") as! SKSpriteNode
        let paddle = childNode(withName: "paddle") as! SKSpriteNode
        
        ball.physicsBody!.applyImpulse(CGVector(dx: 35.0, dy: -40.0))
        
        let bottomRect = CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.size.width, height: 1)
        let bottom = SKNode()
        bottom.physicsBody = SKPhysicsBody(edgeLoopFrom: bottomRect)
        addChild(bottom)
        
       // let paddleRect = CGRect(x: paddle.position.x, y: paddle.position.y, width:  paddle.size.width, height: paddle.size.height)
        
        //paddle.physicsBody = SKPhysicsBody(edgeLoopFrom: paddleRect)
        
        bottom.physicsBody!.categoryBitMask = BottomCategory
        ball.physicsBody!.categoryBitMask = BallCategory
        paddle.physicsBody!.categoryBitMask = PaddleCategory
        borderBody.categoryBitMask = BorderCategory
        
        ball.physicsBody!.contactTestBitMask = BottomCategory | BlockCategory | PaddleCategory
        
        //Create a particle trail for the ball
        let trailNode = SKNode()
        trailNode.zPosition = 1
        addChild(trailNode)
        let trail = SKEmitterNode(fileNamed: "BallTrail")!
        trail.targetNode = trailNode
        ball.addChild(trail)
        
        
        if let musicURL = Bundle.main.url(forResource: "game_music", withExtension: "mp3") {
            backgroundMusic = SKAudioNode(url: musicURL)
            addChild(backgroundMusic)
        }
    }
    
    
    
    func didBegin(_ contact: SKPhysicsContact) {
        //hold the physics bodies involved in the collision
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        
        //Check the two boies have collided
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        //Check if the Ball has made contact with the bottom of the screen
        if firstBody.categoryBitMask == BallCategory && secondBody.categoryBitMask == BottomCategory {
            print("Hit bottom. ")
            let display = childNode(withName: "lbl_winlose") as! SKLabelNode
            if(lives > 0){
                display.text = String(lives)
                lives -= 1
            }else{
                display.text = "You Lose"
            }
            run(bottomHitSound)
        }
        //Check if the Ball has made contact with the blcok
        if firstBody.categoryBitMask == BallCategory && secondBody.categoryBitMask == BlockCategory {
            print("Hit block.")
            breakBlock(node: secondBody.node!)
            run(brickHitSound)
        }
        //Check if the Ball has made contact with the blcok
        if firstBody.categoryBitMask == BallCategory && secondBody.categoryBitMask == PaddleCategory {
            print("Hit paddle.")
            run(paddleHitSound)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        /*if let label = self.label {
            label.run(SKAction.init(named: "Pulse")!, withKey: "fadeInOut")
        }
        
        for t in touches { self.touchDown(atPoint: t.location(in: self)) }*/
        
        let touch = touches.first
        let touchLocation = touch!.location(in: self) //Get location of touch on scene
        
        //check if touch was on paddle
        if let body = physicsWorld.body(at: touchLocation){
            if body.node!.name == "paddle"{
                print("Began touch on paddle")
                isFingerOnPaddle = true;
                
                //if paddle is touched give the ball just a little movement in case the ball is stuck going side to side or up and down
                let ball = childNode(withName: "ball") as! SKSpriteNode
                
                //Adjust ball if stuck
                if(ball.position.y <= 20 ){
                    
                    ball.physicsBody!.applyImpulse(CGVector(dx: 1, dy: 40))
                }
                if(ball.position.y >= 1180 ){
                    
                    ball.physicsBody!.applyImpulse(CGVector(dx: 1, dy: -40))
                }
                if(ball.position.x >= 720){
                    
                    ball.physicsBody!.applyImpulse(CGVector(dx: -40, dy: 1))
                }
                if(ball.position.x <= 20){
                    
                    ball.physicsBody!.applyImpulse(CGVector(dx: 40, dy: 1))
                }
            }
        }
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        //for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
        
        //NOTE: change the anchor point for the scene to 0,0 for the paddleX Max and Min function
        
        //update position of paddle on finger
        let touch = touches.first
        let touchLocation = touch!.location(in: self)
        let previousLocation = touch!.previousLocation(in: self)
        
        //check wether player is touching paddle
        if isFingerOnPaddle {
            
            //get the paddle SKSpriteNode
            let paddle = childNode(withName: "paddle") as! SKSpriteNode
            
            //take the current position and add the difference between the new and the previous touch locations
            var paddleX = paddle.position.x + (touchLocation.x - previousLocation.x)
            
            //before moving the paddle, make sure it does not go off screen to the left or right
            paddleX = max(paddleX, paddle.size.width/2)
            paddleX = min(paddleX, size.width - paddle.size.width/2)
            
            //Set the paddle position
            paddle.position = CGPoint(x: paddleX, y: paddle.position.y)
            
        }
        if(touchLocation.x <= 10 && touchLocation.y <= 10){
            let display = childNode(withName: "lbl_winlose") as! SKLabelNode
            
            display.text = "You Win"
            lives = 3
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
       // for t in touches { self.touchUp(atPoint: t.location(in: self)) }
        isFingerOnPaddle = false
    }
    
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        if(isGameWon() ){
            let display = childNode(withName: "lbl_winlose") as! SKLabelNode
            
            display.text = "You Win, Welcome to UNLV"
        }
    }
    
    func isGameWon()  -> Bool{
        //Check all the bricks in the game and return true if it is zero
        var numberOfBricks = 0
        self.enumerateChildNodes(withName: "block") {
            node, stop in
            numberOfBricks = numberOfBricks + 1
        }
        return numberOfBricks == 0
    }
    
    func breakBlock(node: SKNode){
        //Create an emiter node from the file
        let particles = SKEmitterNode(fileNamed: "BrokenPlatform")!
        particles.position = node.position
        particles.zPosition = 3
        addChild(particles) //add particles to the position of the broken blcok
        particles.run(SKAction.sequence([SKAction.wait(forDuration: 1.0), SKAction.removeFromParent()]))
        node.removeFromParent()//remove block
        
    }
}
