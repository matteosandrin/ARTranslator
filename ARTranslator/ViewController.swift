//
//  ViewController.swift
//  ARTranslator
//
//  Created by Matteo Sandrin on 23/03/2018.
//  Copyright © 2018 CompanyName. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import ROGoogleTranslate

import Vision

class ViewController: UIViewController, ARSCNViewDelegate, UINavigationControllerDelegate {

    var currentLang: Int = 44
    // SCENE
    @IBOutlet var sceneView: ARSCNView!
    let bubbleDepth : Float = 0.01 // the 'depth' of 3D text
    var latestPrediction : String = "…" // a variable containing the latest CoreML prediction
    var isLoaded : Bool = false
    
    // COREML
    var visionRequests = [VNRequest]()
    let dispatchQueueML = DispatchQueue(label: "com.hw.dispatchqueu eml") // A Serial Queue
    @IBOutlet weak var predictView: UIView!
    @IBOutlet weak var predictLabel: UILabel!
    @IBOutlet weak var languageView: UIView!
    @IBOutlet weak var languageButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupInterface()
        
        
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = false
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
        // Enable Default Lighting - makes the 3D text a bit poppier.
        sceneView.autoenablesDefaultLighting = true
        
        //////////////////////////////////////////////////
        // Tap Gesture Recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(gestureRecognize:)))
        view.addGestureRecognizer(tapGesture)
        
        //////////////////////////////////////////////////
        
        // Set up Vision Model
        guard let selectedModel = try? VNCoreMLModel(for: Inceptionv3().model) else { // (Optional) This can be replaced with other models on https://developer.apple.com/machine-learning/
            fatalError("Could not load model. Ensure model has been drag and dropped (copied) to XCode Project from https://developer.apple.com/machine-learning/ . Also ensure the model is part of a target (see: https://stackoverflow.com/questions/45884085/model-is-not-part-of-any-target-add-the-model-to-a-target-to-enable-generation ")
        }
        
        // Set up Vision-CoreML Request
        let classificationRequest = VNCoreMLRequest(model: selectedModel, completionHandler: classificationCompleteHandler)
        classificationRequest.imageCropAndScaleOption = VNImageCropAndScaleOption.centerCrop // Crop from centre of images and scale to appropriate size.
        visionRequests = [classificationRequest]
        
