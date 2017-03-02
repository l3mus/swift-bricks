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
    
    //Create category bit maskes (identify the category a body belongs to)
    let BallCategory   : UInt32 = 0x1 << 0
    let BottomCategory : UInt32 = 0x1 << 1
    let BlockCategory  : UInt32 = 0x1 << 2
    let PaddleCategory : UInt32 = 0x1 << 3
    let BorderCategory : UInt32 = 0x1 << 4
    
    override func didMove(to view: SKView) {
        
       /* // Get label node from scene and store it for use later
        self.label = self.childNode(withName: "//helloLabel") as? SKLabelNode
        if let label = self.label {
            label.alpha = 0.0
            label.run(SKAction.fadeIn(withDuration: 2.0))
        }
        
        // Create shape node to use during mouse interaction
        let w = (self.size.width + self.size.height) * 0.05
        self.spinnyNode = SKShapeNode.init(rectOf: CGSize.init(width: w, height: w), cornerRadius: w * 0.3)
        
        if let spinnyNode = self.spinnyNode {
            spinnyNode.lineWidth = 2.5
            
            spinnyNode.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat(M_PI), duration: 1)))
            spinnyNode.run(SKAction.sequence([SKAction.wait(forDuration: 0.5),
                                              SKAction.fadeOut(withDuration: 0.5),
                                              SKAction.removeFromParent()]))
        }
        */
        
       
        let borderBody = SKPhysicsBody(edgeLoopFrom: self.frame) //create an edge-based body, does not have mass or volume and is unnafected by forces
        
        borderBody.friction = 0 //The ball will not be slowed down when colliding with the border barrier
        
        self.physicsBody = borderBody //physics for the frame
        
        
        //Define blocks
        let numberOfBlocks = 8
        let blockWidth = SKSpriteNode(imageNamed: "block").size.width
        let totalBlcksWidth = blockWidth * CGFloat(numberOfBlocks)
        
        //calclulate offset between blocks
        let xOffset = (frame.width - totalBlcksWidth)/2
        
        //create blocks
        for i in 0..<numberOfBlocks {
            let block = SKSpriteNode(imageNamed: "block.png")
            block.position = CGPoint(x: xOffset + CGFloat(CGFloat(i) + 0.5) * blockWidth,
                                     y: frame.height * 0.8)
            
            block.physicsBody = SKPhysicsBody(rectangleOf: block.frame.size)
            block.physicsBody!.allowsRotation = false
            block.physicsBody!.friction = 0.0
            block.physicsBody!.affectedByGravity = false
            block.physicsBody!.isDynamic = false
            block.name = "block"
            block.physicsBody!.categoryBitMask = BlockCategory
            block.zPosition = 2
            addChild(block)
        }
        
        
        
        //Removes all gravity from the scene
        physicsWorld.gravity = CGVector(dx: 0.0, dy: 0.0)
        physicsWorld.contactDelegate = self //allows collision notifications
        
        //Gets the ball from the scene's child nodes 
        let ball = childNode(withName: "ball") as! SKSpriteNode
        let paddle = childNode(withName: "paddle") as! SKSpriteNode
        
        ball.physicsBody!.applyImpulse(CGVector(dx: 30.0, dy: -30.0))
        
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
        
        ball.physicsBody!.contactTestBitMask = BottomCategory
        paddle.physicsBody!.contactTestBitMask = BottomCategory
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
            print("Hit bottom. First contact has been made.")
        }
        //Check if the Ball has made contact with the paddle
        if firstBody.categoryBitMask == BallCategory && secondBody.categoryBitMask == PaddleCategory {
            print("Hit paddle. First contact has been made.")
        }
        //Check if the Ball has made contact with the paddle
        if secondBody.categoryBitMask == BallCategory && firstBody.categoryBitMask == PaddleCategory {
            print("Hit paddle. First contact has been made.")
        }
    }
    func touchDown(atPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.green
            self.addChild(n)
        }
    }
    
    func touchMoved(toPoint pos : CGPoint) {
        /*if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.blue
            self.addChild(n)
        }*/
        
    }
    
    func touchUp(atPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.red
            self.addChild(n)
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
            }
        }
        
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        //for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
        
        //NOTE: change the anchor point for the scene to 0,0 for the paddleX Max and Min function
        
        //check wether player is touching paddle
        if isFingerOnPaddle {
            //update position of paddle on finger
            let touch = touches.first
            let touchLocation = touch!.location(in: self)
            let previousLocation = touch!.previousLocation(in: self)
            
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
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
       // for t in touches { self.touchUp(atPoint: t.location(in: self)) }
        isFingerOnPaddle = false
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
