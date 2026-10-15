import SwiftUI
import SceneKit
import UIKit
import simd

/// Small, reusable mesh tools. All characters are real, lit 3D geometry.
enum BeastArt {
    static func material(_ hex: String, roughness: CGFloat = 0.88) -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(Color(hex: hex))
        material.roughness.contents = roughness
        material.metalness.contents = 0
        material.lightingModel = .physicallyBased
        return material
    }
    static func texturedMaterial(_ hex: String, image: String, scale: Float, roughness: CGFloat = 0.88) -> SCNMaterial {
        let result = material(hex, roughness: roughness)
        if let texture = UIImage(named: image) {
            result.diffuse.contents = texture
            result.multiply.contents = UIColor(Color(hex: hex))
            result.diffuse.wrapS = .repeat; result.diffuse.wrapT = .repeat
            result.diffuse.contentsTransform = SCNMatrix4MakeScale(scale, scale, 1)
        }
        return result
    }
    @discardableResult static func ellipsoid(_ parent: SCNNode, _ radius: CGFloat,
                                             _ scale: SCNVector3, _ position: SCNVector3,
                                             _ material: SCNMaterial) -> SCNNode {
        let sphere = SCNSphere(radius: radius)
        sphere.segmentCount = 28
        sphere.materials = [material]
        let node = SCNNode(geometry: sphere)
        node.scale = scale; node.position = position
        parent.addChildNode(node)
        return node
    }
    @discardableResult static func box(_ parent: SCNNode, _ size: SCNVector3,
                                      _ position: SCNVector3, _ material: SCNMaterial,
                                      bevel: CGFloat = 0.04) -> SCNNode {
        let shape = SCNBox(width: CGFloat(size.x), height: CGFloat(size.y), length: CGFloat(size.z), chamferRadius: bevel)
        shape.materials = [material]
        let node = SCNNode(geometry: shape); node.position = position
        parent.addChildNode(node)
        return node
    }
    @discardableResult static func limb(_ parent: SCNNode, length: CGFloat, radius: CGFloat,
                     at position: SCNVector3, material: SCNMaterial) -> SCNNode {
        let pivot = SCNNode(); pivot.position = position; parent.addChildNode(pivot)
        let capsule = SCNCapsule(capRadius: radius, height: length)
        capsule.radialSegmentCount = 16; capsule.heightSegmentCount = 2
        capsule.materials = [material]
        let mesh = SCNNode(geometry: capsule); mesh.position.y = -Float(length) / 2
        pivot.addChildNode(mesh)
        return pivot
    }

    @discardableResult static func mesh(_ parent: SCNNode, vertices: [SIMD3<Float>], indices: [Int32],
                                         material: SCNMaterial, uv: [CGPoint]? = nil) -> SCNNode {
        var normals = Array(repeating: SIMD3<Float>(repeating: 0), count: vertices.count)
        for index in stride(from: 0, to: indices.count, by: 3) {
            let a = Int(indices[index]), b = Int(indices[index + 1]), c = Int(indices[index + 2])
            let normal = simd_cross(vertices[b] - vertices[a], vertices[c] - vertices[a])
            normals[a] += normal; normals[b] += normal; normals[c] += normal
        }
        let sources = [SCNGeometrySource(vertices: vertices.map(SCNVector3.init)),
                       SCNGeometrySource(normals: normals.map { SCNVector3(simd_length_squared($0) > 0.00000001 ? simd_normalize($0) : SIMD3(0, 1, 0)) }),
                       SCNGeometrySource(textureCoordinates: uv ?? vertices.map { CGPoint(x: CGFloat($0.x * 2 + $0.z), y: CGFloat($0.y * 2)) })]
        let geometry = SCNGeometry(sources: sources, elements: [SCNGeometryElement(indices: indices, primitiveType: .triangles)])
        geometry.materials = [material]
        let node = SCNNode(geometry: geometry); parent.addChildNode(node)
        return node
    }

    /// Smooth, tapered elliptical sweep, used for carved hair, fur and curved leather cords.
    @discardableResult static func sweep(_ parent: SCNNode, _ controls: [SIMD3<Float>],
                                          radius: Float, depth: Float = 1, pointed: Bool = false,
                                          material: SCNMaterial, sides: Int = 10, steps: Int = 20) -> SCNNode {
        precondition(controls.count == 4)
        func point(_ t: Float) -> SIMD3<Float> {
            let a = 1 - t
            return controls[0] * (a * a * a) + controls[1] * (3 * a * a * t)
                + controls[2] * (3 * a * t * t) + controls[3] * (t * t * t)
        }
        var vertices: [SIMD3<Float>] = [], indices: [Int32] = [], uv: [CGPoint] = []
        var previousRight: SIMD3<Float>?
        for row in 0...steps {
            let t = Float(row) / Float(steps)
            let p = point(t)
            let tangent = simd_normalize(point(min(1, t + 0.002)) - point(max(0, t - 0.002)))
            let reference = abs(tangent.z) > 0.92 ? SIMD3<Float>(0, 1, 0) : SIMD3<Float>(0, 0, 1)
            // Parallel transport keeps the cross-section continuous around tight curves.
            let right = previousRight.map { simd_normalize($0 - tangent * simd_dot($0, tangent)) }
                ?? simd_normalize(simd_cross(tangent, reference))
            previousRight = right
            let up = simd_cross(tangent, right)
            let profile: Float = pointed ? max(0.012, pow(1 - t, 0.65) * (0.62 + 0.75 * sin(t * .pi))) : 1
            for side in 0..<sides {
                let angle = Float(side) * .pi * 2 / Float(sides)
                vertices.append(p + (right * cos(angle) + up * sin(angle) * depth) * radius * profile)
                uv.append(CGPoint(x: CGFloat(side) / CGFloat(sides), y: CGFloat(t)))
            }
        }
        for row in 0..<steps {
            for side in 0..<sides {
                let a = Int32(row * sides + side), b = Int32(row * sides + (side + 1) % sides)
                let c = a + Int32(sides), d = b + Int32(sides)
                indices += [a, b, c, b, d, c]
            }
        }
        return mesh(parent, vertices: vertices, indices: indices, material: material, uv: uv)
    }

    /// Elliptical cloth rings with modeled pleats; no cone-shaped costume placeholders.
    @discardableResult static func garment(_ parent: SCNNode, rings: [(Float, Float, Float)],
                                            folds: Float, material: SCNMaterial) -> SCNNode {
        let sides = 48
        var vertices: [SIMD3<Float>] = [], indices: [Int32] = []
        for (row, ring) in rings.enumerated() {
            for side in 0..<sides {
                let angle = Float(side) * .pi * 2 / Float(sides)
                let ripple = folds * sin(angle * 10 + Float(row) * 0.2)
                let hem = row == rings.count - 1 ? sin(angle * 5 + 0.8) * 0.012 : 0
                vertices.append(SIMD3((ring.1 + ripple) * cos(angle), ring.0 + hem, (ring.2 + ripple) * sin(angle)))
            }
        }
        for row in 0..<(rings.count - 1) {
            for side in 0..<sides {
                let a = Int32(row * sides + side), b = Int32(row * sides + (side + 1) % sides)
                let c = a + Int32(sides), d = b + Int32(sides)
                indices += [a, b, c, b, d, c]
            }
        }
        return mesh(parent, vertices: vertices, indices: indices, material: material)
    }
}

