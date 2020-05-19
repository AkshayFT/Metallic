//
//  ImageRenderer.swift
//  Metallic
//
//  Created by Akshay on 11/09/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import MetalKit

private struct FTVertex {
    var position : SIMD2<Float>
    var textureCoordinate : SIMD2<Float>
}

class ImageRenderer: NSObject {

    private var device: MTLDevice!
    private var pipelineState: MTLRenderPipelineState!
    private var commandQueue: MTLCommandQueue!

    private var vertexBuffer : MTLBuffer?
    private var mvpBuffer : MTLBuffer?

    private var textures = [MTLTexture]()

    private var numberOfVertices = 4

    private var prevViewPortSize = CGSize(width:0,height:0)

    init(metalView: MTKView) {
        super.init()
        configure(with: metalView.device!, pixelFormat: metalView.colorPixelFormat)
    }

    init(metalLayer: CAMetalLayer) {
        super.init()
        configure(with: metalLayer.device!, pixelFormat: metalLayer.pixelFormat)
    }

    func render(on metalLayer: CAMetalLayer) {
        createDummyTextures(device)

        populateVertexBuffer(with: metalLayer.bounds.size, textures: textures)
        guard let drawble = metalLayer.nextDrawable() else { return }
        draw(textures, on: drawble)
    }

    func render(texture: MTLTexture, ontexture: MTLTexture, commandBuffer: MTLCommandBuffer, mvpBuffer: MTLBuffer) {

        let dataSize = numberOfVertices * MemoryLayout<Vertex>.stride;
        vertexBuffer = device.makeBuffer(length: dataSize*numberOfVertices, options: .storageModeShared)

        let quadVertices = getQuadVertices(for: texture, vpRect: CGRect(origin: .zero, size: CGSize(width: ontexture.width, height: ontexture.height)))
        let destination = vertexBuffer!.contents() + dataSize
        memcpy(destination, quadVertices, dataSize)

        self.mvpBuffer = mvpBuffer
        fillInTextures([texture], on:ontexture, commandBuffer: commandBuffer)
    }
}

private extension ImageRenderer {

    func createDummyTextures(_ device: MTLDevice) {
        let cgImage = CGImage.cgImage(for: "A")
        let cgImage2 = CGImage.cgImage(for: "B")
        let cgImage3 = CGImage.cgImage(for: "C")
        let cgImage4 = CGImage.cgImage(for: "D")
        textures.removeAll()
        textures.append(TextureHelper.createTexture(for: cgImage, device: device))
        textures.append(TextureHelper.createTexture(for: cgImage2, device: device))
        textures.append(TextureHelper.createTexture(for: cgImage3, device: device))
        textures.append(TextureHelper.createTexture(for: cgImage4, device: device))
    }

    func configure(with device: MTLDevice, pixelFormat: MTLPixelFormat) {
        self.device = device
        let library = device.makeDefaultLibrary()
        let vertexFunction = library?.makeFunction(name: "vertexShader")
        let fragmentFunction = library?.makeFunction(name: "samplingShader")

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "Texture Pipeline"
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = pixelFormat
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .one
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

        pipelineState = try? device.makeRenderPipelineState(descriptor: pipelineDescriptor)

        commandQueue = device.makeCommandQueue()
    }

    func populateVertexBuffer(with vpSize:CGSize, textures: [MTLTexture]) {

//        let scale = CGAffineTransform(scaleX: 0.5, y: 0.5)
//        let translate2 = CGAffineTransform(translationX: vpSize.width/2, y: 0)
//        let translate3 = CGAffineTransform(translationX: 0, y: vpSize.height/2)
//        let translate4 = CGAffineTransform(translationX: vpSize.width/2, y: vpSize.height/2)
//
//        let vpRect = CGRect(origin: .zero, size: vpSize).applying(scale)
//        let vpRect2 = vpRect.applying(translate2)
//        let vpRect3 = vpRect.applying(translate3)
//        let vpRect4 = vpRect.applying(translate4)
//
        let vpRects = getVpRects(vpSize: vpSize)

        let dataSize = numberOfVertices * MemoryLayout<Vertex>.stride;
        vertexBuffer = device.makeBuffer(length: dataSize*numberOfVertices, options: .storageModeShared)

        for (index,texture) in textures.enumerated() {
            let quadVertices = getQuadVertices(for: texture, vpRect: vpRects[index])
            let destination = vertexBuffer!.contents() + dataSize*index
            memcpy(destination, quadVertices, dataSize)
        }

        var projection = simd_float4x4.ortho2d(width: vpSize.width.toFloat, height: vpSize.height.toFloat)
        mvpBuffer = device.makeBuffer(bytes: &projection, length: MemoryLayout<simd_float4x4>.stride, options: .storageModeShared)
    }

