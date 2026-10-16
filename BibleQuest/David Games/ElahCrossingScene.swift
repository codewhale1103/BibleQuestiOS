import SceneKit
import SwiftUI
import simd

final class ElahCrossingScene {
    let scene = SCNScene()
    let cameraNode = SCNNode()
    private let david = RoaringDavidRig()
    private let focusNode = SCNNode()
    private let waterMaterial = BeastArt.material("#528F91",roughness: 0.23)
    private var reeds: [SCNNode] = []
    private var gusts: [SCNNode] = []
    private var markers: [SCNNode] = []
    private var shimmers: [SCNNode] = []
    var wide = false
    private var cameraBlend = 0.0
    private var breathHalo = SCNNode()
    private let stone = BeastArt.texturedMaterial("#FFF1D4",image: "ElahCrossingStone",scale: 1,roughness: 0.94)
    private let darkStone = BeastArt.texturedMaterial("#C2B99C",image: "RoaringSandstone",scale: 1.4)
    private let gold = BeastArt.material("#EACB87",roughness: 0.5)

    init() {
        scene.background.contents = UIColor.clear
        scene.fogColor = UIColor(Color(hex: "#C4CFBF"))
        scene.fogStartDistance = 26; scene.fogEndDistance = 95; scene.fogDensityExponent = 1.35
        makeLighting(); makeCamera(); makeWater(); makeCrossing(); makeBanks(); makeWind()
        scene.rootNode.addChildNode(david.root)
        let ring = SCNTorus(ringRadius: 0.8,pipeRadius: 0.018); ring.ringSegmentCount = 64; ring.pipeSegmentCount = 8
        let mat = SCNMaterial(); mat.lightingModel = .constant; mat.diffuse.contents = UIColor(Color(hex: "#FCE2A0")); mat.emission.contents = UIColor(Color(hex: "#FCE2A0"))
        ring.materials = [mat]; breathHalo.geometry = ring; breathHalo.opacity = 0
        scene.rootNode.addChildNode(breathHalo)
        update(round: ElahBalanceRound(),time: 0,dt: 0,reduced: false)
    }
    private func center(_ distance: Double) -> Float { Float(sin(distance * 0.10) * 0.9 + sin(distance * 0.27) * 0.3) }
    private func makeCamera() {
        let camera = SCNCamera(); camera.zNear = 0.08; camera.zFar = 150
        camera.fieldOfView = 54; camera.wantsHDR = true; camera.wantsExposureAdaptation = false
        camera.exposureOffset = 0.05; camera.bloomIntensity = 0.21; camera.bloomThreshold = 1.0
        camera.bloomBlurRadius = 6; camera.vignettingIntensity = 0.28; camera.vignettingPower = 1.8
        camera.screenSpaceAmbientOcclusionIntensity = 0.6; camera.screenSpaceAmbientOcclusionRadius = 0.65
        cameraNode.camera = camera; scene.rootNode.addChildNode(cameraNode); scene.rootNode.addChildNode(focusNode)
        let look = SCNLookAtConstraint(target: focusNode); look.isGimbalLockEnabled = true; cameraNode.constraints = [look]
    }
    private func makeLighting() {
        let ambient = SCNNode(); ambient.light = SCNLight(); ambient.light?.type = .ambient
        ambient.light?.color = UIColor(Color(hex: "#D5E9E5")); ambient.light?.intensity = 650; scene.rootNode.addChildNode(ambient)
        let sun = SCNNode(); sun.light = SCNLight(); sun.light?.type = .directional
        sun.light?.color = UIColor(Color(hex: "#FFF0CF")); sun.light?.intensity = 1450
        sun.eulerAngles = SCNVector3(-0.9,-0.6,-0.2)
        sun.light?.castsShadow = true; sun.light?.shadowMode = .deferred
        sun.light?.shadowColor = UIColor(red: 0.18,green: 0.27,blue: 0.27,alpha: 0.38)
        sun.light?.shadowMapSize = CGSize(width: 1536,height: 1536); sun.light?.shadowRadius = 4
        sun.light?.shadowSampleCount = 8; sun.light?.orthographicScale = 16
        scene.rootNode.addChildNode(sun)
    }
    private func makeWater() {
        let plane = SCNPlane(width: 95,height: 145); plane.materials = [waterMaterial]
        waterMaterial.metalness.contents = 0.18
        waterMaterial.shaderModifiers = [.surface: """
        #pragma arguments
        float flowTime;
        #pragma body
        float2 uv = _surface.diffuseTexcoord;
        float ripple = sin(uv.x * 145.0 + uv.y * 42.0 + flowTime * 1.8) * sin(uv.y * 190.0 - flowTime * 1.2);
        float lace = pow(max(0.0, sin(uv.x * 260.0 + sin(uv.y * 90.0 + flowTime) * 2.5 + flowTime * 2.0)), 16.0);
        _surface.diffuse.rgb = mix(float3(0.18,0.39,0.39),float3(0.36,0.60,0.57),0.5 + ripple * 0.22) + lace * 0.10;
        """]
        waterMaterial.setValue(0,forKey: "flowTime")
        let node = SCNNode(geometry: plane); node.eulerAngles.x = -.pi / 2; node.position = SCNVector3(0,-2.0,-40)
        scene.rootNode.addChildNode(node)
        let sparkle = SCNMaterial(); sparkle.lightingModel = .constant; sparkle.diffuse.contents = UIColor(red: 1,green: 0.94,blue: 0.72,alpha: 0.45)
        for index in 0..<42 {
            let shape = SCNPlane(width: 0.08 + Double(index % 4) * 0.05,height: 0.018); shape.materials = [sparkle]
            let p = SCNNode(geometry: shape); p.eulerAngles.x = -.pi / 2
            p.position = SCNVector3(Float(index % 7) * 1.5 - 4.8,-1.985,-Float(index / 7) * 10)
            p.castsShadow = false; shimmers.append(p); scene.rootNode.addChildNode(p)
        }
    }
    private func makeCrossing() {
        let root = SCNNode()
        for index in -8..<121 {
            let distance = Double(index) * 0.68
            let x = center(distance)
            let slab = BeastArt.box(root,SCNVector3(2.08 + sin(Float(index)*2.4)*0.06,0.38,0.65),SCNVector3(x,-0.08,-Float(distance)),stone,bevel: 0.065)
            slab.eulerAngles.y = -Float(cos(distance * 0.1) * 0.09 + cos(distance * 0.27) * 0.08)
            if index % 7 == 0 {
                let support = BeastArt.box(root,SCNVector3(1.25,2.1,0.65),SCNVector3(x,-1.25,-Float(distance)),darkStone,bevel: 0.15)
                support.castsShadow = false
            }
            for side: Float in [-1,1] where index % 2 == 0 {
                BeastArt.box(root,SCNVector3(0.10,0.08,0.36),SCNVector3(x+side*0.99,0.15,-Float(distance)),darkStone,bevel: 0.025)
            }
        }
        scene.rootNode.addChildNode(root.flattenedClone())
        for index in 1...3 { makeMarker(distance: Double(index) * 19.2,index: index) }
        let landing = BeastArt.box(scene.rootNode,SCNVector3(5,0.7,10),SCNVector3(center(58),-0.15,-58),stone,bevel: 0.2)
        landing.castsShadow = false
    }
    private func makeMarker(distance: Double,index: Int) {
        let root = SCNNode(); root.position = SCNVector3(center(distance)+1.75,0.1,-Float(distance))
        for tier in 0..<4 {
            let radius = CGFloat(0.42 - Double(tier) * 0.075)
            let rock = SCNNode(geometry: rockGeometry(seed: index * 7 + tier))
            rock.scale = SCNVector3(radius,0.17,radius); rock.position.y = Float(tier) * 0.26
            root.addChildNode(rock)
        }
        let ring = SCNTorus(ringRadius: 0.22,pipeRadius: 0.022); ring.ringSegmentCount = 40; ring.pipeSegmentCount = 8
        let glow = gold.copy() as! SCNMaterial; glow.emission.contents = UIColor(Color(hex: "#FFE6A6")); glow.emission.intensity = 0.7
        ring.materials = [glow]
        let halo = SCNNode(geometry: ring); halo.position.y = 1.35; halo.eulerAngles.x = .pi / 2; root.addChildNode(halo)
        let orb = SCNSphere(radius: 0.055); orb.segmentCount = 16; orb.materials = [glow]
        halo.addChildNode(SCNNode(geometry: orb))
        markers.append(root); scene.rootNode.addChildNode(root)
    }
    private func rockGeometry(seed: Int) -> SCNGeometry {
        let rows = 9, columns = 14
        var vertices: [SIMD3<Float>] = [], indices: [Int32] = []
        for row in 0...rows {
            let t = Float(row)/Float(rows), a = t * .pi
            for col in 0..<columns {
                let phi = Float(col)/Float(columns) * .pi * 2
                let noise = 1 + 0.13 * sin(phi * 3 + Float(seed)) + 0.08 * cos(phi * 5 + t * 9)
                vertices.append(SIMD3(sin(a) * cos(phi) * noise,cos(a),sin(a) * sin(phi) * noise))
            }
        }
        for row in 0..<rows { for col in 0..<columns {
            let a = Int32(row * columns + col), b = Int32(row * columns + (col+1)%columns), c = a + Int32(columns), d = b + Int32(columns)
            indices += [a,b,c,b,d,c]
        }}
        let temp = SCNNode(); return BeastArt.mesh(temp,vertices: vertices,indices: indices,material: darkStone).geometry!
    }
    private func makeBanks() {
        for side: Float in [-1,1] {
            for index in 0..<20 {
                let distance = Double(index) * 4.5 - 8
                let cluster = SCNNode()
                let x = center(distance) + side * (5.5 + Float(index % 3) * 0.8)
                for layer in 0..<3 {
                    let rock = SCNNode(geometry: rockGeometry(seed: index * 13 + layer))
                    rock.scale = SCNVector3(3.4 + Double(layer)*0.6,1.1 + Double(index%3)*0.25,3.2)
                    rock.position = SCNVector3(x+side*Float(layer)*1.6,-1.3+Float(layer)*0.75,-Float(distance))
                    rock.eulerAngles.y = Float(index)*0.8; rock.castsShadow = false; cluster.addChildNode(rock)
                }
                scene.rootNode.addChildNode(cluster.flattenedClone())
                if index % 2 == 0 { makeOlive(at: SCNVector3(x+side*2,0.65,-Float(distance)),seed: index) }
                for tuft in 0..<2 {
                    let grass = SCNPlane(width: 1.6,height: 1.6)
                    let mat = SCNMaterial(); mat.diffuse.contents = UIImage(named: "ElahRiverReeds"); mat.lightingModel = .physicallyBased
                    mat.isDoubleSided = true; mat.roughness.contents = 1; mat.writesToDepthBuffer = false; mat.transparencyMode = .aOne
                    grass.materials = [mat]
                    let node = SCNNode(geometry: grass); node.position = SCNVector3(x-side*1.6,0.5,-Float(distance)-Float(tuft)*1.4)
                    let face = SCNBillboardConstraint(); face.freeAxes = .Y; node.constraints = [face]
                    node.castsShadow = false; reeds.append(node); scene.rootNode.addChildNode(node)
                }
            }
        }
    }
    private func makeOlive(at position: SCNVector3,seed: Int) {
        let shape = SCNPlane(width: 4.3,height: 4.3)
        let material = SCNMaterial(); material.diffuse.contents = UIImage(named: "ElahOliveTree")
        material.lightingModel = .constant; material.isDoubleSided = true
        material.writesToDepthBuffer = false; material.transparencyMode = .aOne
        shape.materials = [material]
        let root = SCNNode(geometry: shape); root.position = position
        root.position.y += 1.8
        let face = SCNBillboardConstraint(); face.freeAxes = .Y; root.constraints = [face]
        root.castsShadow = false; scene.rootNode.addChildNode(root)
    }

