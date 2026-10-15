import SwiftUI
import SceneKit
import simd

final class RoaringCanyonScene {
    let scene = SCNScene()
    let cameraNode = SCNNode()
    private let david = RoaringDavidRig()
    private let lion = RoaringLionRig()
    private let focus = SCNNode()
    private let sun = SCNNode()
    private let gate = SCNNode()
    private var chunks: [SCNNode] = []
    private var obstacleNodes: [Int: SCNNode] = [:]
    private var cameraBlend: Float = 0
    private var lionLane: Double = 1
    private var hitShake: Double = 0
    private let sand: SCNMaterial
    private let stone: SCNMaterial
    private let bark = BeastArt.material("#66503A")
    private let leaves = [BeastArt.material("#A2AF86"), BeastArt.material("#B7BD8B"), BeastArt.material("#82936D")]
    private let trim = BeastArt.material("#DAC39A")
    private let dust = SCNParticleSystem()

    init() {
        sand = Self.textured("RoaringTrail", tint: "#E8D9BD")
        stone = Self.textured("RoaringSandstone", tint: "#E7DDC9")
        if let foliage = UIImage(named: "RoaringFoliage") {
            for material in leaves {
                material.multiply.contents = material.diffuse.contents
                material.diffuse.contents = foliage
                material.diffuse.wrapS = .repeat; material.diffuse.wrapT = .repeat
                material.diffuse.contentsTransform = SCNMatrix4MakeScale(1.5, 1.5, 1)
            }
        }
        scene.background.contents = UIColor(Color(hex: "#D6BE99"))
        scene.fogColor = UIColor(Color(hex: "#D6BE99"))
        scene.fogStartDistance = 32; scene.fogEndDistance = 104; scene.fogDensityExponent = 1.35
        configureLighting()
        configureCamera()
        let floor = SCNFloor(); floor.reflectivity = 0
        floor.materials = [Self.textured("RoaringTrail", tint: "#AEAA78")]
        let floorNode = SCNNode(geometry: floor); floorNode.position.y = -0.2; scene.rootNode.addChildNode(floorNode)
        for index in 0..<7 {
            let chunk = makeChunk(index)
            chunks.append(chunk)
            scene.rootNode.addChildNode(chunk)
        }
        makeDistantRidges()
        makeGate()
        scene.rootNode.addChildNode(david.root)
        scene.rootNode.addChildNode(lion.root)
        makeDust()
        update(run: RoaringRun(), time: 0, dt: 0, reduceMotion: false)
    }

    private static func textured(_ name: String, tint: String) -> SCNMaterial {
        let result = BeastArt.material(tint)
        if let image = UIImage(named: name) {
            result.diffuse.contents = image
            result.multiply.contents = UIColor(Color(hex: tint))
        }
        result.diffuse.wrapS = .repeat; result.diffuse.wrapT = .repeat
        return result
    }
    private func configureCamera() {
        let camera = SCNCamera()
        camera.zNear = 0.1; camera.zFar = 150
        camera.fieldOfView = 58
        camera.wantsHDR = true
        camera.wantsExposureAdaptation = false
        camera.exposureOffset = 0.1
        camera.bloomIntensity = 0.18; camera.bloomThreshold = 1.1; camera.bloomBlurRadius = 5
        camera.vignettingIntensity = 0.32; camera.vignettingPower = 1.5
        camera.screenSpaceAmbientOcclusionIntensity = 0.45
        camera.screenSpaceAmbientOcclusionRadius = 1.3
        cameraNode.camera = camera
        scene.rootNode.addChildNode(cameraNode)
        scene.rootNode.addChildNode(focus)
        let look = SCNLookAtConstraint(target: focus); look.isGimbalLockEnabled = true
        cameraNode.constraints = [look]
    }
    private func configureLighting() {
        let ambient = SCNNode(); ambient.light = SCNLight()
        ambient.light?.type = .ambient; ambient.light?.intensity = 680
        ambient.light?.color = UIColor(Color(hex: "#D8E0DE"))
        scene.rootNode.addChildNode(ambient)
        sun.light = SCNLight(); sun.light?.type = .directional
        sun.light?.intensity = 1350
        sun.light?.color = UIColor(Color(hex: "#FFF1D8"))
        sun.eulerAngles = SCNVector3(-0.75, -0.65, -0.15)
        sun.light?.castsShadow = true; sun.light?.shadowMode = .deferred
        sun.light?.shadowColor = UIColor(red: 0.18, green: 0.21, blue: 0.18, alpha: 0.35)
        sun.light?.shadowMapSize = CGSize(width: 1536, height: 1536)
        sun.light?.shadowRadius = 5; sun.light?.shadowSampleCount = 8
        sun.light?.orthographicScale = 22
        sun.light?.zNear = 0.1; sun.light?.zFar = 90
        scene.rootNode.addChildNode(sun)
        let rim = SCNNode(); rim.light = SCNLight(); rim.light?.type = .omni
        rim.light?.intensity = 180; rim.light?.color = UIColor(Color(hex: "#D7E6EA"))
        rim.position = SCNVector3(0, 4, 6); scene.rootNode.addChildNode(rim)
    }

