//
//  ViewController.swift
//  ARKitFirstApp
//
//  Created by Gustavo Rodrigues on 27/02/18.
//  Copyright © 2018 Gustavo Rodrigues. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    var trackerNode: SCNNode!
    var mainContainer: SCNNode!
    var gameHasStarted = false
    var foundSurface = false
    var gamePos = SCNVector3Make(0.0, 0.0, 0.0)
    var scoreLbl: UILabel!
    
    var score = 0 {
        didSet {
            scoreLbl.text = "\(score)"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/Scene.scn")!
        
        // Set the scene to the view
        sceneView.scene = scene
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    func randomPosition() -> SCNVector3 {
        let randX = (Float(arc4random_uniform(200)) / 100.0) - 1.0
        let randY = (Float(arc4random_uniform(200)) / 100.0) + 1.5
        
        return SCNVector3Make(randX, randY, -3.0)
    }
    
    @objc func addPlane(){
        let planeNode = sceneView.scene.rootNode.childNode(withName: "plane", recursively: false)?.copy() as! SCNNode
        planeNode.isHidden = false
        planeNode.position = randomPosition()
        
        mainContainer.addChildNode(planeNode)
        
        let randSpeed = SCNVector3Make(0.0, 0.0, Float(arc4random_uniform(2) + 4))
        planeNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        planeNode.physicsBody?.isAffectedByGravity = false
        planeNode.physicsBody?.applyForce(randSpeed, asImpulse: true)
        
        let planeDissapearAction = SCNAction.sequence([SCNAction.wait(duration: 10.0), SCNAction.fadeOut(duration: 1.0), SCNAction.removeFromParentNode()])
        planeNode.runAction(planeDissapearAction)
        
        Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(addPlane), userInfo: nil, repeats: false)
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if gameHasStarted {
            //guard let touch = touches.first else { return }
            let touchLocation = CGPoint(x:view.frame.width/2, y: view.frame.height/2) //touch.location(in: view)
            print(touchLocation)
            guard let nodeHitTest = sceneView.hitTest(touchLocation, options: nil).first else { return }
            let hitNode = nodeHitTest.node
            
            guard hitNode.name == "plane" else { return }
            score += 1
            
            let explosion = SCNParticleSystem(named: "Explosion.scnp", inDirectory: nil)!
            hitNode.addParticleSystem(explosion)
            
            let planeSpinForce = SCNVector4Make(0.5, 0.0, 1.0, 1.0)
            hitNode.physicsBody?.isAffectedByGravity = true
            hitNode.physicsBody?.applyTorque(planeSpinForce, asImpulse: true)
            
        }else{
            guard foundSurface else { return }
            trackerNode.removeFromParentNode()
            gameHasStarted = true
            
            scoreLbl = UILabel(frame: CGRect(x: 0.0, y: view.frame.height * 0.05, width: view.frame.width, height: view.frame.height * 0.1))
            scoreLbl.textAlignment = .center
            scoreLbl.font = UIFont(name: "Arial", size: view.frame.width * 0.1)
            scoreLbl.textColor = .yellow
            scoreLbl.text = "\(score)"
            
            view.addSubview(scoreLbl)
            
            mainContainer = sceneView.scene.rootNode.childNode(withName: "mainContainer", recursively: false)!
            mainContainer.isHidden = false
            mainContainer.position = gamePos
         
            addPlane()
            
            let ambientLight = SCNLight()
            ambientLight.type = .ambient
            ambientLight.color = UIColor.white
            ambientLight.intensity = 500
            
            let ambientLightNode = SCNNode()
            ambientLightNode.light = ambientLight
            ambientLightNode.position.y = 3.0
            
            mainContainer.addChildNode(ambientLightNode)
            
            let omniLight = SCNLight()
            omniLight.type = .omni
            omniLight.color = UIColor.white
            omniLight.intensity = 1000
            
            let omniLightNode = SCNNode()
            omniLightNode.light = omniLight
            omniLightNode.position.y = 3.0
            
            mainContainer.addChildNode( omniLightNode)
            
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard !gameHasStarted else { return }
        guard let hitTest = sceneView.hitTest(CGPoint(x: view.frame.midX, y: view.frame.midY), types: [.existingPlane, .featurePoint]).last else { return }
        let trans = SCNMatrix4(hitTest.worldTransform)
        gamePos = SCNVector3Make(trans.m41, trans.m42, trans.m43)
        
        if !foundSurface {
            let trackerPlane = SCNPlane(width: 0.3, height: 0.3)
            trackerPlane.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "tracker")
            trackerNode = SCNNode(geometry: trackerPlane)
            print(trackerNode.position)
            trackerNode.eulerAngles.x = .pi * -0.5
            sceneView.scene.rootNode.addChildNode(trackerNode)
        }
        trackerNode.position = gamePos
        foundSurface = true
    }
}













































