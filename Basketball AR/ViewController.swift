//
//  ViewController.swift
//  Basketball AR
//
//  Created by YURY PROSVIRNIN on 18.06.2021.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    var score: Int = 0
    
    let configuration = ARWorldTrackingConfiguration()
    var isBasketSet = false {
        didSet {
            //Setting up configuration detection off
            configuration.planeDetection = []

            // Run the view's session
            sceneView.session.run(configuration, options: .removeExistingAnchors)
        }
    }
    var swipeStartPoint = CGPoint()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        //sceneView.showsStatistics = true
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        

        //Setting up configuration to auto detect vertical and horizontal planes
        configuration.planeDetection = [.horizontal, .vertical]

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    private func getBasketNode() -> SCNNode {
        let scene = SCNScene(named: "Basket.scn", inDirectory: "art.scnassets")!
        
        let basketNode = scene.rootNode.clone()
        basketNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: basketNode, options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron]))
        basketNode.eulerAngles.x -= .pi/2
        
        return basketNode
    }
    
    private func getBallNode(_ power: Float) -> SCNNode {
        let ball = SCNSphere(radius: 0.1)
        ball.firstMaterial?.diffuse.contents = UIImage(named: "ballTexture")
        
        let ballNode = SCNNode(geometry: ball)
        
        if let frame = sceneView.session.currentFrame {
            ballNode.simdTransform = frame.camera.transform
        }
        
        let matrix = SCNMatrix4(ballNode.simdTransform)
        let x = (matrix.m31) * power
        let y = (matrix.m32) * power
        let z = matrix.m33 * power
        let forceVector = SCNVector3(-x, -y, -z)
        
        ballNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: ballNode))
        ballNode.physicsBody?.applyForce(forceVector, asImpulse: true)
        
        return ballNode
    }
    
    private func getForceVector() -> SCNVector3 {
        
        guard let frame = sceneView.session.currentFrame  else {
            return SCNVector3()
        }
        
        let matrix = SCNMatrix4(frame.camera.transform)
        
        let ortoX = (matrix.m23 * matrix.m12 - matrix.m13 + matrix.m22) / (matrix.m11 * matrix.m22 - matrix.m21 * matrix.m12 )
        
        let ortoY = (matrix.m23 * matrix.m11 - matrix.m13 + matrix.m21) / (matrix.m12 * matrix.m21 - matrix.m22 * matrix.m11 )
        
        let ortoZ: Float = 1
        
        return SCNVector3(ortoX, ortoY, ortoZ)
        
    }
    
    
    private func getPlaneNode(for anchor: ARPlaneAnchor) -> SCNNode {
        let extent = anchor.extent
        let plane = SCNPlane(width: CGFloat(extent.x), height: CGFloat(extent.z))
        plane.firstMaterial?.diffuse.contents = UIColor.green
        
        let planeNode = SCNNode(geometry: plane)
        planeNode.opacity = 0.3
        planeNode.eulerAngles.x -= .pi/2
        
        return planeNode
    }
    
    private func updatePlaneNode(_ node: SCNNode, for anchor: ARPlaneAnchor) {
        guard let planeNode = node.childNodes.first, let plane = planeNode.geometry as? SCNPlane else {
            return
        }
        
        planeNode.simdPosition = anchor.center
        plane.width = CGFloat(anchor.extent.x)
        plane.height = CGFloat(anchor.extent.z)
    }

    // MARK: - ARSCNViewDelegate
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor, planeAnchor.alignment == .vertical else {
            return
        }
        
        node.addChildNode(getPlaneNode(for: planeAnchor))
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, willUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor, planeAnchor.alignment == .vertical else {
            return
        }
        
        updatePlaneNode(node, for: planeAnchor)
    }
    
    // MARK: - Actions
    @IBAction func userTap(_ sender: UITapGestureRecognizer) {
        
        if isBasketSet {
            	
            //sceneView.scene.rootNode.addChildNode(getBallNode())
            
        }
        else {
            let location = sender.location(in: sceneView)
            guard let query = sceneView.raycastQuery(from: location, allowing: .existingPlaneGeometry, alignment: .vertical) else {
                return
            }
            
            let results = sceneView.session.raycast(query)
            guard let hitResult = results.first else {
               print("No surface found")
               return
            }
            
            
            guard let anchor = hitResult.anchor as? ARPlaneAnchor, anchor.alignment == .vertical else {
                return
            }
            
            let basketNode = getBasketNode()
            basketNode.simdTransform = hitResult.worldTransform
            basketNode.eulerAngles.x -= .pi/2
            
            sceneView.scene.rootNode.addChildNode(basketNode)
            
            isBasketSet = true
        }
    }

                    
    @IBAction func userPan(_ sender: UIPanGestureRecognizer) {

        if sender.state == .began {
            swipeStartPoint = sender.location(in: sceneView)
        }
        if sender.state == .ended {
            let swipeEndPoint = sender.location(in: sceneView)
            
            
          //  if isBasketSet {
            
            let swipePower = Float(swipeStartPoint.y - swipeEndPoint.y) / Float(sceneView.frame.height)
            let power = 25 * swipePower
            
            sceneView.scene.rootNode.addChildNode(getBallNode(power))
            
            addScore()
                //print("start", swipeStartPoint)
               // print("end", swipeEndPoint)
                
         //   }
        }
    }
    
    func addScore() {
        guard let scoreTextNode = sceneView.scene.rootNode.childNode(withName: "text node", recursively: true) else { return }
        
        if let text = scoreTextNode.geometry as? SCNText {
            if score == 99 {
                text.string = "!!! WINNER !!!"
            }
            if score < 10 {
                text.string = "SCORE 0\(score)"
            }
            if score > 9 {
                text.string = "SCORE \(score)"
            }
            
            score += 1
        }
    }

    
    
}