final class RoaringDavidRig {
    let root = SCNNode()
    private let body = SCNNode()
    private let head = SCNNode()
    private var arms: [SCNNode] = []
    private var legs: [SCNNode] = []
    private var knees: [SCNNode] = []
    private let cloak = SCNNode()
    private var tassels: [SCNNode] = []

    init() {
        let skin = BeastArt.material("#EFB58F", roughness: 0.82)
        let warmSkin = BeastArt.material("#CA7B57", roughness: 0.72)
        let linen = BeastArt.texturedMaterial("#FFF0C6", image: "RoaringLinen", scale: 3)
        let seam = BeastArt.material("#C6AD7A")
        let burgundy = BeastArt.texturedMaterial("#8E4B62", image: "RoaringLinen", scale: 3, roughness: 0.94)
        let cloakLight = BeastArt.material("#9D5865")
        let leather = BeastArt.material("#70402B", roughness: 0.67)
        let leatherEdge = BeastArt.material("#AF7747", roughness: 0.62)
        let rope = BeastArt.material("#C49B5D")
        let ropeShade = BeastArt.material("#947039")
        root.addChildNode(body)

        BeastArt.garment(body, rings: [(1.34, 0.13, 0.12), (1.29, 0.245, 0.17), (1.16, 0.26, 0.18),
                                       (1.01, 0.225, 0.175), (0.94, 0.24, 0.18), (0.8, 0.30, 0.205),
                                       (0.65, 0.335, 0.235)], folds: 0.009, material: linen)
        // Split collar, stitched hem, and the reference's diagonal wine-colored wrap.
        BeastArt.sweep(body, [SIMD3(-0.09, 1.325, -0.085), SIMD3(-0.11, 1.29, -0.15), SIMD3(-0.025, 1.24, -0.19), SIMD3(0, 1.16, -0.19)], radius: 0.009, material: seam)
        BeastArt.sweep(body, [SIMD3(0.09, 1.325, -0.085), SIMD3(0.11, 1.29, -0.15), SIMD3(0.025, 1.24, -0.19), SIMD3(0, 1.16, -0.19)], radius: 0.009, material: seam)
        for side: Float in [-1, 1] {
            BeastArt.sweep(body, [SIMD3(side * 0.025, 0.65, -0.238), SIMD3(side * 0.04, 0.71, -0.233), SIMD3(side * 0.045, 0.76, -0.22), SIMD3(side * 0.035, 0.81, -0.21)], radius: 0.006, material: seam)
        }
        makeSash(material: burgundy, edge: cloakLight)
        makeCloak(material: burgundy, edge: cloakLight)
        // Double twisted rope belt follows the waist all the way around.
        for winding in 0..<2 {
            var points: [SIMD3<Float>] = []
            for i in 0...96 {
                let t = Float(i) / 96 * .pi * 2
                let twist = t * 19 + Float(winding) * .pi
                points.append(SIMD3((0.25 + cos(twist) * 0.011) * cos(t), 0.965 + sin(twist) * 0.011, (0.194 + cos(twist) * 0.011) * sin(t)))
            }
            addPolyline(points, radius: 0.013, parent: body, material: winding == 0 ? rope : ropeShade)
        }
        for side: Float in [-1, 1] {
            let tassel = SCNNode(); tassel.position = SCNVector3(side * 0.04, 0.966, -0.206); body.addChildNode(tassel)
            let end = SIMD3<Float>(side * 0.035, side < 0 ? -0.25 : -0.34, -0.035)
            for strand in 0..<2 {
                let offset = Float(strand) * 0.009
                BeastArt.sweep(tassel, [SIMD3(offset, 0, 0), SIMD3(-0.025, -0.08, -0.055), SIMD3(end.x + offset, end.y + 0.07, -0.035), end + SIMD3(offset, 0, 0)], radius: 0.011, material: strand == 0 ? rope : ropeShade)
            }
            for i in 0..<4 {
                BeastArt.sweep(tassel, [end, end + SIMD3(0, -0.01, 0), end + SIMD3(Float(i - 2) * 0.009, -0.026, 0), end + SIMD3(Float(i - 2) * 0.009, -0.04, 0.008)], radius: 0.004, pointed: true, material: rope)
            }
            tassels.append(tassel)
        }
        BeastArt.ellipsoid(body, 0.105, SCNVector3(0.85, 1.1, 0.88), SCNVector3(0, 1.38, 0), skin)
        head.position = SCNVector3(0, 1.655, -0.006); body.addChildNode(head)
        RoaringPortraits.davidFace(on: head, skin: skin)
        RoaringPortraits.davidHair(on: head)

        for side: Float in [-1, 1] {
            let arm = SCNNode(); arm.position = SCNVector3(side * 0.268, 1.255, 0); body.addChildNode(arm)
            arm.eulerAngles.z = side * 0.13
            BeastArt.garment(arm, rings: [(0.045, 0.092, 0.105), (-0.06, 0.105, 0.105), (-0.17, 0.115, 0.11)], folds: 0.004, material: linen)
            BeastArt.limb(arm, length: 0.23, radius: 0.073, at: SCNVector3(0, -0.085, 0), material: skin)
            let elbow = BeastArt.limb(arm, length: 0.245, radius: 0.06, at: SCNVector3(0, -0.265, 0), material: skin)
            elbow.eulerAngles.x = -0.72
            BeastArt.garment(elbow, rings: [(-0.12, 0.065, 0.061), (-0.14, 0.068, 0.063), (-0.215, 0.059, 0.056), (-0.23, 0.058, 0.055)], folds: 0, material: leather)
            for y: Float in [-0.14, -0.213] {
                let trim = SCNTorus(ringRadius: y == -0.14 ? 0.065 : 0.057, pipeRadius: 0.007)
                trim.ringSegmentCount = 20; trim.pipeSegmentCount = 6; trim.materials = [leatherEdge]
                let node = SCNNode(geometry: trim); node.position.y = y; elbow.addChildNode(node)
            }
            BeastArt.ellipsoid(elbow, 0.073, SCNVector3(0.83, 1.03, 0.72), SCNVector3(0, -0.27, -0.008), skin)
            BeastArt.ellipsoid(elbow, 0.029, SCNVector3(0.8, 1.35, 0.85), SCNVector3(-side * 0.052, -0.257, -0.025), skin)
            for finger in 0..<3 {
                BeastArt.sweep(elbow, [SIMD3(-0.035 + Float(finger) * 0.025, -0.285, -0.052), SIMD3(-0.035 + Float(finger) * 0.025, -0.3, -0.062), SIMD3(-0.035 + Float(finger) * 0.025, -0.315, -0.04), SIMD3(-0.035 + Float(finger) * 0.025, -0.32, -0.02)], radius: 0.004, material: warmSkin, steps: 8)
            }
            if side > 0 { makeSling(parent: elbow, leather: leather, cord: rope) }
            arms.append(arm)

            let leg = BeastArt.limb(body, length: 0.32, radius: 0.087, at: SCNVector3(side * 0.145, 0.72, 0), material: skin)
            let knee = BeastArt.limb(leg, length: 0.32, radius: 0.068, at: SCNVector3(0, -0.295, 0), material: skin)
            BeastArt.ellipsoid(knee, 0.082, SCNVector3(0.95, 0.69, 1.57), SCNVector3(0, -0.291, -0.052), skin)
            BeastArt.box(knee, SCNVector3(0.17, 0.037, 0.285), SCNVector3(0, -0.35, -0.055), leather, bevel: 0.017)
            BeastArt.box(knee, SCNVector3(0.175, 0.013, 0.285), SCNVector3(0, -0.327, -0.055), leatherEdge, bevel: 0.006)
            for toe in 0..<4 {
                BeastArt.ellipsoid(knee, 0.024, SCNVector3(0.82, 0.7, 1.1), SCNVector3(-0.054 + Float(toe) * 0.035, -0.303, -0.178 + Float(toe) * 0.005), skin)
            }
            for offset: Float in [-0.008, 0.058] {
                BeastArt.sweep(knee, [SIMD3(-0.081, -0.317, -0.13 + offset), SIMD3(-0.06, -0.245, -0.14 + offset), SIMD3(0.06, -0.245, -0.07 + offset), SIMD3(0.081, -0.317, -0.08 + offset)], radius: 0.018, depth: 0.48, material: leather)
            }
            BeastArt.garment(knee, rings: [(-0.201, 0.071, 0.069), (-0.244, 0.068, 0.066)], folds: 0, material: leather)
            BeastArt.box(knee, SCNVector3(0.028, 0.025, 0.014), SCNVector3(side * 0.051, -0.22, -0.057), leatherEdge, bevel: 0.004)
            legs.append(leg); knees.append(knee)
        }
    }

