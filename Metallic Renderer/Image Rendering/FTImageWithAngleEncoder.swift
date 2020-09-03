//
//  FTImageWithAngleEncoder.swift
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
private struct FTTextureCoordinate {
    static let topLeft = SIMD2<Float>(0.0,0.0)
    static let topRight = SIMD2<Float>(1.0,0.0)
    static let bottomRight = SIMD2<Float>(1.0,1.0)
    static let bottomLeft = SIMD2<Float>(0.0,1.0)
}

final class FTImageWithAngleEncoder {

    private var aliasingTexture: MTLTexture?

    func encode(texture: MTLTexture,
                rect: CGRect,
                angle: Float,
                mvpBuffer: MTLBuffer,
                targetTexture: MTLTexture,
                commandBuffer: MTLCommandBuffer) {
        if aliasingTexture == nil {
            aliasingTexture = createAliasingTexture(from: targetTexture)
        }
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = aliasingTexture
        renderPassDescriptor.colorAttachments[0].resolveTexture = targetTexture
        renderPassDescriptor.colorAttachments[0].loadAction = .load
        renderPassDescriptor.colorAttachments[0].storeAction = .storeAndMultisampleResolve

        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        do {
            let pipeline = try createTexturePipeline(pixelFormat: targetTexture.pixelFormat)
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

private extension FTImageWithAngleEncoder {

    func createTexturePipeline(pixelFormat: MTLPixelFormat) throws -> MTLRenderPipelineState  {
        let descriptor = MTLRenderPipelineDescriptor()
        let library = mtlDevice.makeDefaultLibrary()!
        descriptor.vertexFunction = library.makeFunction(name: "vertexShaderImage")
        descriptor.fragmentFunction = library.makeFunction(name: "fragmentShaderImage")
        descriptor.colorAttachments[0].pixelFormat = pixelFormat
        descriptor.sampleCount = 4
        return try mtlDevice.makeRenderPipelineState(descriptor: descriptor)
    }

    func createAliasingTexture(from texture: MTLTexture) -> MTLTexture {
        let descriptor = MTLTextureDescriptor()
        descriptor.usage = [.renderTarget, .shaderRead]
        descriptor.textureType = .type2DMultisample
        descriptor.sampleCount = 4
        descriptor.pixelFormat = texture.pixelFormat
        descriptor.width = texture.width
        descriptor.height = texture.height
        
        guard let texture = mtlDevice.makeTexture(descriptor: descriptor) else {
            fatalError("Unable to create Texture")
        }
        return texture
    }
    
    func getQuadVertices(texture:MTLTexture, rect: CGRect, angle: Float) -> [FTTextureVertex] {
        let textureSize = CGSize(width: texture.width, height: texture.height)
        let textureRect = CGRect(origin: .zero, size: textureSize)
        let aspectRect = textureRect.aspectFitted(inside: rect)
        
        let angle : Float = angle
        let tx : Float = Float(rect.midX)
        let ty : Float = Float(rect.midY)
        let topLeft = rotate(vector: aspectRect.topLeft, angle: angle, tx: tx, ty: ty)
        let topRight = rotate(vector: aspectRect.topRight, angle: angle, tx: tx, ty: ty)
        let bottomLeft = rotate(vector: aspectRect.bottomLeft, angle: angle, tx: tx, ty: ty)
        let bottomRight = rotate(vector: aspectRect.bottomRight, angle: angle, tx: tx, ty: ty)
        
        let tl = FTTextureVertex(position: topLeft,
                                 textureCoordinate: FTTextureCoordinate.topLeft)
        
        let tr = FTTextureVertex(position: topRight,
                                 textureCoordinate: FTTextureCoordinate.topRight)
        
        let bl = FTTextureVertex(position: bottomLeft,
                                 textureCoordinate: FTTextureCoordinate.bottomLeft)
        
        let br = FTTextureVertex(position: bottomRight,
                                 textureCoordinate: FTTextureCoordinate.bottomRight)
        
        return [tl,tr,bl,br]
    }
}

private func rotate(vector:SIMD2<Float>, angle:Float, tx:Float, ty: Float) -> SIMD2<Float> {
    let positionVector = simd_float3(vector, 1)
    let translated = positionVector*makeTranslationMatrix(tx: -tx, ty: -ty)
    let rotated = translated*makeRotationMatrix(angle: angle)
    let final = rotated*makeTranslationMatrix(tx: tx, ty: ty)
    return SIMD2<Float>(x:final.x, y:final.y)
}

private func makeRotationMatrix(angle: Float) -> simd_float3x3 {
    let rows = [
        simd_float3( cos(angle), sin(angle), 0),
        simd_float3(-sin(angle), cos(angle), 0),
        simd_float3( 0,          0,          1)
    ]
    return simd_float3x3(rows: rows)
}

private func makeTranslationMatrix(tx: Float, ty: Float) -> simd_float3x3 {
    var matrix = matrix_identity_float3x3
    matrix[0, 2] = tx
    matrix[1, 2] = ty
    return matrix
}
