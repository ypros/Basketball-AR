//
//  ball.swift
//  Basketball AR
//
//  Created by YURY PROSVIRNIN on 15.09.2021.
//


import UIKit
import SceneKit

final class Ball: SCNNode {
    
    var scored: Bool = false
    var points: Int = 2
    var distance: Float = 0 {
        didSet {
            self.points = self.distance > 6.0 ? 3 : 2
        }
    }
    
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
    
    func setDistance(from point:SCNVector3){

        self.distance = sqrtf(pow(self.position.x - point.x, 2) + pow(self.position.z - point.z, 2))
    
    }


}


