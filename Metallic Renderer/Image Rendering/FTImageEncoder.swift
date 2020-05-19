//
//  FTImageEncoder.swift
//  Metallic
//
//  Created by Akshay on 19/05/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import MetalKit

private struct FTTextureVertex {
    var position : SIMD2<Float>
    var textureCoordinate : SIMD2<Float>
}

final class FTImageEncoder {

    func encode(texture: MTLTexture,
                rect: CGRect,
                angle: Float,
                mvpBuffer: MTLBuffer,
                targetTexture: MTLTexture,
                commandBuffer: MTLCommandBuffer) {

        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = targetTexture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        renderPassDescriptor.colorAttachments[0].storeAction = .store

        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        do {
            let pipeline = try PipelineHelper.createTexturePipeline(pixelFormat: .bgra8Unorm)
            renderEncoder?.setRenderPipelineState(pipeline)
        } catch {
            preconditionFailure("Unable to Create Pipeline")
        }

        let quadVertices = getQuadVertices(texture: texture, rect: rect, angle: angle)

        renderEncoder?.setVertexBytes(quadVertices, length: MemoryLayout<FTTextureVertex>.stride*quadVertices.count, index: 0)
        renderEncoder?.setVertexBuffer(mvpBuffer, offset: 0, index: 1)

        renderEncoder?.setFragmentTexture(texture, index: 0)

        renderEncoder?.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        renderEncoder?.endEncoding()
    }
}

private extension FTImageEncoder {
    
    func getQuadVertices(texture:MTLTexture, rect: CGRect, angle: Float) -> [FTTextureVertex] {
        let textureSize = CGSize(width: texture.width, height: texture.height)
        let textureRect = CGRect(origin: .zero, size: textureSize)
        let aspectRect = textureRect.aspectFitted(inside: rect)

        let angle : Float = angle
        let tx : Float = Float(rect.midX)
        let ty : Float = Float(rect.midY)
        let topLeft = rotate(vector: aspectRect.topLeft, by: angle, tx: tx, ty: ty)
        let topRight = rotate(vector: aspectRect.topRight, by: angle, tx: tx, ty: ty)
        let bottomLeft = rotate(vector: aspectRect.bottomLeft, by: angle, tx: tx, ty: ty)
        let bottomRight = rotate(vector: aspectRect.bottomRight, by: angle, tx: tx, ty: ty)

        let tl = FTTextureVertex(position: topLeft,
                                 textureCoordinate: TextureCoordinate.topLeft)

        let tr = FTTextureVertex(position: topRight,
                                 textureCoordinate: TextureCoordinate.topRight)

        let bl = FTTextureVertex(position: bottomLeft,
                                 textureCoordinate: TextureCoordinate.bottomLeft)

        let br = FTTextureVertex(position: bottomRight,
                                 textureCoordinate: TextureCoordinate.bottomRight)

        return [tl,tr,bl,br]
    }

    func rotate(vector:SIMD2<Float>, by angle:Float, tx:Float, ty: Float) -> SIMD2<Float> {
        let positionVector = simd_float3(vector, 1)
        let translated = positionVector*makeTranslationMatrix(tx: -tx, ty: -ty)
        let rotated = translated*makeRotationMatrix(angle: angle)
        let final = rotated*makeTranslationMatrix(tx: tx, ty: ty)
        return SIMD2<Float>(x:final.x, y:final.y)
    }

    func makeRotationMatrix(angle: Float) -> simd_float3x3 {
        let rows = [
            simd_float3( cos(angle), sin(angle), 0),
            simd_float3(-sin(angle), cos(angle), 0),
            simd_float3( 0,          0,          1)
        ]
        return simd_float3x3(rows: rows)
    }

    func makeTranslationMatrix(tx: Float, ty: Float) -> simd_float3x3 {
        var matrix = matrix_identity_float3x3
        matrix[0, 2] = tx
        matrix[1, 2] = ty
        return matrix
    }
}
