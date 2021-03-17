//
//  FTTextureTile.swift
//  Metallic
//
//  Created by Akshay on 04/12/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import CoreGraphics
import Metal
import simd

struct FTTextureTile {
    let texture: MTLTexture
    let rect: CGRect
    //TODO:Should move to reusable Lockable Buffer if required.
    let buffer: FTMetalBuffer<FTTextureVertex>

    init(texture: MTLTexture, rect: CGRect) {
        self.texture = texture
        self.rect = rect
        let vertices = getQuadVertices(rect: rect)
        self.buffer = FTMetalBuffer(vertices: vertices)
    }
}

struct FTTextureVertex {
    var position : SIMD2<Float>
    var coordinate : SIMD2<Float>
}

private struct FTTextureCoordinate {
    static let topLeft = SIMD2<Float>(0.0,0.0)
    static let topRight = SIMD2<Float>(1.0,0.0)
    static let bottomRight = SIMD2<Float>(1.0,1.0)
    static let bottomLeft = SIMD2<Float>(0.0,1.0)
}

private func getQuadVertices(rect: CGRect) -> [FTTextureVertex] {

    let tl = FTTextureVertex(position: rect.topLeft,
                             coordinate: FTTextureCoordinate.topLeft)

    let tr = FTTextureVertex(position: rect.topRight,
                             coordinate: FTTextureCoordinate.topRight)

    let bl = FTTextureVertex(position: rect.bottomLeft,
                             coordinate: FTTextureCoordinate.bottomLeft)

    let br = FTTextureVertex(position: rect.bottomRight,
                             coordinate: FTTextureCoordinate.bottomRight)

    return [tl,tr,bl,br]
}
