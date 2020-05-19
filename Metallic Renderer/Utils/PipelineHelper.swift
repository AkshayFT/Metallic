//
//  PipelineHelper.swift
//  Metallic
//
//  Created by Akshay on 23/09/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import Metal

class PipelineHelper {
    static func createPipeline(device: MTLDevice,
                               tool: DrawingTool,
                               pixelFormat: MTLPixelFormat) throws -> MTLRenderPipelineState {

        let pipelineDescriptor = PipelineHelper.pipelineDescriptor(device: device,
                                                                  tool: tool,
                                                                  pixelFormat: pixelFormat)

        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)

    }

    static func createImageRenderPipeline(device: MTLDevice,
                                          pixelFormat: MTLPixelFormat) throws -> MTLRenderPipelineState {

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
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .destinationColor
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .destinationColor
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }

    static func createFillPipeline(device: MTLDevice, pixelFormat: MTLPixelFormat) throws -> MTLRenderPipelineState {
        let descriptor = MTLRenderPipelineDescriptor()
        let library = device.makeDefaultLibrary()!
        descriptor.vertexFunction = library.makeFunction(name: "fillVertexShader")
        descriptor.fragmentFunction = library.makeFunction(name: "fillFragmentShader")
        descriptor.colorAttachments[0].pixelFormat = pixelFormat
        descriptor.sampleCount = 4
        return try device.makeRenderPipelineState(descriptor: descriptor)
    }

    static func createFillShapePipeline(device: MTLDevice, pixelFormat: MTLPixelFormat) throws -> MTLRenderPipelineState {
          let descriptor = MTLRenderPipelineDescriptor()
          let library = device.makeDefaultLibrary()!
          descriptor.vertexFunction = library.makeFunction(name: "vertexShapes")
          descriptor.fragmentFunction = library.makeFunction(name: "fragmentShapes")
          descriptor.colorAttachments[0].pixelFormat = pixelFormat
          return try device.makeRenderPipelineState(descriptor: descriptor)
      }

    static func createTextureCopyPipeline(device: MTLDevice, pixelFormat: MTLPixelFormat) throws -> MTLRenderPipelineState  {
        let descriptor = MTLRenderPipelineDescriptor()
        let library = device.makeDefaultLibrary()!
        descriptor.vertexFunction = library.makeFunction(name: "textureQuadVertex")
        descriptor.fragmentFunction = library.makeFunction(name: "textureQuadFragment")
        descriptor.colorAttachments[0].pixelFormat = pixelFormat
        return try device.makeRenderPipelineState(descriptor: descriptor)
    }

    static func createTexturePipeline(pixelFormat: MTLPixelFormat) throws -> MTLRenderPipelineState  {
          let descriptor = MTLRenderPipelineDescriptor()
          let library = mtlDevice.makeDefaultLibrary()!
          descriptor.vertexFunction = library.makeFunction(name: "vertexShaderImage")
          descriptor.fragmentFunction = library.makeFunction(name: "fragmentShaderImage")
          descriptor.colorAttachments[0].pixelFormat = pixelFormat
          return try mtlDevice.makeRenderPipelineState(descriptor: descriptor)
      }
}

//MARK: - Private
private extension PipelineHelper {
    private static func pipelineDescriptor(device: MTLDevice,
                                           tool: DrawingTool,
                                           pixelFormat: MTLPixelFormat) -> MTLRenderPipelineDescriptor {

        let library = device.makeDefaultLibrary()
        let vertexFunction = library?.makeFunction(name: "drawVertexShader")
        let fragmentFunction = library?.makeFunction(name: "drawFragmentShader")

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "\(tool.rawValue) Pipeline"
        pipelineDescriptor.colorAttachments[0].pixelFormat = pixelFormat
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add

        if tool == .eraser {
            pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .one
            pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
            pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceColor
            pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        } else {
            pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .one
            pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
            pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
            pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        }
        return pipelineDescriptor
    }
}