    private func makeChunk(_ index: Int) -> SCNNode {
        let chunk = SCNNode()
        let road = SCNBox(width: 8.6, height: 0.3, length: 20, chamferRadius: 0)
        let roadMaterial = sand.copy() as! SCNMaterial
        roadMaterial.diffuse.contentsTransform = SCNMatrix4MakeScale(2, 5, 1)
        road.materials = [roadMaterial]
        let roadNode = SCNNode(geometry: road); roadNode.position = SCNVector3(0, -0.15, -10)
        chunk.addChildNode(roadNode)
        for side in [-1.0, 1.0] {
            // Inlaid stones outline the ancient path without turning it into a modern road.
            for j in 0..<10 {
                let edge = BeastArt.box(chunk, SCNVector3(0.25, 0.16, 1.6),
                                         SCNVector3(side * 4.25, 0.025, -Double(j) * 2 - 0.5), trim, bevel: 0.06)
                edge.eulerAngles.y = Float(sin(Double(j + index)) * 0.08)
                edge.castsShadow = false
            }
            for j in 0..<5 {
                let seed = index * 17 + j * 11 + (side < 0 ? 9 : 0)
                let height = 2.6 + Double((seed * 7) % 36) / 10
                let rock = SCNNode(geometry: makeRock(seed: seed))
                rock.geometry?.materials = [stone]
                rock.position = SCNVector3(side * (5.8 + Double(seed % 3) * 0.8), 0, -Double(j) * 4 - 1)
                rock.scale = SCNVector3(2.0 + Double(seed % 3) * 0.45, height, 2.7)
                rock.eulerAngles.y = Float(seed) * 0.37; rock.castsShadow = false
                chunk.addChildNode(rock)
                if j % 2 == index % 2 {
                    let tree = makeOlive(seed: seed)
                    tree.position = SCNVector3(side * (4.9 + Double(seed % 2)), 0, -Double(j) * 4 - 2)
                    tree.scale = SCNVector3(1.1, 1.1 + Double(seed % 3) * 0.18, 1.1)
                    chunk.addChildNode(tree)
                }
            }
            for j in 0..<13 {
                let rock = SCNNode(geometry: makeRock(seed: j + index))
                rock.geometry?.materials = [stone]
                rock.scale = SCNVector3(0.15 + Double(j % 3) * 0.09, 0.12 + Double(j % 2) * 0.1, 0.2)
                rock.position = SCNVector3(side * (4.55 + Double(j % 4) * 0.35), 0, -Double(j) * 1.5)
                rock.castsShadow = false; chunk.addChildNode(rock)
            }
        }
        chunk.addChildNode(makeGrass(seed: index))
        return chunk
    }

    private func makeOlive(seed: Int) -> SCNNode {
        let tree = SCNNode()
        let trunk = SCNCylinder(radius: 0.14, height: 1.8); trunk.radialSegmentCount = 7; trunk.materials = [bark]
        let trunkNode = SCNNode(geometry: trunk); trunkNode.position.y = 0.9
        trunkNode.eulerAngles.z = seed.isMultiple(of: 2) ? 0.13 : -0.12; tree.addChildNode(trunkNode)
        for j in 0..<3 {
            let branch = SCNCylinder(radius: 0.065, height: 1); branch.radialSegmentCount = 6; branch.materials = [bark]
            let node = SCNNode(geometry: branch); node.position = SCNVector3(Double(j - 1) * 0.28, 1.65, 0)
            node.eulerAngles.z = Float(j - 1) * -0.65; tree.addChildNode(node)
        }
        for j in 0..<6 {
            let sphere = SCNSphere(radius: 0.8)
            sphere.segmentCount = 18
            let canopy = SCNNode(geometry: sphere)
            canopy.geometry?.materials = [leaves[(seed + j) % leaves.count]]
            let angle = Double(j) * .pi / 3
            canopy.position = SCNVector3(sin(angle) * 0.65, 1.9 + Double(j % 2) * 0.45, cos(angle) * 0.55)
            canopy.scale = SCNVector3(0.95, 0.8, 0.9)
            canopy.castsShadow = false; tree.addChildNode(canopy)
        }
        tree.castsShadow = false
        return tree
    }

