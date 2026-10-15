import SceneKit
import UIKit
import simd

/// Painted facial features sit on a continuous, sculpted head surface. Eyes, blush,
/// lips and whisker pads share its UVs, avoiding floating facial parts and hard seams.
enum RoaringPortraits {
    private static func portraitMaterial(_ name: String, fallback: SCNMaterial) -> SCNMaterial {
        guard let image = UIImage(named: name) else { return fallback }
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.diffuse.contents = image
        material.diffuse.magnificationFilter = .linear
        material.diffuse.minificationFilter = .linear
        material.diffuse.mipFilter = .linear
        material.roughness.contents = 0.86
        material.metalness.contents = 0
        // A small ambient contribution preserves the painted color in the canyon shade.
        material.emission.contents = image
        material.emission.intensity = 0.12
        return material
    }

    static func davidFace(on parent: SCNNode, skin: SCNMaterial) {
        let material = portraitMaterial("RoaringDavidFace", fallback: skin)
        sculptHead(on: parent, radius: SIMD3(0.3, 0.335, 0.26), textureSize: SIMD2(0.64, 0.72),
                   face: material, back: skin, lion: false)
        let inner = BeastArt.material("#D78F76", roughness: 0.9)
        for side: Float in [-1, 1] {
            let ear = BeastArt.ellipsoid(parent, 0.077, SCNVector3(0.60, 1.04, 0.57),
                                         SCNVector3(side * 0.294, -0.023, 0.005), skin)
            ear.eulerAngles.z = side * -0.12
            BeastArt.ellipsoid(parent, 0.041, SCNVector3(0.65, 1, 0.3),
                               SCNVector3(side * 0.313, -0.021, -0.029), inner)
        }
    }

    static func lionFace(on parent: SCNNode, fur: SCNMaterial, mane: SCNMaterial) {
        let face = SCNNode(); face.position.z = -0.26; parent.addChildNode(face)
        let material = portraitMaterial("RoaringLionFace", fallback: fur)
        sculptHead(on: face, radius: SIMD3(0.35, 0.335, 0.30), textureSize: SIMD2(0.74, 0.74),
                   face: material, back: fur, lion: true)
        for side: Float in [-1, 1] {
            let ear = BeastArt.ellipsoid(parent, 0.092, SCNVector3(0.9, 0.94, 0.48),
                                         SCNVector3(side * 0.302, 0.318, -0.18), fur)
            ear.eulerAngles.z = side * -0.16
            BeastArt.ellipsoid(parent, 0.048, SCNVector3(0.85, 0.9, 0.28),
                               SCNVector3(side * 0.302, 0.322, -0.221), mane)
        }
    }