    private func makeSash(material: SCNMaterial, edge: SCNMaterial) {
        let columns = 12, rows = 18
        var vertices: [SIMD3<Float>] = [], indices: [Int32] = []
        for row in 0...rows {
            let t = Float(row) / Float(rows)
            for column in 0...columns {
                let u = Float(column) / Float(columns) - 0.5
                let x = -0.225 + t * 0.435 + u * 0.205
                let y = 1.31 - t * 0.34 + u * 0.2
                let z = -0.15 - sin(t * .pi) * 0.072 - cos(u * .pi * 6) * 0.009
                vertices.append(SIMD3(x,y,z))
            }
        }
        for row in 0..<rows { for column in 0..<columns {
            let a = Int32(row * (columns + 1) + column), b = a + 1, c = a + Int32(columns + 1), d = c + 1
            indices += [a,c,b,b,c,d]
        }}
        let mat = material.copy() as! SCNMaterial; mat.isDoubleSided = true
        BeastArt.mesh(body, vertices: vertices, indices: indices, material: mat)
        for side: Float in [-1, 1] {
            BeastArt.sweep(body, [SIMD3(-0.225 + side * 0.102, 1.31 + side * 0.1, -0.158), SIMD3(-0.08 + side * 0.102, 1.2 + side * 0.1, -0.225), SIMD3(0.06 + side * 0.102, 1.09 + side * 0.1, -0.225), SIMD3(0.21 + side * 0.102, 0.97 + side * 0.1, -0.158)], radius: 0.006, material: edge)
        }
    }