    private func makeGrass(seed: Int) -> SCNNode {
        var vertices: [SCNVector3] = []; var normals: [SCNVector3] = []
        for index in 0..<90 {
            let side: Float = index.isMultiple(of: 2) ? 1 : -1
            let x = side * (4.4 + Float((index * 13 + seed * 7) % 23) / 10)
            let z = -Float((index * 17 + seed * 3) % 200) / 10
            let h = Float(0.2 + Double(index % 5) * 0.08)
            vertices += [SCNVector3(x - 0.04, 0, z), SCNVector3(x + 0.09, h, z + 0.03), SCNVector3(x + 0.04, 0, z)]
            normals += Array(repeating: SCNVector3(0, 0.4, 1), count: 3)
        }
        let element = SCNGeometryElement(indices: (0..<vertices.count).map(Int32.init), primitiveType: .triangles)
        let geometry = SCNGeometry(sources: [SCNGeometrySource(vertices: vertices), SCNGeometrySource(normals: normals)], elements: [element])
        let mat = leaves[1].copy() as! SCNMaterial; mat.isDoubleSided = true; geometry.materials = [mat]
        let node = SCNNode(geometry: geometry); node.castsShadow = false; return node
    }

    /// Irregular ring mesh with smooth normals and stone UVs.
    private func makeRock(seed: Int) -> SCNGeometry {
        var vertices: [SCNVector3] = []; var normals: [SCNVector3] = []; var uv: [CGPoint] = []
        let sides = 14
        func point(_ ring: Int, _ side: Int) -> SIMD3<Float> {
            let angle = Double(side % sides) / Double(sides) * .pi * 2
            let variation = 0.84 + Double((seed * 7 + side * 13 + ring * 5) % 23) / 100
            let radii = [0.88, 1.0, 0.73, 0.22]
            let heights = [0.0, 0.31, 0.75, 1.0]
            return SIMD3(Float(cos(angle) * radii[ring] * variation), Float(heights[ring]), Float(sin(angle) * radii[ring] * variation))
        }
        func triangle(_ a: SIMD3<Float>, _ b: SIMD3<Float>, _ c: SIMD3<Float>) {
            for v in [a, b, c] {
                let n = simd_normalize(SIMD3(v.x, 0.28 + v.y * 0.85, v.z))
                vertices.append(SCNVector3(v)); normals.append(SCNVector3(n))
                uv.append(CGPoint(x: CGFloat(v.x * 0.5 + 0.5), y: CGFloat(v.y)))
            }
        }
        for ring in 0..<3 {
            for side in 0..<sides {
                let a = point(ring, side); let b = point(ring, side + 1)
                let c = point(ring + 1, side); let d = point(ring + 1, side + 1)
                triangle(a, c, b); triangle(b, c, d)
            }
        }
        for side in 0..<sides { triangle(point(3, side), SIMD3(0, 1.04, 0), point(3, side + 1)) }
        let element = SCNGeometryElement(indices: (0..<vertices.count).map(Int32.init), primitiveType: .triangles)
        return SCNGeometry(sources: [SCNGeometrySource(vertices: vertices), SCNGeometrySource(normals: normals), SCNGeometrySource(textureCoordinates: uv)], elements: [element])
    }