    private func makeWind() {
        let material = SCNMaterial(); material.lightingModel = .constant
        material.diffuse.contents = UIColor(red: 0.92,green: 0.99,blue: 0.94,alpha: 0.65)
        material.isDoubleSided = true; material.writesToDepthBuffer = false
        for index in 0..<22 {
            let plane = SCNPlane(width: 0.4 + Double(index%4)*0.18,height: 0.009)
            plane.materials = [material]
            let node = SCNNode(geometry: plane); node.constraints = [SCNBillboardConstraint()]
            node.castsShadow = false; gusts.append(node); scene.rootNode.addChildNode(node)
        }
    }
    func reset() { cameraBlend = 0 }
    func update(round: ElahBalanceRound,time: Double,dt: Double,reduced: Bool) {
        let active = round.phase != .intro
        cameraBlend = active ? min(1,cameraBlend + dt * 0.65) : 0
        if reduced { cameraBlend = active ? 1 : 0 }
        let blend = cameraBlend * cameraBlend * (3-2*cameraBlend)
        let distance = round.phase == .intro ? 0 : round.distance
        let z = -Float(distance), x = center(distance)
        let lean = round.offset
        david.root.isHidden = !active
        david.root.position = SCNVector3(x+Float(lean*0.82),0.12,z)
        david.root.eulerAngles.y = 0
        if round.phase == .falling || round.phase == .lost {
            let p = min(1,round.fallElapsed/0.9)
            david.root.position.y -= Float(p*p*0.9)
            david.root.eulerAngles.z = Float(-max(-1,min(1,lean)) * p * 0.95)
        } else { david.root.eulerAngles.z = 0 }
        david.balance(time: time,walking: round.phase == .walking,lean: lean,wind: round.wind,calm: round.calmRemaining > 0,reduced: reduced)
        let orbit = (1-blend) * 0.65 + blend * 0.04
        let radius = 5.8 + blend * 0.6
        cameraNode.camera?.fieldOfView = wide ? 48 : 54
        let framing: Float = wide ? -1.5 : 0
        cameraNode.position = SCNVector3(x+framing+Float(sin(orbit)*radius),Float(2.6+blend*1.2),z+Float(cos(orbit)*radius))
        focusNode.position = SCNVector3(center(distance+blend*3)+framing,Float(1.0-blend*0.35),z-Float(blend*3))
        waterMaterial.setValue(time,forKey: "flowTime")
        for (index,node) in shimmers.enumerated() { node.opacity = reduced ? 0.22 : CGFloat(max(0,sin(time*1.7+Double(index)*2.1))*0.7) }
        for (index,node) in reeds.enumerated() { node.eulerAngles.z = reduced ? 0 : Float(sin(time*2.4+Double(index))*0.035+round.wind*0.08) }
        for (index,node) in gusts.enumerated() {
            let direction = round.wind == 0 ? round.gustDirection : (round.wind > 0 ? 1.0 : -1.0)
            let t = (time * 0.65 + Double(index)*0.137).truncatingRemainder(dividingBy: 1)
            node.position = SCNVector3(x+Float((t-0.5)*15*direction),Float(0.5+Double(index%5)*0.45),z-Float(2+index%8))
            node.opacity = reduced ? 0 : CGFloat(abs(round.wind) * sin(t * .pi) * (round.calmRemaining > 0 ? 0.10 : 0.42))
        }
        for (index,node) in markers.enumerated() {
            if let halo = node.childNodes.last {
                halo.eulerAngles.y = reduced ? 0 : Float(time*0.5)
                halo.position.y = 1.35 + (reduced ? 0 : Float(sin(time*1.8+Double(index))*0.08))
                halo.opacity = index < round.checkpoint || round.phase == .won ? 1 : 0.62
            }
        }
        breathHalo.position = SCNVector3(x,0.18,z)
        let pulse = reduced ? 1 : 1 + sin(time*2.8)*0.12
        breathHalo.scale = SCNVector3(pulse,1,pulse)
        breathHalo.opacity = round.calmRemaining > 0 ? 0.85 : 0
    }
}
