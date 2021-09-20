//
//  ViewController.swift
//  Basketball AR
//
//  Created by YURY PROSVIRNIN on 18.06.2021.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, SCNPhysicsContactDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var powerLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    
    var score: Int = 0
    private var swipeStartPoint = CGPoint()
    private var swipeEndPoint = CGPoint()
    private var shootingPower: Float = 0
    private var counterPosition = SCNVector3()
    
    let configuration = ARWorldTrackingConfiguration()
    var isBasketSet = false {
        didSet {
            //Setting up configuration detection off
            configuration.planeDetection = []

            // Run the view's session
            sceneView.session.run(configuration, options: .removeExistingAnchors)
        }
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        sceneView.scene.physicsWorld.contactDelegate = self
        // Setup the scene light
        sceneView.autoenablesDefaultLighting = true
        
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
        
        basketNode.physicsBody?.categoryBitMask = 2 //basket
        
        return basketNode
    }
    
    private func getBallNode() -> SCNNode? {
        guard let frame = sceneView.session.currentFrame else { return nil }
        // Get camera transform
        let cameraTransform = frame.camera.transform
        let matrixCameraTransform = SCNMatrix4(cameraTransform)

        let x = -matrixCameraTransform.m31 * shootingPower
        let y = -matrixCameraTransform.m32 * shootingPower
        let z = -matrixCameraTransform.m33 * shootingPower
        let force = SCNVector3(x, y, z)
        
        let ballNode = Ball()
        
        ballNode.physicsBody?.applyForce(force, asImpulse: true)
        ballNode.simdTransform = cameraTransform
        
        ballNode.scale = SCNVector3(0.5, 0.5, 0.5)

        ballNode.setDistance(from: counterPosition)

        return ballNode
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
    
    
    func physicsWorld(_ world: SCNPhysicsWorld, didEnd contact: SCNPhysicsContact) {
        guard let bitMaskA = contact.nodeA.physicsBody?.categoryBitMask,
              let bitMaskB = contact.nodeB.physicsBody?.categoryBitMask
        else { return }
        
        if bitMaskA + bitMaskB != 1 + 4 {
            return
        }
    
        let contactNode = bitMaskA == 1 ? contact.nodeA : contact.nodeB
        guard let ball = contactNode as? Ball else { return }
        
        if !ball.scored {
            addScore(ball.points)
            ball.scored.toggle()
        }
    }
    
    // MARK: - Actions
    @IBAction func userTap(_ sender: UITapGestureRecognizer) {
        
        print("ser taped")
        
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
            
            let counter = Counter()
            counterPosition = counter.position
            
            basketNode.addChildNode(counter)
            //basketNode.addChildNode(Floor())
            
            sceneView.scene.rootNode.addChildNode(basketNode)
            
            isBasketSet.toggle()
        }
    }

    //calculating throwing power
    @IBAction func userPan(_ sender: UIPanGestureRecognizer) {

        if sender.state == .began {
            swipeStartPoint = sender.location(in: sceneView)
        }
        if sender.state == .ended {
            swipeEndPoint = sender.location(in: sceneView)
            
            setShootingPower()
            
            guard let newBall = getBallNode() else { return }
            sceneView.scene.rootNode.addChildNode(newBall)
            
        }
    }
    
    //adding score points and updating score panel
    private func addScore(_ points: Int) {
        guard let scoreTextNode = sceneView.scene.rootNode.childNode(withName: "text", recursively: true) else { return }
        
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
            
            score += points
        }
    }
    
    //setting shooting power by swipe distance
    private func setShootingPower() {
        
        let swipePower = Float(swipeStartPoint.y - swipeEndPoint.y) / Float(sceneView.frame.height)
        shootingPower = 20 * (0.1 + swipePower)
    
    }

    
    
}