    private func makeCloak(material: SCNMaterial, edge: SCNMaterial) {
        cloak.position = SCNVector3(-0.10, 1.31, 0.135); body.addChildNode(cloak)
        let rows = 24, columns = 20
        var vertices: [SIMD3<Float>] = [], indices: [Int32] = []
        for row in 0...rows {
            let t = Float(row) / Float(rows)
            for column in 0...columns {
                let u = Float(column) / Float(columns) - 0.5
                let width = 0.36 + t * 0.22
                let x = u * width - t * 0.07
                let y = -t * 0.88 + sin(u * .pi * 7) * pow(t, 8) * 0.035
                let z = 0.055 + sin(t * .pi * 0.7) * 0.095 + sin(u * .pi * 8 + t * 1.5) * (0.012 + t * 0.025)
                vertices.append(SIMD3(x,y,z))
            }
        }
        for row in 0..<rows { for column in 0..<columns {
            let a = Int32(row * (columns + 1) + column), b = a + 1, c = a + Int32(columns + 1), d = c + 1
            indices += [a,b,c,b,d,c]
        }}
        let mat = material.copy() as! SCNMaterial; mat.isDoubleSided = true
        BeastArt.mesh(cloak, vertices: vertices, indices: indices, material: mat)
        for side: Float in [-1, 1] {
            BeastArt.sweep(cloak, [SIMD3(side * 0.18,0,0.055), SIMD3(side * 0.22 - 0.02,-0.3,0.1), SIMD3(side * 0.27 - 0.05,-0.6,0.14), SIMD3(side * 0.29 - 0.07,-0.88,0.14)], radius: 0.006, material: edge)
        }
    }

