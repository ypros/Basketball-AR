//
//  counter.swift
//  Basketball AR
//
//  Created by YURY PROSVIRNIN on 15.09.2021.
//

import UIKit
import SceneKit

final class Counter: SCNNode {
    
    override init() {
        super.init()
        initialisation()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialisation()
    }
    
    private func initialisation() {
        let plane = SCNPlane(width: 0.2, height: 0.2)
        
        self.geometry = plane
        self.opacity = 0
        
        // Find the Coordinates of the Rim
        let scene = SCNScene(named: "Basket.scn", inDirectory: "art.scnassets")!
        guard let ring = scene.rootNode.childNode(withName: "ring", recursively: true) else { return }
        // Locate the Score Point in the middle of the Rim
        self.position = ring.position
        self.position.y -= 0.2
        self.eulerAngles.x = -.pi / 2
        
        // Add Physics and BitMasks for the ScorePoint
        self.physicsBody = SCNPhysicsBody(
            type: .static,
            shape: SCNPhysicsShape(node: self,
                                   options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron]))
        
        self.physicsBody?.categoryBitMask = 4 //counter
        self.physicsBody?.contactTestBitMask = 1 //ball
    }
    
}
