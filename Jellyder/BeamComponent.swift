//
//  BeamComponent.swift
//  Jellyder
//
//  Created by BAHATTIN KOC on 15.09.2025.
//

import UIKit
import SceneKit

/**
 * Delegate protocol for beam interaction events
 */
protocol BeamComponentDelegate: AnyObject {
    /**
     * Called when the beam compression changes
     * @param component The beam component
     * @param compression The current compression value (0 to 1)
     */
    func beamComponent(_ component: BeamComponent, didChangeCompression compression: CGFloat)
    
    /**
     * Called when the beam wobble amplitude changes
     * @param component The beam component
     * @param amplitude The current wobble amplitude (0 to 1)
     */
    func beamComponent(_ component: BeamComponent, didChangeWobbleAmplitude amplitude: CGFloat)
}

/**
 * A custom component that renders a 3D beam with realistic buckling physics
 * The beam can be compressed using pan gestures and exhibits wobbling behavior
 */
final class BeamComponent: UIView {
    
    // MARK: - Public Properties
    
    /**
     * Delegate to receive beam interaction events
     */
    weak var delegate: BeamComponentDelegate?
    
    /**
     * Current compression ratio (0.0 = no compression, 1.0 = maximum compression)
     */
    var compressionRatio: CGFloat {
        get { currentCompression / beamTotalLength }
        set { setCompression(newValue * beamTotalLength) }
    }
    
    /**
     * Whether the beam is currently wobbling
     */
    var isWobbling: Bool {
        return wobbleAmplitude > 0.0001
    }
    
    /**
     * Current wobble amplitude (0.0 = no wobble, 1.0 = maximum wobble)
     */
    var wobbleIntensity: CGFloat {
        return wobbleAmplitude
    }
    
    // MARK: - Private Properties
    
    private var sceneView: SCNView!
    private var beamNode: SCNNode!
    
    // Beam Physical Properties
    private var beamTotalLength: CGFloat = 3.5
    private var beamThicknessY: CGFloat = 0.1
    private var beamThicknessZ: CGFloat = 0.5
    private var beamSegmentCount: Int = 80
    
    // Compression State
    private var currentCompression: CGFloat = 0
    private var compressionAtPanStart: CGFloat = 0
    private var maxCompressionRatio: CGFloat = 0.8
    private var minLengthRatio: CGFloat = 0.2
    
    // Buckling Physics
    private var bucklingAmplitudeGain: CGFloat = 0.45
    private var flatEndLeft: CGFloat = 0.25
    private var flatEndRight: CGFloat = 0.25
    private var transitionSmoothness: CGFloat = 0.15
    
