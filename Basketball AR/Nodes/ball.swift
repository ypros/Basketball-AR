//
//  ball.swift
//  Basketball AR
//
//  Created by YURY PROSVIRNIN on 15.09.2021.
//


import UIKit
import SceneKit

final class Ball: SCNNode {
    
    override init() {
        super.init()
        initialisation()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialisation()
    }
    
    private func initialisation() {
        // Ball Geometry
        let ball = SCNSphere(radius: 0.125)
        ball.firstMaterial?.diffuse.contents = UIImage(named: "ballTexture")
        
        self.geometry = ball
        self.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: self))
        
        self.physicsBody?.categoryBitMask = 1 //ball
        self.physicsBody?.collisionBitMask = 1 + 2 + 8//ball + board + floor
        self.physicsBody?.contactTestBitMask = 4 + 8//counter + floor

    }

    
    
}
