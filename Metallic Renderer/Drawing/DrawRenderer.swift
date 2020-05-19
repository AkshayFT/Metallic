//
//  DrawRenderer.swift
//  Metallic
//
//  Created by Akshay on 20/09/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import MetalKit

private struct FTVertex {
    let position : SIMD2<Float>
    let color : SIMD4<Float>
    let thickness : Int

    init(with point:CGPoint, color: PlatformColor, thickness: Thickness) {
        self.position = SIMD2<Float>(x:point.x.toFloat, y:point.y.toFloat)
        self.color = color.toFloat4
        self.thickness = thickness.rawValue
    }
}

enum DrawingTool: String {
    case pen
    case highlighter
    case eraser
}

enum Thickness: Int {
    case small = 10
    case medium = 20
    case large = 30
}

class DrawRenderer {

    private let device : MTLDevice!
    private let metalLayer : CAMetalLayer!

    private let pipeline_pen: MTLRenderPipelineState!
    private let pipeline_eraser: MTLRenderPipelineState!
    private let pipeline_image: MTLRenderPipelineState!
    private let pipeline_fill: MTLRenderPipelineState!

    private let commandQueue: MTLCommandQueue!
    private let imageEncoder : TextureEncoder!

    private var bufferPool: FTLockableBufferPool<FTMetalBuffer<FTVertex>>?
    private var vertexBuffer: FTMetalBuffer<FTVertex>?
    private var mvpBuffer: MTLBuffer?


    private var finalRenderTexture: MTLTexture!
    private var highlighterTexture: MTLTexture!
    private let brushTexture: MTLTexture!

    private var multiSampleTexture: MTLTexture!

    private var oldVPSize = CGSize.zero
    private var lastPoint : CGPoint?
    private var fillWithWhite = false;

    private var currentTool : DrawingTool = .pen

    init(metalLayer:CAMetalLayer) {
        self.device = metalLayer.device!
        self.metalLayer = metalLayer
        commandQueue = device.makeCommandQueue()

        let pixelFormat = self.metalLayer.pixelFormat
        let brushImage = CGImage.cgImage(for: "brush")
        brushTexture = TextureHelper.createTexture(for: brushImage, device: device)

        pipeline_pen = try? PipelineHelper.createPipeline(device: device,
                                                          tool: .pen,
                                                          pixelFormat: pixelFormat)

        pipeline_eraser = try? PipelineHelper.createPipeline(device: device,
                                                             tool: .eraser,
                                                             pixelFormat: pixelFormat)

        pipeline_image = try? PipelineHelper.createImageRenderPipeline(device: device,
                                                                       pixelFormat: pixelFormat)
        pipeline_fill = try? PipelineHelper.createFillPipeline(device: device, pixelFormat: pixelFormat)
        imageEncoder = TextureEncoder(pipeline:pipeline_image)


        bufferPool = FTLockableBufferPool<FTMetalBuffer<FTVertex>>.init(withCount: 3, factoryFunction: { () -> FTMetalBuffer<FTVertex> in
            let buffer = FTMetalBuffer<FTVertex>(vertices: [])
            return buffer
        })

        updateTargetTextureIfRequired(vpSize: metalLayer.bounds.size)
    }

    func render(mode: DrawingTool,
                points: [CGPoint],
                color: UIColor,
                thickness: Thickness,
                shouldClear: Bool,
                shouldEnd: Bool,
                isPolygon: Bool = false) {

        guard let drawble = metalLayer.nextDrawable() else { fatalError("Drawble doesn't exist") }
        self.currentTool = mode
        draw(currentDrawble: drawble,
             points: points,
             color: color,
             thickness: thickness,
             shouldClear: shouldClear,
             shouldEnd: shouldEnd,
             isPolygon: isPolygon);

        if shouldEnd {
            lastPoint = nil;
        }
    }

    func viewportSizeDidChange() {
        updateTargetTextureIfRequired(vpSize: metalLayer.bounds.size)
    }