    // Animation System
    private var displayLink: CADisplayLink?
    private var wobblePhase: CGFloat = 0
    private var wobbleAmplitude: CGFloat = 0
    private var wobbleDamping: CGFloat = 2.5
    private var wobbleFrequency: CGFloat = 2.0
    private var velocityToWobbleGain: CGFloat = 0.0003
    private var lateralWobbleGain: CGFloat = 0.3
    private var lastAnimationTimestamp: CFTimeInterval = 0
    private var roundEnds: Bool = true
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupComponent()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupComponent()
    }
    
    deinit {
        stopAnimation()
    }
    
    // MARK: - Public Interface
    
    /**
     * Sets the beam compression programmatically
     * @param compression The compression value (0 to beamTotalLength)
     */
    func setCompression(_ compression: CGFloat) {
        let clampedCompression = max(0, min(beamTotalLength * maxCompressionRatio, compression))
        currentCompression = clampedCompression
        updateBeamShape()
        delegate?.beamComponent(self, didChangeCompression: compressionRatio)
    }
    
    /**
     * Adds wobble to the beam
     * @param intensity The wobble intensity (0 to 1)
     */
    func addWobble(intensity: CGFloat) {
        let clampedIntensity = max(0, min(1, intensity))
        wobbleAmplitude = min(1.0, wobbleAmplitude + clampedIntensity)
        delegate?.beamComponent(self, didChangeWobbleAmplitude: wobbleAmplitude)
    }
    
    /**
     * Stops all wobbling immediately
     */
    func stopWobble() {
        wobbleAmplitude = 0
        delegate?.beamComponent(self, didChangeWobbleAmplitude: 0)
    }
    
    /**
     * Resets the beam to its original state
     */
    func reset() {
        currentCompression = 0
        wobbleAmplitude = 0
        wobblePhase = 0
        updateBeamShape()
        delegate?.beamComponent(self, didChangeCompression: 0)
        delegate?.beamComponent(self, didChangeWobbleAmplitude: 0)
    }
    
    /**
     * Configures beam physical properties
     * @param length Total length of the beam
     * @param thicknessY Thickness in Y direction
     * @param thicknessZ Thickness in Z direction
     * @param segments Number of segments for smoothness
     */
    func configureBeam(length: CGFloat, thicknessY: CGFloat, thicknessZ: CGFloat, segments: Int) {
        beamTotalLength = length
        beamThicknessY = thicknessY
        beamThicknessZ = thicknessZ
        beamSegmentCount = max(4, segments)
        updateBeamShape()
    }
    
    /**
     * Configures buckling physics parameters
     * @param amplitudeGain How much the beam buckles under compression
     * @param flatEnds How much of each end remains flat
     * @param smoothness How smooth the transitions are
     */
    func configureBuckling(amplitudeGain: CGFloat, flatEnds: CGFloat, smoothness: CGFloat) {
        bucklingAmplitudeGain = amplitudeGain
        flatEndLeft = flatEnds
        flatEndRight = flatEnds
        transitionSmoothness = smoothness
        updateBeamShape()
    }
    
    /**
     * Configures wobble animation parameters
     * @param damping How quickly wobble fades out
     * @param frequency How fast the wobble oscillates
     * @param velocityGain How much velocity affects wobble
     * @param lateralGain How much lateral wobble occurs
     */
    func configureWobble(damping: CGFloat, frequency: CGFloat, velocityGain: CGFloat, lateralGain: CGFloat) {
        wobbleDamping = damping
        wobbleFrequency = frequency
        velocityToWobbleGain = velocityGain
        lateralWobbleGain = lateralGain
    }
    
    // MARK: - Private Setup
    
    private func setupComponent() {
        setupSceneView()
        setupScene()
        setupCamera()
        setupLighting()
        setupBeam()
        setupGestureRecognizers()
        startAnimationLoop()
    }
    
    private func setupSceneView() {
        sceneView = SCNView(frame: bounds)
        sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        sceneView.allowsCameraControl = false
        sceneView.backgroundColor = .black
        addSubview(sceneView)
    }
    
    private func setupScene() {
        let scene = SCNScene()
        sceneView.scene = scene
    }
    
    private func setupCamera() {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.usesOrthographicProjection = false
        
        let cameraRadius: Float = 8
        let cameraYawDegrees: Float = 35
        let cameraPitchDegrees: Float = -25
        let yaw = cameraYawDegrees * .pi / 180
        let pitch = cameraPitchDegrees * .pi / 180
        
        let x = cameraRadius * cosf(pitch) * sinf(yaw)
        let y = cameraRadius * sinf(pitch)
        let z = cameraRadius * cosf(pitch) * cosf(yaw)
        cameraNode.position = SCNVector3(x - 4, y + 8, z)
        
        let lookTarget = SCNNode()
        sceneView.scene?.rootNode.addChildNode(lookTarget)
        let lookAtConstraint = SCNLookAtConstraint(target: lookTarget)
        lookAtConstraint.isGimbalLockEnabled = true
        cameraNode.constraints = [lookAtConstraint]
        sceneView.scene?.rootNode.addChildNode(cameraNode)
    }
    
    private func setupLighting() {
        guard let scene = sceneView.scene else { return }
        
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.intensity = 400
        let ambientNode = SCNNode()
        ambientNode.light = ambientLight
        scene.rootNode.addChildNode(ambientNode)
        
        let directionalLight = SCNLight()
        directionalLight.type = .directional
        directionalLight.intensity = 900
        let directionalNode = SCNNode()
        directionalNode.light = directionalLight
        directionalNode.eulerAngles = SCNVector3(-CGFloat.pi / 4, .pi / 6, 0)
        scene.rootNode.addChildNode(directionalNode)
    }
    
    private func setupBeam() {
        guard let scene = sceneView.scene else { return }
        beamNode = SCNNode()
        scene.rootNode.addChildNode(beamNode)
        updateBeamShape()
    }
    
    private func setupGestureRecognizers() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        sceneView.addGestureRecognizer(panGesture)
    }
    
    private func startAnimationLoop() {
        let animationLink = CADisplayLink(target: self, selector: #selector(updateAnimation(_:)))
        animationLink.add(to: .main, forMode: .common)
        displayLink = animationLink
    }
    
    private func stopAnimation() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    // MARK: - Beam Construction
    
    private func updateBeamShape() {
        let beamData = calculateBeamParameters()
        let crossSection = generateCrossSection(radius: beamData.cornerRadius)
        let (positions, colors) = generateBeamVertices(
            crossSection: crossSection,
            beamData: beamData
        )
        let indices = generateBeamIndices(
            segmentCount: beamData.segmentCount,
            crossSectionCount: crossSection.count
        )
        let geometry = createBeamGeometry(
            positions: positions,
            colors: colors,
            indices: indices
        )
        beamNode.geometry = geometry
    }
    
    // MARK: - Beam Calculation Helpers
    
    private func calculateBeamParameters() -> BeamParameters {
        let compressedLength = max(beamTotalLength - currentCompression, beamTotalLength * minLengthRatio)
        let segmentCount = max(4, beamSegmentCount)
        let baseAmplitude = bucklingAmplitudeGain * currentCompression
        let oscillation = sin(wobblePhase)
        let amplitude = baseAmplitude * (1 + 0.25 * wobbleAmplitude * oscillation)
        
        let halfThicknessY = beamThicknessY / 2
        let halfThicknessZ = beamThicknessZ / 2
        let cornerRadius = min(halfThicknessY, halfThicknessZ)
        
        let startX = -beamTotalLength / 2
        let endX = startX + compressedLength
        let clampedLeft = min(flatEndLeft, compressedLength * 0.49)
        let clampedRight = min(flatEndRight, compressedLength * 0.49)
        let midStart = startX + clampedLeft
        let midEnd = endX - clampedRight
        let midLength = max(0.0001, midEnd - midStart)
        
        return BeamParameters(
            compressedLength: compressedLength,
            segmentCount: segmentCount,
            amplitude: amplitude,
            oscillation: oscillation,
            halfThicknessY: halfThicknessY,
            halfThicknessZ: halfThicknessZ,
            cornerRadius: cornerRadius,
            startX: startX,
            endX: endX,
            midStart: midStart,
            midEnd: midEnd,
            midLength: midLength
        )
    }
    
    private func generateCrossSection(radius: CGFloat) -> [CGPoint] {
        let cornerSegments = 8
        var crossSection: [CGPoint] = []
        
        if radius > 0 {
            func addArc(centerX: CGFloat, centerZ: CGFloat, startAngle: CGFloat, endAngle: CGFloat) {
                for segment in 0...cornerSegments {
                    let t = CGFloat(segment) / CGFloat(cornerSegments)
                    let angle = startAngle + (endAngle - startAngle) * t
                    crossSection.append(CGPoint(
                        x: centerX + radius * cos(angle),
                        y: centerZ + radius * sin(angle)
                    ))
                }
            }
            
            addArc(centerX: beamThicknessY/2 - radius, centerZ: beamThicknessZ/2 - radius, startAngle: 0, endAngle: .pi/2)
            addArc(centerX: -beamThicknessY/2 + radius, centerZ: beamThicknessZ/2 - radius, startAngle: .pi/2, endAngle: .pi)
            addArc(centerX: -beamThicknessY/2 + radius, centerZ: -beamThicknessZ/2 + radius, startAngle: .pi, endAngle: 3*CGFloat.pi/2)
            addArc(centerX: beamThicknessY/2 - radius, centerZ: -beamThicknessZ/2 + radius, startAngle: 3*CGFloat.pi/2, endAngle: 2*CGFloat.pi)
            crossSection.removeLast()
        } else {
            crossSection = [
                CGPoint(x: beamThicknessY/2, y: beamThicknessZ/2),
                CGPoint(x: -beamThicknessY/2, y: beamThicknessZ/2),
                CGPoint(x: -beamThicknessY/2, y: -beamThicknessZ/2),
                CGPoint(x: beamThicknessY/2, y: -beamThicknessZ/2)
            ]
        }
        
        return crossSection
    }
    
    private func generateBeamVertices(crossSection: [CGPoint], beamData: BeamParameters) -> ([SCNVector3], [Float]) {
        var positions: [SCNVector3] = []
        var colors: [Float] = []
        
        positions.reserveCapacity(beamData.segmentCount * crossSection.count + 2)
        
        var firstCenter = SCNVector3Zero
        var lastCenter = SCNVector3Zero
        
        for segmentIndex in 0..<beamData.segmentCount {
            let t = CGFloat(segmentIndex) / CGFloat(beamData.segmentCount - 1)
            let x = beamData.startX + t * beamData.compressedLength
            
            let (y, dydx, lateral) = calculateBeamDeflection(
                x: x,
                beamData: beamData
            )
            
            let (cosTheta, sinTheta) = calculateRotation(dydx: dydx)
            let endScale = roundEnds ? calculateEndScale(x: x, beamData: beamData) : 1
            
            for point in crossSection {
                let scaledX = point.x * endScale
                let scaledY = point.y * endScale
                let worldX = x + lateral + (-sinTheta) * scaledX
                let worldY = y + cosTheta * scaledX
                let worldZ = scaledY
                positions.append(SCNVector3(Float(worldX), Float(worldY), Float(worldZ)))
                
                let color = calculateVertexColor(t: Float(t))
                colors.append(contentsOf: [color.r, color.g, color.b, color.a])
            }
            
            if segmentIndex == 0 { firstCenter = SCNVector3(Float(x), Float(y), 0) }
            if segmentIndex == beamData.segmentCount - 1 { lastCenter = SCNVector3(Float(x), Float(y), 0) }
        }
        
        positions.append(firstCenter)
        positions.append(lastCenter)
        
        return (positions, colors)
    }

    private func calculateEndScale(x: CGFloat, beamData: BeamParameters) -> CGFloat {
        let radius = max(beamData.halfThicknessY, beamData.halfThicknessZ)
        let distanceToStart = x - beamData.startX
        let distanceToEnd = beamData.endX - x
        let nearest = min(distanceToStart, distanceToEnd)
        if nearest >= radius { return 1 }
        if nearest <= 0 { return 0 }
        let u = nearest / radius
        return sqrt(max(0, 2 * u - u * u))
    }
    
    private func calculateBeamDeflection(x: CGFloat, beamData: BeamParameters) -> (y: CGFloat, dydx: CGFloat, lateral: CGFloat) {
        var y: CGFloat = 0
        var dydx: CGFloat = 0
        var lateral: CGFloat = 0
        
        if x > beamData.midStart && x < beamData.midEnd {
            let t = (x - beamData.midStart) / beamData.midLength
            lateral = lateralWobbleGain * wobbleAmplitude * beamData.oscillation * sin(.pi * t) * 1.01
            
            let asymmetryFactor = 1.0 - t * 0.9
            let ys = beamData.amplitude * sin(.pi * t) * asymmetryFactor
            let dysdx = beamData.amplitude * .pi / beamData.midLength * cos(.pi * t) * asymmetryFactor
            
            let transitionWidth = max(0.0001, min(transitionSmoothness, beamData.midLength * 0.49))
            
            func smoothStep(_ u: CGFloat) -> CGFloat {
                let v = max(0, min(1, u))
                return v * v * (3 - 2 * v)
            }
            
            func smoothStepDerivative(_ u: CGFloat) -> CGFloat {
                let v = max(0, min(1, u))
                return 6 * v * (1 - v)
            }
            
            let uLeft = (x - beamData.midStart) / transitionWidth
            let uRight = (beamData.midEnd - x) / transitionWidth
            let leftBlend = smoothStep(uLeft)
            let rightBlend = smoothStep(uRight)
            let leftDeriv = smoothStepDerivative(uLeft) / transitionWidth
            let rightDeriv = -smoothStepDerivative(uRight) / transitionWidth
            
            let blend = leftBlend * rightBlend
            let blendDeriv = leftDeriv * rightBlend + leftBlend * rightDeriv
            
            y = blend * ys
            dydx = blend * dysdx + blendDeriv * ys
        }
        
        return (y, dydx, lateral)
    }
    
    private func calculateRotation(dydx: CGFloat) -> (cosTheta: CGFloat, sinTheta: CGFloat) {
        let theta = atan(dydx)
        return (cos(theta), sin(theta))
    }
    
    private func calculateVertexColor(t: Float) -> (r: Float, g: Float, b: Float, a: Float) {
        let leftColor = (r: Float(1.0), g: Float(1.0), b: Float(1.0), a: Float(1.0))
        let midColor = (r: Float(1.0), g: Float(0.35), b: Float(0.0), a: Float(1.0))
        let rightColor = (r: Float(1.0), g: Float(0.35), b: Float(0.0), a: Float(1.0))
        
        if t <= 0.5 {
            let u = t / 0.5
            return (
                r: leftColor.r + (midColor.r - leftColor.r) * u,
                g: leftColor.g + (midColor.g - leftColor.g) * u,
                b: leftColor.b + (midColor.b - leftColor.b) * u,
                a: leftColor.a + (midColor.a - leftColor.a) * u
            )
        } else {
            let u = (t - 0.5) / 0.5
            return (
                r: midColor.r + (rightColor.r - midColor.r) * u,
                g: midColor.g + (rightColor.g - midColor.g) * u,
                b: midColor.b + (rightColor.b - midColor.b) * u,
                a: midColor.a + (rightColor.a - midColor.a) * u
            )
        }
    }
    
    private func generateBeamIndices(segmentCount: Int, crossSectionCount: Int) -> [Int32] {
        var indices: [Int32] = []
        
        for segmentIndex in 0..<(segmentCount - 1) {
            let baseA = Int32(segmentIndex * crossSectionCount)
            let baseB = Int32((segmentIndex + 1) * crossSectionCount)
            
            for pointIndex in 0..<crossSectionCount {
                let nextPointIndex = (pointIndex + 1) % crossSectionCount
                
                indices.append(contentsOf: [
                    baseA + Int32(pointIndex),
                    baseB + Int32(pointIndex),
                    baseB + Int32(nextPointIndex)
                ])
                
                indices.append(contentsOf: [
                    baseA + Int32(pointIndex),
                    baseB + Int32(nextPointIndex),
                    baseA + Int32(nextPointIndex)
                ])
            }
        }
        
        let startCenterIndex = Int32(segmentCount * crossSectionCount)
        let endCenterIndex = Int32(segmentCount * crossSectionCount + 1)
        let baseStart = Int32(0)
        let baseEnd = Int32((segmentCount - 1) * crossSectionCount)
        
        for pointIndex in 0..<crossSectionCount {
            let nextPointIndex = (pointIndex + 1) % crossSectionCount
            
            indices.append(contentsOf: [
                startCenterIndex,
                baseStart + Int32(pointIndex),
                baseStart + Int32(nextPointIndex)
            ])
            
            indices.append(contentsOf: [
                endCenterIndex,
                baseEnd + Int32(nextPointIndex),
                baseEnd + Int32(pointIndex)
            ])
        }
        
        return indices
    }
    
    private func createBeamGeometry(positions: [SCNVector3], colors: [Float], indices: [Int32]) -> SCNGeometry {
        let vertexSource = SCNGeometrySource(vertices: positions)
        
        let colorData = Data(bytes: colors, count: colors.count * MemoryLayout<Float>.size)
        let colorSource = SCNGeometrySource(
            data: colorData,
            semantic: .color,
            vectorCount: positions.count,
            usesFloatComponents: true,
            componentsPerVector: 4,
            bytesPerComponent: MemoryLayout<Float>.size,
            dataOffset: 0,
            dataStride: MemoryLayout<Float>.size * 4
        )
        
        let indexData = Data(bytes: indices, count: indices.count * MemoryLayout<Int32>.size)
        let element = SCNGeometryElement(
            data: indexData,
            primitiveType: .triangles,
            primitiveCount: indices.count / 3,
            bytesPerIndex: MemoryLayout<Int32>.size
        )
        
        let geometry = SCNGeometry(sources: [vertexSource, colorSource], elements: [element])
        
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.white
        material.metalness.contents = 0.2
        material.roughness.contents = 0.35
        material.isDoubleSided = false
        material.blendMode = .replace
        geometry.materials = [material]
        
        return geometry
    }
    
    // MARK: - User Interaction
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: sceneView)
        let velocity = gesture.velocity(in: sceneView)
        
        switch gesture.state {
        case .began:
            compressionAtPanStart = currentCompression
            
        case .changed:
            updateCompressionFromPan(translation: translation, velocity: velocity)
            
        case .ended, .cancelled, .failed:
            break
            
        default:
            break
        }
    }
    
    private func updateCompressionFromPan(translation: CGPoint, velocity: CGPoint) {
        let panSensitivity: CGFloat = 0.01
        let compressionDelta = -translation.x * panSensitivity
        let newCompression = max(0, min(
            beamTotalLength * maxCompressionRatio,
            compressionAtPanStart + compressionDelta
        ))
        
        currentCompression = newCompression
        
        let compressionRatio = currentCompression / beamTotalLength
        let normalizedVelocity = abs(velocity.x) * (1.0 - compressionRatio * 0.7)
        let velocityBoost = min(0.25, normalizedVelocity * velocityToWobbleGain * 0.5)
        wobbleAmplitude = min(1.0, wobbleAmplitude + velocityBoost)
        wobblePhase += 0.04
        
        updateBeamShape()
        delegate?.beamComponent(self, didChangeCompression: compressionRatio)
        delegate?.beamComponent(self, didChangeWobbleAmplitude: wobbleAmplitude)
    }
    
    // MARK: - Animation Loop
    
    @objc private func updateAnimation(_ displayLink: CADisplayLink) {
        if lastAnimationTimestamp == 0 {
            lastAnimationTimestamp = displayLink.timestamp
        }
        
        let deltaTime = CGFloat(displayLink.timestamp - lastAnimationTimestamp)
        lastAnimationTimestamp = displayLink.timestamp
        
        updateWobbleAnimation(deltaTime: deltaTime)
    }
    
    private func updateWobbleAnimation(deltaTime: CGFloat) {
        if wobbleAmplitude > 0.0001 {
            wobbleAmplitude = max(0, wobbleAmplitude * exp(-wobbleDamping * deltaTime))
            wobblePhase += 2 * .pi * wobbleFrequency * deltaTime
            
            updateBeamShape()
            delegate?.beamComponent(self, didChangeWobbleAmplitude: wobbleAmplitude)
        }
    }
    
    // MARK: - Data Structures
    
    private struct BeamParameters {
        let compressedLength: CGFloat
        let segmentCount: Int
        let amplitude: CGFloat
        let oscillation: CGFloat
        let halfThicknessY: CGFloat
        let halfThicknessZ: CGFloat
        let cornerRadius: CGFloat
        let startX: CGFloat
        let endX: CGFloat
        let midStart: CGFloat
        let midEnd: CGFloat
        let midLength: CGFloat
    }
}