    func getQuadVertices(for texture:MTLTexture, vpRect: CGRect) -> [FTVertex] {
        let textureSize = CGSize(width: texture.width, height: texture.height)
        let textureRect = CGRect(origin: .zero, size: textureSize)
        let aspectRect = textureRect.aspectFitted(inside: vpRect)

        let angle : Float = 0.0//Float.pi/4
        let tx : Float = 0.0
        let ty : Float = 0.0
        let topLeft = rotateAndTranslate(vector: aspectRect.topLeft, by: angle, tx: tx, ty: ty)
        let topRight = rotateAndTranslate(vector: aspectRect.topRight, by: angle, tx: tx, ty: ty)
        let bottomLeft = rotateAndTranslate(vector: aspectRect.bottomLeft, by: angle, tx: tx, ty: ty)
        let bottomRight = rotateAndTranslate(vector: aspectRect.bottomRight, by: angle, tx: tx, ty: ty)

        let tl = FTVertex(position: topLeft,
                        textureCoordinate: TextureCoordinate.topLeft)

        let tr = FTVertex(position: topRight,
                        textureCoordinate: TextureCoordinate.topRight)

        let bl = FTVertex(position: bottomLeft,
                        textureCoordinate: TextureCoordinate.bottomLeft)

        let br = FTVertex(position: bottomRight,
                        textureCoordinate: TextureCoordinate.bottomRight)

        return [tl,tr,bl,br]
    }

    func encodeTexture(with vertexBuffer: MTLBuffer?,
                       offset: Int,
                       texture: MTLTexture?,
                       renderEncoder:MTLRenderCommandEncoder?) {
        let finalOffset : Int = MemoryLayout<Vertex>.stride*numberOfVertices*offset
        let startVertex = 0
        renderEncoder?.setVertexBuffer(vertexBuffer, offset: finalOffset, index: 0)
        renderEncoder?.setVertexBuffer(mvpBuffer, offset: 0, index: 1)

        renderEncoder?.setFragmentTexture(texture, index: 0)
        renderEncoder?.drawPrimitives(type: .triangleStrip, vertexStart: startVertex, vertexCount: numberOfVertices)
    }

}

//MARK:- Draw
extension ImageRenderer {
    private func draw(_ textures: [MTLTexture], on currentDrawable:CAMetalDrawable) {

        let commandBuffer = commandQueue.makeCommandBuffer()!
        commandBuffer.label = "command-buffer"

        fillInTextures(textures, on:currentDrawable.texture, commandBuffer: commandBuffer)

        commandBuffer.present(currentDrawable)
        commandBuffer.commit()
    }

   private  func fillInTextures(_ textures: [MTLTexture],
                        on texture: MTLTexture,
                       commandBuffer: MTLCommandBuffer) {
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = texture
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1, 1, 1, 1)
        renderPassDescriptor.colorAttachments[0].loadAction = .clear

        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        renderEncoder?.label = "renderEncoder"
        renderEncoder?.setRenderPipelineState(pipelineState)

        for i in 0..<textures.count {
            encodeTexture(with: vertexBuffer,
                          offset: i,
                          texture: textures[i],
                          renderEncoder: renderEncoder)
        }
        renderEncoder?.endEncoding()
    }
}

//MARK:- MTKView
extension ImageRenderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {

        if(size.width != prevViewPortSize.width || size.height != prevViewPortSize.height) {
            prevViewPortSize = size;
            populateVertexBuffer(with: size, textures: textures);
        }
        print(size)
    }

    func draw(in view: MTKView) {
        guard let currentDrawable = view.currentDrawable else {
            fatalError("Drawable not available")
        }

        draw(textures, on: currentDrawable)
    }
}

private extension ImageRenderer {
    func getVpRects(vpSize: CGSize) -> [CGRect] {
        let scale = CGAffineTransform(scaleX: 0.5, y: 0.5)
        let translate2 = CGAffineTransform(translationX: vpSize.width/2, y: 0)
        let translate3 = CGAffineTransform(translationX: 0, y: vpSize.height/2)
        let translate4 = CGAffineTransform(translationX: vpSize.width/2, y: vpSize.height/2)

        let vpRect = CGRect(origin: .zero, size: vpSize).applying(scale)
        let vpRect2 = vpRect.applying(translate2)
        let vpRect3 = vpRect.applying(translate3)
        let vpRect4 = vpRect.applying(translate4)

        let vpRects = [vpRect,vpRect2,vpRect3,vpRect4]
        return vpRects
    }
}
