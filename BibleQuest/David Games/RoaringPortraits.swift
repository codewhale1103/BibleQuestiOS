import SceneKit
import UIKit
import simd

/// Reference-matched surface detail on sculpted heads, with modeled noses, cheeks,
/// eye volumes and fur. Facial materials respond to the scene lighting.
enum RoaringPortraits {
    private static func portraitMaterial(_ name: String, fallback: SCNMaterial) -> SCNMaterial {
        guard let image = UIImage(named: name) else { return fallback }
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.diffuse.contents = image
        material.diffuse.magnificationFilter = .linear
        material.diffuse.minificationFilter = .linear
        material.diffuse.mipFilter = .linear
        material.roughness.contents = 0.75
        material.metalness.contents = 0
        // A small ambient contribution preserves the painted color in the canyon shade.
        material.emission.contents = image
        material.emission.intensity = 0.015
        return material
    }

    private static func projectedHead(on parent: SCNNode, radius: SIMD3<Float>, textureSize: SIMD2<Float>,
                                   face: SCNMaterial, back: SCNMaterial, lion: Bool) {
        let rows = 96, columns = 128
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
                            relief += gaussian(x,y,0,-0.055,0.085,0.13) * 0.145
                            relief += gaussian(x,y,-0.105,-0.15,0.145,0.105) * 0.135
                            relief += gaussian(x,y,0.105,-0.15,0.145,0.105) * 0.135
                            relief += gaussian(x,y,0,0.08,0.10,0.18) * 0.024
                            relief -= gaussian(x,y,-0.145,0.145,0.10,0.055) * 0.018
                            relief -= gaussian(x,y,0.145,0.145,0.10,0.055) * 0.018
                        } else {
                            relief += gaussian(x,y,0,-0.052,0.052,0.065) * 0.100
                            relief += gaussian(x,y,0,0.005,0.035,0.11) * 0.030
                            relief += gaussian(x,y,-0.145,-0.068,0.12,0.11) * 0.028
                            relief += gaussian(x,y,0.145,-0.068,0.12,0.11) * 0.028
                            relief += gaussian(x,y,0,-0.146,0.15,0.045) * 0.009
                            relief += gaussian(x,y,-0.109,0.05,0.085,0.075) * 0.025
                            relief += gaussian(x,y,0.109,0.05,0.085,0.075) * 0.025
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

    static func davidFace(on parent: SCNNode, skin: SCNMaterial) {
        let material = portraitMaterial("RoaringDavidFace", fallback: skin)
        projectedHead(on: parent, radius: SIMD3(0.287,0.325,0.245), textureSize: SIMD2(0.64,0.72), face: material, back: skin, lion: false)
        let inner = BeastArt.material("#D88766", roughness: 0.85)
        for side: Float in [-1,1] {
            let ear = BeastArt.ellipsoid(parent,0.074,SCNVector3(0.7,1.1,0.63),SCNVector3(side*0.289,-0.008,-0.004),skin)
            ear.eulerAngles.z = side * -0.18
            BeastArt.ellipsoid(ear,0.044,SCNVector3(0.73,1.1,0.32),SCNVector3(0,0,-0.071),inner)
        }
    }

    static func lionFace(on parent: SCNNode, fur: SCNMaterial, mane: SCNMaterial) {
        let face = SCNNode(); face.position.z = -0.23; parent.addChildNode(face)
        let portrait = portraitMaterial("RoaringLionFace", fallback: fur)
        projectedHead(on: face, radius: SIMD3(0.34,0.335,0.30), textureSize: SIMD2(0.74,0.74), face: portrait, back: fur, lion: true)
        for side: Float in [-1, 1] {
            let ear = BeastArt.ellipsoid(parent, 0.086, SCNVector3(0.95, 1, 0.51),
                                         SCNVector3(side * 0.32, 0.34, -0.11), fur)
            ear.eulerAngles.z = side * -0.3
            BeastArt.ellipsoid(ear, 0.054, SCNVector3(0.88, 0.91, 0.30), SCNVector3(0, 0, -0.087), mane)
        }
        let nose = BeastArt.material("#33241F", roughness: 0.38)
        let path = UIBezierPath()
        path.move(to: CGPoint(x: -0.073, y: 0.025))
        path.addCurve(to: CGPoint(x: 0.073, y: 0.025), controlPoint1: CGPoint(x: -0.045, y: 0.052), controlPoint2: CGPoint(x: 0.045, y: 0.052))
        path.addQuadCurve(to: CGPoint(x: 0, y: -0.053), controlPoint: CGPoint(x: 0.066, y: -0.01))
        path.addQuadCurve(to: CGPoint(x: -0.073, y: 0.025), controlPoint: CGPoint(x: -0.066, y: -0.01))
        let shape = SCNShape(path: path, extrusionDepth: 0.038); shape.chamferRadius = 0.012; shape.materials = [nose]
        let node = SCNNode(geometry: shape); node.position = SCNVector3(0, -0.05, -0.458); face.addChildNode(node)
        let mouth = BeastArt.material("#4A3027", roughness: 0.9)
        BeastArt.sweep(face, [SIMD3(0,-0.09,-0.447),SIMD3(0,-0.115,-0.45),SIMD3(0,-0.14,-0.448),SIMD3(0,-0.16,-0.426)], radius: 0.005, material: mouth)
        for side: Float in [-1, 1] {
            BeastArt.sweep(face, [SIMD3(0,-0.16,-0.426),SIMD3(side * 0.045,-0.19,-0.433),SIMD3(side * 0.13,-0.177,-0.41),SIMD3(side * 0.16,-0.15,-0.365)], radius: 0.004, material: mouth)
            for row in 0..<3 {
                for i in 0..<3 {
                    let x = side * (0.07 + Float(i) * 0.027)
                    let y = -0.10 - Float(row) * 0.025
                    BeastArt.ellipsoid(face, 0.0035, SCNVector3(1,1,0.4), SCNVector3(x,y,-0.434 + Float(i) * 0.008), mouth)
                }
                let y = -0.11 - Float(row) * 0.028
                let ivory = BeastArt.material("#E9D6B4", roughness: 0.8)
                BeastArt.sweep(face, [SIMD3(side * 0.12,y,-0.425),SIMD3(side * 0.24,y + 0.01,-0.46),SIMD3(side * 0.33,y + 0.03,-0.45),SIMD3(side * 0.40,y + Float(row - 1) * 0.035,-0.39)], radius: 0.0015, pointed: true, material: ivory, sides: 5, steps: 14)
            }
        }
    }

    static func davidHair(on parent: SCNNode) {
        let base = BeastArt.texturedMaterial("#B69A89",image:"RoaringMane",scale:1,roughness:0.69)
        let copper = BeastArt.texturedMaterial("#D7AB8D",image:"RoaringMane",scale:1,roughness:0.67)
        let rows=48, columns=96
        var v:[SIMD3<Float>]=[], i:[Int32]=[], uv:[CGPoint]=[]
        for row in 0...rows {
            let t=Float(row)/Float(rows)
            for col in 0...columns {
                let phi=Float(col)/Float(columns)*2 * .pi
                let front=(cos(phi)+1)*0.5
                let line = -0.15 + pow(front,3)*0.34
                let theta=t*acos((line-0.055)/0.35)
                v.append(SIMD3(sin(theta)*sin(phi)*0.307,0.055+cos(theta)*0.35,0.035-sin(theta)*cos(phi)*0.272))
                uv.append(CGPoint(x:CGFloat(col)/CGFloat(columns)*2,y:CGFloat(t)))
            }
        }
        for row in 0..<rows { for col in 0..<columns {
            let a=Int32(row*(columns+1)+col),b=a+1,c=a+Int32(columns+1),d=c+1;i += [a,b,c,b,d,c]
        }}
        BeastArt.mesh(parent,vertices:v,indices:i,material:base,uv:uv)
        let locks:[([SIMD3<Float>],Float,Float)] = [
            ([SIMD3(-0.22,0.24,-0.12),SIMD3(-0.12,0.40,-0.23),SIMD3(0.20,0.37,-0.23),SIMD3(0.29,0.37,-0.09)],0.092,0.046),
            ([SIMD3(-0.25,0.22,-0.17),SIMD3(-0.12,0.38,-0.35),SIMD3(0.22,0.19,-0.34),SIMD3(0.33,0.27,-0.19)],0.09,0.044),
            ([SIMD3(-0.22,0.20,-0.20),SIMD3(-0.10,0.30,-0.38),SIMD3(0.15,0.10,-0.34),SIMD3(0.24,0.17,-0.25)],0.074,0.040),
            ([SIMD3(-0.16,0.30,-0.19),SIMD3(-0.31,0.27,-0.32),SIMD3(-0.25,0.10,-0.32),SIMD3(-0.13,0.13,-0.30)],0.070,0.041),
            ([SIMD3(-0.22,0.20,-0.10),SIMD3(-0.37,0.12,-0.24),SIMD3(-0.35,-0.03,-0.19),SIMD3(-0.26,-0.065,-0.09)],0.065,0.040),
            ([SIMD3(0.20,0.26,-0.12),SIMD3(0.39,0.20,-0.17),SIMD3(0.36,0.08,-0.17),SIMD3(0.39,0.18,-0.04)],0.068,0.037),
            ([SIMD3(0.28,0.17,-0.04),SIMD3(0.36,0.08,-0.15),SIMD3(0.32,-0.04,-0.15),SIMD3(0.27,-0.09,-0.03)],0.05,0.035),
            ([SIMD3(-0.19,0.31,0.05),SIMD3(-0.06,0.43,0.09),SIMD3(0.20,0.43,0.11),SIMD3(0.32,0.40,0.13)],0.085,0.045)
        ]
        for (index, lock) in locks.enumerated() {
            hairLock(on:parent,controls:lock.0.map { SIMD3(-$0.x,$0.y,$0.z) },width:lock.1,thickness:lock.2,material:index.isMultiple(of:3) ? copper:base)

        }
        for index in 0..<9 {
            let a=Float(index)/8 * .pi + .pi*0.5
            let x=sin(a)*0.28,z=0.035-cos(a)*0.25
            hairLock(on:parent,controls:[SIMD3(x,0.05,z),SIMD3(x*1.15,-0.06,z*1.12),SIMD3(x*1.1,-0.17,z*1.12),SIMD3(x*0.93+0.035,-0.20,z)],width:0.046,thickness:0.028,material:base)
        }
    }

    private static func hairLock(on parent: SCNNode, controls:[SIMD3<Float>],width:Float,thickness:Float,material:SCNMaterial) {
        let rows=32,sides=20
        func point(_ t:Float)->SIMD3<Float> {
            let a=1-t
            return controls[0]*(a*a*a)+controls[1]*(3*a*a*t)+controls[2]*(3*a*t*t)+controls[3]*(t*t*t)
        }
        var v:[SIMD3<Float>]=[],i:[Int32]=[], uv:[CGPoint]=[]
        var previous:SIMD3<Float>?
        for row in 0...rows {
            let t=Float(row)/Float(rows),p=point(t)
            let tangent=simd_normalize(point(min(1,t+0.002))-point(max(0,t-0.002)))
            let reference:SIMD3<Float>=abs(tangent.z)<0.92 ? SIMD3(0,0,-1):SIMD3(0,1,0)
            let right=previous.map { simd_normalize($0-tangent*simd_dot($0,tangent)) } ?? simd_normalize(simd_cross(tangent,reference))
            previous=right
            let outward=simd_cross(tangent,right)
            let profile=max(0.006,pow(1-t,0.6)*(0.70+sin(t * .pi)*0.6))
            for side in 0..<sides {
                let a=Float(side)/Float(sides)*2 * .pi
                let groove=1+sin(a*9+t*3)*0.035
                v.append(p+right*(cos(a)*width*profile)+outward*(sin(a)*thickness*profile*groove))
                uv.append(CGPoint(x:CGFloat(side)/CGFloat(sides),y:CGFloat(t)))
            }
        }
        for row in 0..<rows { for side in 0..<sides {
            let a=Int32(row*sides+side),b=Int32(row*sides+(side+1)%sides),c=a+Int32(sides),d=b+Int32(sides)
            i += [a,b,c,b,d,c]
        }}
        BeastArt.mesh(parent,vertices:v,indices:i,material:material,uv:uv)
    }
}