    private static func sculptHead(on parent: SCNNode, radius: SIMD3<Float>, textureSize: SIMD2<Float>,
                                   face: SCNMaterial, back: SCNMaterial, lion: Bool) {
        let rows = 64, columns = 80
        func gaussian(_ x: Float, _ y: Float, _ cx: Float, _ cy: Float, _ wx: Float, _ wy: Float) -> Float {
            let u = (x - cx) / wx, v = (y - cy) / wy
            return exp(-(u * u + v * v) * 2)
        }
        for front in [true, false] {
            var vertices: [SIMD3<Float>] = [], uv: [CGPoint] = [], indices: [Int32] = []
            for row in 0...rows {
                let latitude = Float(row) / Float(rows) * .pi
                let y = cos(latitude) * radius.y
                let jaw: Float = lion ? 1 : 1 - max(0, -y) * 0.54
                for column in 0...columns {
                    let phi = Float(column) / Float(columns) * .pi + (front ? .pi : 0)
                    let x = sin(latitude) * cos(phi) * radius.x * jaw
                    var z = sin(latitude) * sin(phi) * radius.z
                    if front {
                        let weight = pow(max(0, -sin(phi)), 5)
                        var relief: Float = 0
                        if lion {
                            relief += gaussian(x,y,0,-0.055,0.075,0.11) * 0.085
                            relief += gaussian(x,y,-0.105,-0.15,0.14,0.095) * 0.095
                            relief += gaussian(x,y,0.105,-0.15,0.14,0.095) * 0.095
                            relief += gaussian(x,y,0,0.08,0.10,0.18) * 0.024
                            relief -= gaussian(x,y,-0.145,0.145,0.10,0.055) * 0.018
                            relief -= gaussian(x,y,0.145,0.145,0.10,0.055) * 0.018
                        } else {
                            relief += gaussian(x,y,0,-0.052,0.052,0.055) * 0.056
                            relief += gaussian(x,y,0,0.005,0.035,0.09) * 0.018
                            relief += gaussian(x,y,-0.145,-0.068,0.11,0.10) * 0.014
                            relief += gaussian(x,y,0.145,-0.068,0.11,0.10) * 0.014
                            relief += gaussian(x,y,0,-0.146,0.15,0.045) * 0.009
                            relief -= gaussian(x,y,-0.109,0.05,0.085,0.058) * 0.008
                            relief -= gaussian(x,y,0.109,0.05,0.085,0.058) * 0.008
                        }
                        z -= relief * weight
                    }
                    vertices.append(SIMD3(x,y,z))
                    // UIKit image textures use a top-left origin in this geometry source.
                    uv.append(CGPoint(x: CGFloat(0.5 + x / textureSize.x), y: CGFloat(0.5 - y / textureSize.y)))
                }
            }
            for row in 0..<rows { for column in 0..<columns {
                let a = Int32(row * (columns + 1) + column), b = a + 1
                let c = a + Int32(columns + 1), d = c + 1
                indices += [a,b,c,b,d,c]
            }}
            BeastArt.mesh(parent, vertices: vertices, indices: indices, material: front ? face : back, uv: uv)
        }
    }

    static func davidHair(on parent: SCNNode) {
        let base = BeastArt.texturedMaterial("#844624", image: "RoaringFur", scale: 1.8, roughness: 0.72)
        let copper = BeastArt.texturedMaterial("#8F4D29", image: "RoaringFur", scale: 1.8, roughness: 0.70)
        // One groomed crown, with a soft asymmetric outline and small modeled strand ridges.
        let rows = 44, columns = 96
        var vertices: [SIMD3<Float>] = [], uv: [CGPoint] = [], indices: [Int32] = []
        for row in 0...rows {
            let t = Float(row) / Float(rows)
            for column in 0...columns {
                let phi = Float(column) / Float(columns) * .pi * 2
                let front = (cos(phi) + 1) * 0.5
                let hairline = -0.155 + pow(front, 3) * 0.32
                let end = acos((hairline - 0.06) / 0.35)
                let theta = t * end
                let ridge = sin(phi * 12 + theta * 5) * 0.005 + sin(phi * 7 - theta * 2) * 0.008
                let fullness = 1 + sin(phi * 5 + 0.8) * 0.025
                let x = sin(theta) * sin(phi) * (0.304 + ridge) * fullness
                let y = 0.06 + cos(theta) * 0.35 + sin(phi * 7) * pow(t, 10) * 0.012
                let z = 0.035 - sin(theta) * cos(phi) * (0.27 + ridge)
                vertices.append(SIMD3(x,y,z))
                uv.append(CGPoint(x: CGFloat(column) / CGFloat(columns), y: CGFloat(t)))
            }
        }
        for row in 0..<rows { for column in 0..<columns {
            let a = Int32(row * (columns + 1) + column), b = a + 1, c = a + Int32(columns + 1), d = c + 1
            indices += [a,b,c,b,d,c]
        }}
        BeastArt.mesh(parent, vertices: vertices, indices: indices, material: base, uv: uv)

        // Broad, shallow locks flow across the crown; their tips feather into the silhouette.
        let locks: [([SIMD3<Float>], Float)] = [
            ([SIMD3(-0.17,0.28,-0.12),SIMD3(-0.07,0.37,-0.26),SIMD3(0.18,0.25,-0.28),SIMD3(0.28,0.30,-0.08)],0.10),
            ([SIMD3(-0.18,0.245,-0.13),SIMD3(-0.10,0.30,-0.30),SIMD3(0.09,0.14,-0.31),SIMD3(0.20,0.20,-0.22)],0.093),
            ([SIMD3(-0.20,0.23,-0.08),SIMD3(-0.29,0.18,-0.23),SIMD3(-0.13,0.10,-0.29),SIMD3(-0.07,0.16,-0.25)],0.077),
            ([SIMD3(-0.24,0.16,-0.035),SIMD3(-0.33,0.05,-0.10),SIMD3(-0.30,-0.05,-0.10),SIMD3(-0.26,-0.10,-0.01)],0.043),
            ([SIMD3(0.25,0.18,-0.03),SIMD3(0.32,0.12,-0.10),SIMD3(0.31,0.01,-0.09),SIMD3(0.29,0.03,0.06)],0.048),
            ([SIMD3(-0.13,0.30,0.07),SIMD3(-0.03,0.42,0.15),SIMD3(0.22,0.32,0.12),SIMD3(0.28,0.39,0.06)],0.09)
        ]
        for (index, lock) in locks.enumerated() {
            hairLock(on: parent, controls: lock.0, width: lock.1, material: index.isMultiple(of: 2) ? copper : base,
                     followsCrown: index < 3)
        }
        for index in 0..<7 {
            let phi = Float(index) / 6 * .pi + .pi * 0.5
            let x = sin(phi) * 0.275, z = 0.035 - cos(phi) * 0.245
            hairLock(on: parent, controls: [SIMD3(x,0.02,z),SIMD3(x * 1.1,-0.07,z * 1.05),SIMD3(x * 0.96,-0.14,z * 1.05),SIMD3(x * 0.85 + 0.035,-0.18,z * 0.9)], width: 0.037, material: base)
        }
    }