    private func makeSling(parent: SCNNode, leather: SCNMaterial, cord: SCNMaterial) {
        let sling = SCNNode(); sling.position = SCNVector3(0.02, -0.3, -0.02); parent.addChildNode(sling)
        BeastArt.sweep(sling, [SIMD3(0,0,0), SIMD3(0.19,-0.12,-0.03), SIMD3(0.21,-0.27,0), SIMD3(0.08,-0.34,0.015)], radius: 0.011, material: cord)
        BeastArt.sweep(sling, [SIMD3(0,0,0), SIMD3(-0.05,-0.13,0.02), SIMD3(-0.03,-0.27,0.02), SIMD3(0.08,-0.34,0.015)], radius: 0.009, material: cord)
        BeastArt.ellipsoid(sling, 0.052, SCNVector3(1,0.5,0.4), SCNVector3(0.08,-0.34,0.015), leather)
    }

    private func addPolyline(_ points: [SIMD3<Float>], radius: Float, parent: SCNNode, material: SCNMaterial) {
        // One continuous tube for each rope strand, rather than a node per twist.
        let sides = 6
        var vertices: [SIMD3<Float>] = [], indices: [Int32] = []
        for index in points.indices {
            let tangent = simd_normalize(points[min(index + 1, points.count - 1)] - points[max(0,index - 1)])
            let right = simd_normalize(simd_cross(tangent, SIMD3<Float>(0,1,0)))
            let up = simd_cross(tangent,right)
            for side in 0..<sides {
                let a = Float(side) / Float(sides) * .pi * 2
                vertices.append(points[index] + radius * (right * cos(a) + up * sin(a)))
            }
        }
        for row in 0..<(points.count - 1) { for side in 0..<sides {
            let a = Int32(row * sides + side), b = Int32(row * sides + (side + 1) % sides), c = a + Int32(sides), d = b + Int32(sides)
            indices += [a,b,c,b,d,c]
        }}
        BeastArt.mesh(parent, vertices: vertices, indices: indices, material: material)
    }

