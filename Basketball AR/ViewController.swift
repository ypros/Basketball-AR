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
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
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
        
        basketNode.eulerAngles.x -= .pi/2
        
        return basketNode
    }
    
    private func getBallNode() -> SCNNode {
        let ball = SCNSphere(radius: 0.125)
        ball.firstMaterial?.diffuse.contents = UIImage(named: "BasketballColor")
        
        let ballNode = SCNNode(geometry: ball)
        if let frame = sceneView.session.currentFrame {
            ballNode.simdTransform = frame.camera.transform
        }
        
        return SCNNode(geometry: ball)
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
            
            sceneView.scene.rootNode.addChildNode(getBallNode())
            
        }
        else {
            let location = sender.location(in: sceneView)
            
            guard let hitResult = sceneView.hitTest(location, types: .existingPlaneUsingExtent).first else {
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
    
}