    private func makeDistantRidges() {
        for index in 0..<8 {
            let ridge = SCNNode(geometry: makeRock(seed: index * 5))
            ridge.geometry?.materials = [stone]
            ridge.position = SCNVector3(Double(index - 4) * 9, -1, -90 - Double(index % 3) * 4)
            ridge.scale = SCNVector3(9, Double(8 + index % 4 * 3), 8)
            ridge.castsShadow = false; scene.rootNode.addChildNode(ridge)
        }
        let glow = BeastArt.material("#FFF0BE")
        glow.lightingModel = .constant
        let disc = SCNNode(geometry: SCNSphere(radius: 5)); disc.geometry?.materials = [glow]
        disc.position = SCNVector3(-10, 19, -99); disc.castsShadow = false
        scene.rootNode.addChildNode(disc)
    }
    private func makeGate() {
        for side in [-1.0, 1.0] {
            for j in 0..<6 {
                BeastArt.box(gate, SCNVector3(1.0, 0.8, 1.2), SCNVector3(side * 4.6, Double(j) * 0.82 + 0.4, 0), stone, bevel: 0.1)
            }
            BeastArt.box(gate, SCNVector3(1.5, 0.4, 1.6), SCNVector3(side * 4.6, 5, 0), trim)
        }
        BeastArt.box(gate, SCNVector3(10.3, 0.8, 1.2), SCNVector3(0, 5.6, 0), stone, bevel: 0.12)
        let archGlow = SCNNode(); archGlow.light = SCNLight(); archGlow.light?.type = .omni
        archGlow.light?.color = UIColor(Color(hex: "#FFE8A5")); archGlow.light?.intensity = 350
        archGlow.position = SCNVector3(0, 3.5, -1); gate.addChildNode(archGlow)
        scene.rootNode.addChildNode(gate)
    }
    private func makeDust() {
        dust.birthRate = 18; dust.particleLifeSpan = 0.65; dust.particleLifeSpanVariation = 0.2
        dust.particleSize = 0.07; dust.particleSizeVariation = 0.04
        dust.particleColor = UIColor(Color(hex: "#E1C395").opacity(0.35))
        dust.particleVelocity = 0.8; dust.particleVelocityVariation = 0.5
        dust.spreadingAngle = 70; dust.emittingDirection = SCNVector3(0, 0.3, 1)
        dust.acceleration = SCNVector3(0, -0.3, 0)
        dust.blendMode = .alpha; dust.isLightingEnabled = false
        let emitter = SCNNode(); emitter.position = SCNVector3(0, 0.1, 0.25)
        emitter.addParticleSystem(dust); david.root.addChildNode(emitter)
    }

    private func makeHazard(_ hazard: RoaringRun.Hazard) -> SCNNode {
        let root = SCNNode()
        switch hazard.kind {
        case .rock:
            for index in 0..<3 {
                let rock = SCNNode(geometry: makeRock(seed: hazard.id + index))
                rock.geometry?.materials = [stone]
                rock.scale = SCNVector3(index == 0 ? 0.72 : 0.4, index == 0 ? 1.0 : 0.55, 0.65)
                rock.position = SCNVector3(Double(index - 1) * 0.35, 0, Double(index % 2) * 0.2)
                root.addChildNode(rock)
            }
        case .bush:
            for index in 0..<5 {
                let bush = SCNNode(geometry: makeRock(seed: index + hazard.id))
                bush.geometry?.materials = [leaves[index % 3]]
                bush.scale = SCNVector3(0.55, index == 0 ? 1.25 : 0.8, 0.55)
                bush.position = SCNVector3(sin(Double(index) * 2) * 0.43, 0, cos(Double(index) * 2) * 0.2)
                root.addChildNode(bush)
            }
            for side in [-1.0, 1.0] {
                let branch = BeastArt.box(root, SCNVector3(0.1, 0.95, 0.1), SCNVector3(side * 0.4, 0.5, 0), bark)
                branch.eulerAngles.z = Float(side * 0.4)
            }
        case .gap:
            let width: CGFloat = hazard.spansTrack ? 8.1 : 1.95
            let darkness = BeastArt.material("#292820")
            darkness.lightingModel = .constant
            darkness.isDoubleSided = true
            BeastArt.box(root, SCNVector3(Float(width), 0.055, 1.22),
                         SCNVector3(0, 0.035, 0), darkness, bevel: 0)
            let path = UIBezierPath()
            path.move(to: CGPoint(x: -width / 2, y: -0.65))
            for index in 0...8 {
                path.addLine(to: CGPoint(x: -width / 2 + width * CGFloat(index) / 8,
                                         y: -0.65 + (index.isMultiple(of: 2) ? 0.12 : -0.12)))
            }
            for index in (0...8).reversed() {
                path.addLine(to: CGPoint(x: -width / 2 + width * CGFloat(index) / 8,
                                         y: 0.65 + (index.isMultiple(of: 2) ? -0.1 : 0.1)))
            }
            path.close()
            let shape = SCNShape(path: path, extrusionDepth: 0.06)
            shape.materials = [darkness]
            let hole = SCNNode(geometry: shape); hole.eulerAngles.x = -.pi / 2; hole.position.y = 0.018
            root.addChildNode(hole)
            for side in [-1.0, 1.0] {
                BeastArt.box(root, SCNVector3(Float(width), 0.1, 0.12), SCNVector3(0, 0.04, side * 0.78), trim)
            }
        }
        return root
    }