    func animate(time: Double, jump: Double, running: Bool, lean: Double) {
        let stride = running ? sin(time * 15) : sin(time * 2) * 0.06
        body.position.y = Float(running ? abs(sin(time * 15)) * 0.045 : sin(time * 2) * 0.012)
        body.eulerAngles.z = Float(-lean * 0.1)
        body.eulerAngles.x = running ? -0.08 : 0
        head.eulerAngles.y = Float(running ? sin(time * 1.8) * 0.045 : -0.02 + sin(time * 0.8) * 0.035)
        for index in 0..<2 {
            let sign: Double = index == 0 ? 1 : -1
            legs[index].eulerAngles.x = Float(jump > 0.1 ? 0.48 * sign : stride * 0.77 * sign)
            knees[index].eulerAngles.x = Float(jump > 0.1 ? 0.65 : max(0, -stride * sign) * 1.05)
            arms[index].eulerAngles.x = Float(jump > 0.1 ? -1.1 : -stride * 0.78 * sign)
            tassels[index].eulerAngles.x = Float(sin(time * 12 + sign) * (running ? 0.35 : 0.04))
        }
        cloak.eulerAngles.x = Float((running ? -0.63 : -0.06) + sin(time * (running ? 13 : 3)) * (running ? 0.12 : 0.035))
        cloak.eulerAngles.z = Float(sin(time * 6) * (running ? 0.08 : 0.02) + lean * 0.12)
    }
}

