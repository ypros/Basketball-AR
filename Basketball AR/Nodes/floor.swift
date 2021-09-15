//
//  floor.swift
//  Basketball AR
//
//  Created by YURY PROSVIRNIN on 15.09.2021.
//

import UIKit
import SceneKit

final class Floor: SCNNode {
    
    override init() {
        super.init()
        initialisation()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialisation()
    }
    
    private func initialisation() {
        let floor = SCNPlane(width: 25, height: 25)
        floor.firstMaterial?.diffuse.contents = UIImage(named: "floorTexture")
        
        self.geometry = floor
        self.position = SCNVector3(0, -2.05, 1.5)
        self.eulerAngles.x -= .pi / 2
        // Add Physics and BitMasks for the Floor
        self.physicsBody = SCNPhysicsBody(
            type: .static,
            shape: SCNPhysicsShape(node: self))
        
        self.physicsBody?.categoryBitMask = 8 // floor
        self.physicsBody?.contactTestBitMask = 1 //ball
    }
}