    func clearAll() {
        guard let drawble = metalLayer.nextDrawable() else { fatalError("Drawble doesn't exist") }
        clearAllContents(currentDrawble: drawble)
    }
}

private extension DrawRenderer {

    func updateTargetTextureIfRequired(vpSize: CGSize) {
        if oldVPSize != vpSize || finalRenderTexture == nil {
            oldVPSize = vpSize
            multiSampleTexture = TextureHelper.createMultiSampleTexture(with: vpSize, device:device)
            finalRenderTexture = TextureHelper.createTexture(with: vpSize, device:device)
            highlighterTexture = TextureHelper.createTexture(with: vpSize, device: device)

            var projection = simd_float4x4.ortho2d(width: vpSize.width.toFloat,
                                                   height: vpSize.height.toFloat)
            if mvpBuffer == nil {
                mvpBuffer = device.makeBuffer(bytes: &projection,
                                              length: MemoryLayout<simd_float4x4>.stride,
                                              options: .storageModeShared)
            } else {
                memcpy(mvpBuffer?.contents(), &projection, MemoryLayout<simd_float4x4>.stride)
            }

        }
    }

    func populateVertexBuffer(points:[CGPoint],
                              color: UIColor,
                              thickness: Thickness,
                              isPolygon: Bool) {

        var pointsToRender = [CGPoint]()
        var start: CGPoint?
        if isPolygon {
            for point in points  {
                if let startPoint = start {
                    let intermediatePoints = CGPoint.intermediatePoints(start: startPoint, end: point)
                    pointsToRender.append(contentsOf: intermediatePoints)
                }
                start = point
            }
        } else {
            var pointsToRender = points
            if let start = lastPoint, let end = points.first {
                let intermediatePoints = CGPoint.intermediatePoints(start: start, end: end)
                pointsToRender.append(contentsOf: intermediatePoints)
            }
        }

        let vertices = pointsToRender.map { point -> FTVertex in
            return FTVertex(with: point, color: color, thickness: thickness)
        }

        lastPoint = pointsToRender.last

        vertexBuffer = bufferPool?.dequeueItem()
        vertexBuffer?.set(vertices)
    }

