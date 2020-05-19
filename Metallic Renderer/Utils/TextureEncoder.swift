//
//  TextureEncoder.swift
//  Metallic
//
//  Created by Akshay on 23/09/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import Metal
import simd
import CoreGraphics

private struct QuadVertex {
    var position : SIMD2<Float>
    var textureCoordinate : SIMD2<Float>
}
struct TextureCoordinate {
    static let topLeft = SIMD2<Float>(0.0,0.0)
    static let topRight = SIMD2<Float>(1.0,0.0)
    static let bottomRight = SIMD2<Float>(1.0,1.0)
    static let bottomLeft = SIMD2<Float>(0.0,1.0)
}

class TextureEncoder {

    private let pipeline: MTLRenderPipelineState

    private var vertexBuffer: MTLBuffer!
    private var mvpBuffer: MTLBuffer!
    private var numberOfVertices: Int = 4 //As We're using Traingle Strip instead of 2 Traingles.


    init(pipeline: MTLRenderPipelineState) {
        self.pipeline = pipeline
    }

    func encode(sourceTexture: MTLTexture,
                targetTexture: MTLTexture,
                commandBuffer: MTLCommandBuffer) {

        let targetSize = CGSize(width: targetTexture.width, height: targetTexture.height)
        populateVertextBuffer(texture: sourceTexture, vpSize: targetSize)

        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = targetTexture        
        renderPassDescriptor.colorAttachments[0].loadAction = .load        

        let rendercommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        rendercommandEncoder.setRenderPipelineState(pipeline)

        rendercommandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        rendercommandEncoder.setVertexBuffer(mvpBuffer, offset: 0, index: 1)

        rendercommandEncoder.setFragmentTexture(sourceTexture, index: 0)
        rendercommandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: numberOfVertices)
        rendercommandEncoder.endEncoding()
    }
}

private extension TextureEncoder {
    func populateVertextBuffer(texture: MTLTexture, vpSize: CGSize) {
        if(nil == vertexBuffer) {
            let vpRect = CGRect(origin: .zero, size: vpSize)

            let quadVertices = getQuadVertices(for: texture, vpRect: vpRect)
            let dataSize = quadVertices.count * MemoryLayout<QuadVertex>.stride;
            vertexBuffer = texture.device.makeBuffer(bytes: quadVertices, length: dataSize, options: .storageModeShared);

            var projection = simd_float4x4.ortho2d(width: vpSize.width.toFloat, height: vpSize.height.toFloat)
            mvpBuffer = texture.device.makeBuffer(bytes: &projection, length: MemoryLayout<simd_float4x4>.stride, options: .storageModeShared)
        }
    }

    func getQuadVertices(for texture:MTLTexture,
                         vpRect: CGRect,
                         angle: Float = 0,
                         tx: Float = 0,
                         ty: Float = 0) -> [QuadVertex] {
        let textureSize = CGSize(width: texture.width, height: texture.height)
        let textureRect = CGRect(origin: .zero, size: textureSize)
        let aspectRect = textureRect.aspectFitted(inside: vpRect)

        let topLeft = rotateAndTranslate(vector: aspectRect.topLeft, by: angle, tx: tx, ty: ty)
        let topRight = rotateAndTranslate(vector: aspectRect.topRight, by: angle, tx: tx, ty: ty)
        let bottomLeft = rotateAndTranslate(vector: aspectRect.bottomLeft, by: angle, tx: tx, ty: ty)
        let bottomRight = rotateAndTranslate(vector: aspectRect.bottomRight, by: angle, tx: tx, ty: ty)

        let tl = QuadVertex(position: topLeft,
                        textureCoordinate: TextureCoordinate.topLeft)

        let tr = QuadVertex(position: topRight,
                        textureCoordinate: TextureCoordinate.topRight)

        let bl = QuadVertex(position: bottomLeft,
                        textureCoordinate: TextureCoordinate.bottomLeft)

        let br = QuadVertex(position: bottomRight,
                        textureCoordinate: TextureCoordinate.bottomRight)

        return [tl,tr,bl,br]
    }
}