final class RoaringLionRig {
    let root = SCNNode()
    private let body = SCNNode()
    private let head = SCNNode()
    private let tail = SCNNode()
    private var legs: [SCNNode] = []
    private var ankles: [SCNNode] = []
    init() {
        let gold = BeastArt.texturedMaterial("#D8A963", image: "RoaringFur", scale: 2, roughness: 0.79)
        let shoulder = BeastArt.texturedMaterial("#E2B570", image: "RoaringFur", scale: 2, roughness: 0.8)
        let mane = BeastArt.texturedMaterial("#71462E", image: "RoaringFur", scale: 1, roughness: 0.86)
        let maneMid = BeastArt.texturedMaterial("#7D4F32", image: "RoaringFur", scale: 1, roughness: 0.83)
        let maneLight = BeastArt.texturedMaterial("#8A5937", image: "RoaringFur", scale: 1, roughness: 0.8)
        let dark = BeastArt.material("#35251E", roughness: 0.48)
        root.addChildNode(body)
        // Long rib cage, tucked abdomen, distinct shoulder blades and rear haunches.
        makeTorso(material: gold)
        for side: Float in [-1,1] {
            BeastArt.ellipsoid(body, 0.28, SCNVector3(0.59,1.34,1.09), SCNVector3(side * 0.285,0.98,-0.38), shoulder)
            BeastArt.ellipsoid(body, 0.29, SCNVector3(0.68,1.22,1.12), SCNVector3(side * 0.26,0.88,0.71), gold)
        }
        head.position = SCNVector3(0,1.24,-0.83); body.addChildNode(head)
        // A close, layered mane swept backward along the neck, with sharp overlapping tips.
        BeastArt.ellipsoid(head, 0.46, SCNVector3(0.94,1.16,0.98), SCNVector3(0,-0.055,0.07), mane)
        for layer in 0..<3 {
            let count = layer == 0 ? 18 : 22
            for index in 0..<count {
                let a = Float(index) / Float(count) * .pi * 2 + Float(layer) * 0.17
                let rx: Float = layer == 0 ? 0.31 : (layer == 1 ? 0.375 : 0.34)
                let ry: Float = layer == 0 ? 0.35 : (layer == 1 ? 0.415 : 0.39)
                let z = Float(layer) * 0.155 - 0.17
                let root = SIMD3<Float>(sin(a) * rx, cos(a) * ry - 0.025, z)
                let spread: Float = 1.13
                let tip = SIMD3<Float>(sin(a) * rx * spread, cos(a) * ry * spread - 0.17, z + 0.29)
                let control1 = root + SIMD3<Float>(sin(a) * 0.065, cos(a) * 0.05, 0.065)
                let control2 = tip + SIMD3<Float>(sin(a) * 0.025, cos(a) * 0.025, -0.11)
                let mat = (index + layer) % 5 == 0 ? maneLight : (index.isMultiple(of: 2) ? mane : maneMid)
                BeastArt.sweep(head, [root,control1,control2,tip], radius: layer == 0 ? 0.071 : 0.084, depth: 0.44, pointed: true, material: mat, sides: 8, steps: 14)
            }
        }
        RoaringPortraits.lionFace(on: head, fur: gold, mane: mane)
        for front in [true,false] {
            for side: Float in [-1,1] {
                let leg = SCNNode(); leg.position = SCNVector3(side * 0.31,0.91,front ? -0.45 : 0.71); body.addChildNode(leg)
                BeastArt.ellipsoid(leg, 0.19, SCNVector3(0.72,1.5,0.94), SCNVector3(0,-0.15,front ? 0 : -0.06), gold)
                let ankle = SCNNode(); ankle.position = SCNVector3(0,-0.38,front ? 0.035 : -0.11); leg.addChildNode(ankle)
                BeastArt.garment(ankle, rings: [(0.04,0.105,0.104),(-0.13,0.077,0.08),(-0.30,0.065,0.07),(-0.41,0.086,0.11)], folds: 0, material: gold)
                BeastArt.ellipsoid(ankle, 0.145, SCNVector3(0.94,0.61,1.42), SCNVector3(0,-0.415,-0.075), shoulder)
                for toe in 0..<3 {
                    BeastArt.ellipsoid(ankle, 0.055, SCNVector3(0.88,0.91,1.15), SCNVector3(Float(toe - 1) * 0.075,-0.427,-0.196), gold)
                    BeastArt.sweep(ankle, [SIMD3(Float(toe - 1) * 0.075,-0.433,-0.233), SIMD3(Float(toe - 1) * 0.075,-0.439,-0.254), SIMD3(Float(toe - 1) * 0.075,-0.458,-0.264), SIMD3(Float(toe - 1) * 0.075,-0.471,-0.258)], radius: 0.012, pointed: true, material: dark, steps: 8)
                }
                legs.append(leg); ankles.append(ankle)
            }
        }
        tail.position = SCNVector3(0,1.03,0.97); body.addChildNode(tail)
        BeastArt.sweep(tail, [SIMD3(0,0,0),SIMD3(0.19,0.09,0.4),SIMD3(0.3,0.55,0.81),SIMD3(0.13,0.64,0.88)], radius: 0.04, depth: 1, material: gold, steps: 28)
        for index in 0..<7 {
            let a = Float(index) / 7 * .pi * 2
            BeastArt.sweep(tail, [SIMD3(0.13,0.64,0.86),SIMD3(0.13 + sin(a) * 0.06,0.7,0.91),SIMD3(0.12 + sin(a) * 0.055,0.71 + cos(a) * 0.05,1.02),SIMD3(0.1,0.67,1.1)], radius: 0.06, depth: 0.7, pointed: true, material: index.isMultiple(of: 2) ? mane : maneMid, steps: 12)
        }
    }
    private func makeTorso(material: SCNMaterial) {
        // A continuous spline loft joins the shoulders, tucked abdomen and haunches.
        // Its silhouette has no intersecting sphere seams, including from the chase camera.
        let rings: [SIMD4<Float>] = [
            SIMD4(-0.76,1.02,0.08,0.15), SIMD4(-0.58,1.02,0.30,0.39),
            SIMD4(-0.35,1.03,0.38,0.455), SIMD4(-0.10,1.0,0.36,0.41),
            SIMD4(0.18,0.99,0.31,0.33), SIMD4(0.42,1.0,0.28,0.28),
            SIMD4(0.68,0.96,0.32,0.33), SIMD4(0.86,0.94,0.285,0.31),
            SIMD4(1.02,0.95,0.15,0.23), SIMD4(1.09,0.96,0.008,0.03)
        ]
        let rows = 72, sides = 40
        var vertices: [SIMD3<Float>] = [], indices: [Int32] = [], uv: [CGPoint] = []
        for row in 0...rows {
            let progress = Float(row) / Float(rows) * Float(rings.count - 1)
            let index = min(rings.count - 2, Int(progress)), t = progress - Float(index)
            let a = rings[max(0,index - 1)], b = rings[index], c = rings[index + 1], d = rings[min(rings.count - 1,index + 2)]
            let constant: SIMD4<Float> = b * Float(2)
            let linear: SIMD4<Float> = (c - a) * t
            var quadraticCoefficient: SIMD4<Float> = a * Float(2)
            quadraticCoefficient -= b * Float(5)
            quadraticCoefficient += c * Float(4)
            quadraticCoefficient -= d
            var cubicCoefficient: SIMD4<Float> = -a
            cubicCoefficient += b * Float(3)
            cubicCoefficient -= c * Float(3)
            cubicCoefficient += d
            let quadratic = quadraticCoefficient * (t * t)
            let cubic = cubicCoefficient * (t * t * t)
            let p: SIMD4<Float> = (constant + linear + quadratic + cubic) * Float(0.5)
            for side in 0..<sides {
                let angle = Float(side) / Float(sides) * .pi * 2
                vertices.append(SIMD3(cos(angle) * p.z,p.y + sin(angle) * p.w,p.x))
                uv.append(CGPoint(x: CGFloat(side) / CGFloat(sides), y: CGFloat(row) / CGFloat(rows) * 2))
            }
        }
        for row in 0..<rows { for side in 0..<sides {
            let a = Int32(row * sides + side), b = Int32(row * sides + (side + 1) % sides), c = a + Int32(sides), d = b + Int32(sides)
            indices += [a,b,c,b,d,c]
        }}
        BeastArt.mesh(body, vertices: vertices, indices: indices, material: material, uv: uv)
    }
    func animate(time: Double, running: Bool) {
        let stride = running ? sin(time * 13) : sin(time * 2) * 0.035
        body.position.y = Float(running ? sin(time * 26) * 0.035 : sin(time * 2) * 0.013)
        body.eulerAngles.x = Float(running ? cos(time * 13) * 0.035 : 0)
        for (index, leg) in legs.enumerated() {
            let phase = (index == 0 || index == 3) ? 1.0 : -1.0
            leg.eulerAngles.x = Float(stride * phase * 0.62)
            ankles[index].eulerAngles.x = Float(max(0,-stride * phase) * 0.85)
        }
        head.eulerAngles.y = Float(sin(time * 2.3) * 0.045)
        head.eulerAngles.x = Float(running ? sin(time * 13 + 0.3) * 0.04 : sin(time * 1.7) * 0.015)
        tail.eulerAngles.z = Float(sin(time * 4) * 0.26)
        tail.eulerAngles.y = Float(sin(time * 3) * 0.22)
    }
}