    func draw(currentDrawble: CAMetalDrawable,
              points:[CGPoint],
              color: UIColor,
              thickness: Thickness,
              shouldClear: Bool,
              shouldEnd: Bool,
              isPolygon: Bool) {

        populateVertexBuffer(points: points,
                             color: color,
                             thickness: thickness, isPolygon: isPolygon)

        guard let verticesBuffer = vertexBuffer else { return }

        let commandBuffer = commandQueue.makeCommandBuffer()!;
        commandBuffer.label = "drawBuffer"

        let renderPassDescriptor = MTLRenderPassDescriptor()

        if currentTool == .pen || currentTool == .eraser {
            renderPassDescriptor.colorAttachments[0].texture = self.finalRenderTexture
            if fillWithWhite {
                fillWithWhite = false;
                renderPassDescriptor.colorAttachments[0].loadAction = .clear
                renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1.0, 1.0, 1.0, 1.0)
            } else {
                renderPassDescriptor.colorAttachments[0].loadAction = .load
            }
        } else {
            renderPassDescriptor.colorAttachments[0].texture = self.highlighterTexture
            if shouldClear == true {
                renderPassDescriptor.colorAttachments[0].loadAction = .clear
                renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0)
            } else {
                renderPassDescriptor.colorAttachments[0].loadAction = .load
            }
        }

        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)

        switch currentTool {
        case .pen, .highlighter:
            renderEncoder?.setRenderPipelineState(pipeline_pen)
        case .eraser:
            renderEncoder?.setRenderPipelineState(pipeline_eraser)
        }

        renderEncoder?.setVertexBuffer(verticesBuffer.buffer, offset: 0, index: 0)
        renderEncoder?.setVertexBuffer(mvpBuffer, offset: 0, index: 1)

        renderEncoder?.setFragmentTexture(brushTexture, index: 0)
        renderEncoder?.drawPrimitives(type: .point, vertexStart: 0, vertexCount: verticesBuffer.count)
        renderEncoder?.endEncoding()

        if currentTool == .highlighter {
            if shouldEnd {
                imageEncoder.encode(sourceTexture: self.highlighterTexture,
                                    targetTexture: self.finalRenderTexture,
                                    commandBuffer: commandBuffer)
                FTBlitEncoder.copy(sourceTexture: self.finalRenderTexture,
                                   targetTexture: currentDrawble.texture,
                                   commandBuffer: commandBuffer)
                clear(texture:self.highlighterTexture)
            } else {
                FTBlitEncoder.copy(sourceTexture: self.finalRenderTexture,
                                   targetTexture: currentDrawble.texture,
                                   commandBuffer: commandBuffer)

                imageEncoder.encode(sourceTexture: self.highlighterTexture,
                                    targetTexture: currentDrawble.texture,
                                    commandBuffer: commandBuffer)
            }
        } else {
            FTBlitEncoder.copy(sourceTexture: self.finalRenderTexture,
                               targetTexture: currentDrawble.texture,
                               commandBuffer: commandBuffer)
        }


        commandBuffer.present(currentDrawble)
        commandBuffer.commit();
    }

    func clearAllContents(currentDrawble: CAMetalDrawable) {
        let commandBuffer = commandQueue.makeCommandBuffer()!

        let clearPassDescriptor = MTLRenderPassDescriptor()
        clearPassDescriptor.colorAttachments[0].loadAction = .clear
        clearPassDescriptor.colorAttachments[0].texture = finalRenderTexture
        clearPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1, 1, 1, 1)

        let clearEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: clearPassDescriptor)
        clearEncoder?.endEncoding()

        FTBlitEncoder.copy(sourceTexture: finalRenderTexture,
                           targetTexture: currentDrawble.texture,
                           commandBuffer: commandBuffer)

        commandBuffer.present(currentDrawble)
        commandBuffer.commit()
    }

    func clear(texture: MTLTexture) {
        let commandBuffer = commandQueue.makeCommandBuffer()!

        let clearPassDescriptor = MTLRenderPassDescriptor()
        clearPassDescriptor.colorAttachments[0].loadAction = .clear
        clearPassDescriptor.colorAttachments[0].texture = texture
        clearPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1, 1, 1, 1)

        let clearEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: clearPassDescriptor)
        clearEncoder?.endEncoding()

    }
}

extension DrawRenderer {

    func fillShape(points: [CGPoint], color: UIColor = .red) {
        guard let drawble = metalLayer.nextDrawable() else { fatalError("Drawble doesn't exist") }

        let vertices = points.map { point -> FTVertex in
            return FTVertex(with: point, color: color, thickness: Thickness.small)
        }

        vertexBuffer =  FTMetalBuffer<FTVertex>(vertices: [])
        vertexBuffer?.set(vertices)

        let commandBuffer = commandQueue.makeCommandBuffer()!;
        commandBuffer.label = "fillBuffer"

        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].loadAction = .load
        renderPassDescriptor.colorAttachments[0].texture = self.multiSampleTexture
        renderPassDescriptor.colorAttachments[0].resolveTexture = finalRenderTexture
        renderPassDescriptor.colorAttachments[0].storeAction = .storeAndMultisampleResolve
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        renderEncoder?.setRenderPipelineState(pipeline_fill)

        renderEncoder?.setVertexBuffer(vertexBuffer?.buffer, offset: 0, index: 0)
        renderEncoder?.setVertexBuffer(mvpBuffer, offset: 0, index: 1)

        renderEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
        renderEncoder?.endEncoding()

        FTBlitEncoder.copy(sourceTexture: self.finalRenderTexture,
                           targetTexture: drawble.texture,
                           commandBuffer: commandBuffer)

        commandBuffer.present(drawble)

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

    }
}