    private static func hairLock(on parent: SCNNode, controls: [SIMD3<Float>], width: Float,
                                 material: SCNMaterial, followsCrown: Bool = false) {
        let rows = 28, sides = 16
        func point(_ t: Float) -> SIMD3<Float> {
            let a = 1 - t
            let first = controls[0] * (a * a * a) + controls[1] * (3 * a * a * t)
            let second = controls[2] * (3 * a * t * t) + controls[3] * (t * t * t)
            var p = first + second
            if followsCrown {
                let x = p.x / 0.304, y = (p.y - 0.06) / 0.35
                let section = max(0, 1 - x * x - y * y)
                p.z = 0.035 - sqrt(section) * 0.27 - 0.014
            }
            return p
        }
        var vertices: [SIMD3<Float>] = [], uv: [CGPoint] = [], indices: [Int32] = []
        var previousRight: SIMD3<Float>?
        for row in 0...rows {
            let t = Float(row) / Float(rows), p = point(t)
            let tangent = simd_normalize(point(min(1,t + 0.002)) - point(max(0,t - 0.002)))
            let reference: SIMD3<Float> = abs(tangent.z) < 0.92 ? SIMD3(0,0,-1) : SIMD3(0,1,0)
            let right = previousRight.map { simd_normalize($0 - tangent * simd_dot($0,tangent)) }
                ?? simd_normalize(simd_cross(tangent,reference))
            previousRight = right
            let outward = simd_cross(tangent,right)
            let profile = max(0.008,pow(1 - t,0.65) * (0.7 + sin(t * .pi) * 0.6))
            for side in 0..<sides {
                let angle = Float(side) / Float(sides) * .pi * 2
                let groove = 1 + sin(angle * 6 + t * 2) * 0.07
                let across = right * (cos(angle) * width * profile)
                let thickness = outward * (sin(angle) * 0.023 * profile * groove)
                vertices.append(p + across + thickness)
                uv.append(CGPoint(x: CGFloat(side) / CGFloat(sides), y: CGFloat(t)))
            }
        }
        for row in 0..<rows { for side in 0..<sides {
            let a = Int32(row * sides + side), b = Int32(row * sides + (side + 1) % sides), c = a + Int32(sides), d = b + Int32(sides)
            indices += [a,b,c,b,d,c]
        }}
        BeastArt.mesh(parent, vertices: vertices, indices: indices, material: material, uv: uv)
    }
}