        // Begin Loop to Update CoreML
        loopCoreMLUpdate()
        checkHitTestResults()
        NotificationCenter.default.addObserver(self, selector: #selector(modalWasDismissed), name: NSNotification.Name(rawValue: "Dismiss"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        // Enable plane detection
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            // Do any desired updates to SceneKit here.
        }
    }
    
    // MARK: - Status Bar: Hide
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    // MARK: - Interaction
    
    @objc func handleTap(gestureRecognize: UITapGestureRecognizer) {
        // HIT TEST : REAL WORLD
        // Get Screen Centre
        print("tap!")
        let screenCentre : CGPoint = CGPoint(x: self.sceneView.bounds.midX, y: self.sceneView.bounds.midY)
        let arHitTestResults : [ARHitTestResult] = sceneView.hitTest(screenCentre, types: [.featurePoint]) // Alternatively, we could use '.existingPlaneUsingExtent' for more grounded hit-test-points.
        
        if let closestResult = arHitTestResults.first {
            // Get Coordinates of HitTest
            let transform : matrix_float4x4 = closestResult.worldTransform
            let worldCoord : SCNVector3 = SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
            
            let translator = ROGoogleTranslate()
            let langs = translator.languages()
            let lang = langs[self.currentLang] as? [String:String]
            let targetLang: String = lang!["language"] as! String
            let original = latestPrediction
            
            let params = ROGoogleTranslateParams(source: "en",
                                                 target: targetLang,
                                                 text: original)
            translator.translate(params: params) { (result) in
                let node : SCNNode = self.createNewBubbleParentNode(text: original, translation: result)
                self.sceneView.scene.rootNode.addChildNode(node)
                node.position = worldCoord
            }
        }
    }
    
    func createNewBubbleParentNode(text : String, translation : String) -> SCNNode {
        // Warning: Creating 3D Text is susceptible to crashing. To reduce chances of crashing; reduce number of polygons, letters, smoothness, etc.
        
        // TEXT BILLBOARD CONSTRAINT
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = SCNBillboardAxis.Y
        
        // BUBBLE-TEXT
        
        guard let font = UIFont(name: "Roboto-Regular", size: 0.15) else {
            fatalError("""
        Failed to load the "Roboto-Regular" font.
        Make sure the font file is included in the project and the font name is spelled correctly.
        """
            )
        }
        
        let bubble = SCNText(string: text, extrusionDepth: CGFloat(bubbleDepth))
        bubble.font = font
        bubble.alignmentMode = kCAAlignmentCenter
        bubble.firstMaterial?.diffuse.contents = UIColor(red:0.00, green:0.45, blue:0.74, alpha:1.0)
        bubble.firstMaterial?.specular.contents = UIColor.white
        bubble.firstMaterial?.isDoubleSided = true
        bubble.flatness = 0.5
        bubble.chamferRadius = CGFloat(bubbleDepth/2)
        
        // BUBBLE NODE
        let (minBound, maxBound) = bubble.boundingBox
        let bubbleNode = SCNNode(geometry: bubble)
        bubbleNode.pivot = SCNMatrix4MakeTranslation( (maxBound.x - minBound.x)/2, minBound.y - 0.05, bubbleDepth/2)
        bubbleNode.scale = SCNVector3Make(0.15, 0.15, 0.15)
        
        //TRANSLATION TEXT
        
        let transText = SCNText(string: translation.uppercased(), extrusionDepth: CGFloat(bubbleDepth))
        transText.font = font
        transText.alignmentMode = kCAAlignmentCenter
        transText.firstMaterial?.diffuse.contents = UIColor.orange
        transText.firstMaterial?.specular.contents = UIColor.black
        transText.firstMaterial?.isDoubleSided = true
        transText.flatness = 0.5
        transText.chamferRadius = CGFloat(bubbleDepth/2)
        
        //TRANSLATION TEXT NODE
        
        let (minTrBound, maxTrBound) = transText.boundingBox
        let transNode = SCNNode(geometry: transText)
        // Centre Node - to Centre-Bottom point
        transNode.pivot = SCNMatrix4MakeTranslation( (maxTrBound.x - minTrBound.x)/2, minTrBound.y - (maxBound.y-minBound.y) - 0.02, bubbleDepth/2)
        // Reduce default text size
        transNode.scale = SCNVector3Make(0.2, 0.2, 0.2)
        
        // CENTRE POINT NODE
        let sphere = SCNSphere(radius: 0.005)
        sphere.firstMaterial?.diffuse.contents = UIColor.orange
        let sphereNode = SCNNode(geometry: sphere)
        
        // BUBBLE PARENT NODE
        let bubbleNodeParent = SCNNode()
        bubbleNodeParent.addChildNode(bubbleNode)
        bubbleNodeParent.addChildNode(transNode)
        bubbleNodeParent.addChildNode(sphereNode)
        bubbleNodeParent.constraints = [billboardConstraint]
        
        return bubbleNodeParent
    }
    
    // MARK: - CoreML Vision Handling
    
    func loopCoreMLUpdate() {
        // Continuously run CoreML whenever it's ready. (Preventing 'hiccups' in Frame Rate)
        
        dispatchQueueML.async {
            // 1. Run Update.
            self.updateCoreML()
            
            // 2. Loop this function.
            self.loopCoreMLUpdate()
        }
        
    }
    
    func classificationCompleteHandler(request: VNRequest, error: Error?) {
        // Catch Errors
        if error != nil {
            print("Error: " + (error?.localizedDescription)!)
            return
        }
        guard let observations = request.results else {
            print("No results")
            return
        }
        
        // Get Classifications
        let classifications = observations[0...1] // top 2 results
            .flatMap({ $0 as? VNClassificationObservation })
            .map({ "\($0.identifier) \(String(format:"- %.2f", $0.confidence))" })
            .joined(separator: "\n")
        
        
        DispatchQueue.main.async {
            // Print Classifications
//            print(classifications)
//            print("--")
            
            // Store the latest prediction
            var objectName:String = ""
            objectName = classifications.components(separatedBy: "-")[0]
            objectName = objectName.components(separatedBy: ",")[0]
            self.latestPrediction = objectName
            if self.isLoaded {
                self.predictLabel.text = self.latestPrediction
            }
            
            
        }
    }
    
    func updateCoreML() {
        ///////////////////////////
        // Get Camera Image as RGB
        let pixbuff : CVPixelBuffer? = (sceneView.session.currentFrame?.capturedImage)
        if pixbuff == nil { return }
        let ciImage = CIImage(cvPixelBuffer: pixbuff!)
        // Note: Not entirely sure if the ciImage is being interpreted as RGB, but for now it works with the Inception model.
        // Note2: Also uncertain if the pixelBuffer should be rotated before handing off to Vision (VNImageRequestHandler) - regardless, for now, it still works well with the Inception model.
        
        ///////////////////////////
        // Prepare CoreML/Vision Request
        let imageRequestHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        // let imageRequestHandler = VNImageRequestHandler(cgImage: cgImage!, orientation: myOrientation, options: [:]) // Alternatively; we can convert the above to an RGB CGImage and use that. Also UIInterfaceOrientation can inform orientation values.
        
        ///////////////////////////
        // Run Image Request
        do {
            try imageRequestHandler.perform(self.visionRequests)
        } catch {
            print(error)
        }
        
    }
    
    func setupInterface() {
        
        self.predictView.layer.cornerRadius = 10.0
        self.languageView.layer.cornerRadius = 10.0
        self.predictLabel.text = "Loading..."
        updateLanguageButton()
        UIApplication.shared.setStatusBarHidden(false, with: UIStatusBarAnimation.none)
        
    }
    
    func checkHitTestResults() {
        let screenCentre : CGPoint = CGPoint(x: self.sceneView.bounds.midX, y: self.sceneView.bounds.midY)
        let arHitTestResults : [ARHitTestResult] = sceneView.hitTest(screenCentre, types: [.featurePoint])
        let hit = arHitTestResults.first
        if hit == nil {
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: { _ in self.checkHitTestResults() } )
        }else{
            self.isLoaded = true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationViewController = segue.destination as? ARTableViewController {
            destinationViewController.currentLang = self.currentLang
        }
    }
    
    @objc func modalWasDismissed() {
        self.sceneView.scene.rootNode.enumerateChildNodes { (node, stop) -> Void in
            node.removeFromParentNode()
        }
        updateLanguageButton()
    }
    
    func updateLanguageButton() {
        let translator = ROGoogleTranslate()
        let langs = translator.languages()
        let lang = langs[self.currentLang] as? [String:String]
        let targetLang: String = lang!["name"] as! String
        self.languageButton.setTitle(targetLang, for: UIControlState.normal)
    }
    
    
}

extension UIFont {
    // Based on: https://stackoverflow.com/questions/4713236/how-do-i-set-bold-and-italic-on-uilabel-of-iphone-ipad
    func withTraits(traits:UIFontDescriptorSymbolicTraits...) -> UIFont {
        let descriptor = self.fontDescriptor.withSymbolicTraits(UIFontDescriptorSymbolicTraits(traits))
        return UIFont(descriptor: descriptor!, size: 0)
    }
}