    func registerHit() { hitShake = 0.45 }
    func reset() {
        obstacleNodes.values.forEach { $0.removeFromParentNode() }; obstacleNodes.removeAll()
        lionLane = 1; hitShake = 0; cameraBlend = 0
    }
    func update(run: RoaringRun, time: Double, dt: Double, reduceMotion: Bool) {
        let moving = run.phase == .running
        let cycle = Double(chunks.count) * 20
        for (index, chunk) in chunks.enumerated() {
            var z = run.distance - Double(index) * 20 + 20
            while z > 20 { z -= cycle }
            chunk.position.z = Float(z)
        }
        let ids = Set(run.hazards.map(\.id))
        for id in Array(obstacleNodes.keys) where !ids.contains(id) {
            obstacleNodes[id]?.removeFromParentNode(); obstacleNodes[id] = nil
        }
        for hazard in run.hazards {
            if obstacleNodes[hazard.id] == nil {
                let node = makeHazard(hazard); scene.rootNode.addChildNode(node); obstacleNodes[hazard.id] = node
            }
            obstacleNodes[hazard.id]?.position = SCNVector3(hazard.spansTrack ? 0 : (Double(hazard.lane) - 1) * RoaringRun.laneWidth,
                                                          0, -hazard.distance)
        }
        let x = (run.lanePosition - 1) * RoaringRun.laneWidth
        let introWeight = Double(1 - cameraBlend)
        david.root.position = SCNVector3(x * (1 - introWeight) + 0.9 * introWeight, run.jumpHeight, -3 * introWeight)
        david.root.eulerAngles.y = Float(-Double.pi * 0.98 * introWeight)
        david.animate(time: time, jump: run.jumpHeight, running: moving, lean: Double(run.lane) - run.lanePosition)
        lionLane += (run.lanePosition - lionLane) * min(1, dt * 3)
        let lionZ = run.phase == .caught ? 2.0 : 4.0 - Double(run.strikes) * 0.5
        lion.root.position = SCNVector3(-0.9 * introWeight + (lionLane - 1) * RoaringRun.laneWidth * (1 - introWeight), 0,
                                       -2.1 * introWeight + lionZ * (1 - introWeight))
        lion.root.eulerAngles.y = Float(-2.65 * introWeight)
        lion.animate(time: time * 1.04, running: moving)
        dust.birthRate = moving && run.jumpHeight < 0.15 && !reduceMotion ? 16 : 0
        gate.isHidden = run.elapsed < 22
        gate.position.z = Float(-max(-3, run.remaining * run.speed - 4))

        let desiredBlend: Float = run.phase == .ready ? 0 : 1
        cameraBlend += (desiredBlend - cameraBlend) * Float(min(1, dt * 3))
        let intro = SIMD3<Float>(1.0, 3.2, 6.5)
        let chase = SIMD3<Float>(Float(x * 0.6), 4.6, 9.4)
        var position = simd_mix(intro, chase, SIMD3(repeating: cameraBlend))
        if !reduceMotion, moving {
            position.y += Float(sin(time * 15) * 0.025)
            cameraNode.camera?.fieldOfView = CGFloat(58 + run.progress * 3)
        } else { cameraNode.camera?.fieldOfView = 58 }
        hitShake = max(0, hitShake - dt)
        if !reduceMotion, hitShake > 0 { position.x += Float(sin(time * 80) * hitShake * 0.2) }
        cameraNode.simdPosition = position
        let introFocus = SIMD3<Float>(0, 0.3, -4)
        let chaseFocus = SIMD3<Float>(Float(x * 0.5), 0.8, -12)
        focus.simdPosition = simd_mix(introFocus, chaseFocus, SIMD3(repeating: cameraBlend))
    }
}
