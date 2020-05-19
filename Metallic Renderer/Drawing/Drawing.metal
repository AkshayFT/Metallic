//
//  Drawing.metal
//  Metallic
//
//  Created by Akshay on 20/09/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct InVertex {
    float2 position;
    float4 color;
    int thickness;
};

struct OutVertex {
    float4 position [[position]];
    float thickness [[point_size]];
    float4 color;
};

vertex OutVertex
drawVertexShader(uint vertexID [[ vertex_id ]],
                        constant InVertex *vertices [[ buffer(0) ]],
                        constant float4x4 &mvp_matrix [[ buffer(1) ]]) {
    OutVertex out;

    InVertex inVertex = vertices[vertexID];

    float2 pixelSpacePosition = inVertex.position.xy;
    out.position = float4(pixelSpacePosition,0,1)*mvp_matrix;
    out.color = inVertex.color;
    out.thickness = inVertex.thickness;
    return out;
}

fragment float4
drawFragmentShader(OutVertex in [[ stage_in ]],
                   float2 pointCoordinates [[ point_coord ]],
                   texture2d<float> brushTexture [[ texture(0) ]]) {
    constexpr sampler textureSampler (coord::normalized,
                                      address::repeat,
                                      filter::linear);

    return brushTexture.sample(textureSampler, pointCoordinates)*in.color;
}

fragment float4
drawHighlighterFragmentShader(OutVertex in [[ stage_in ]],
                   float2 pointCoordinates [[ point_coord ]],
                   texture2d<float> brushTexture [[ texture(0) ]]) {
    constexpr sampler textureSampler (coord::normalized,
                                      address::repeat,
                                      filter::linear);

    return brushTexture.sample(textureSampler, pointCoordinates)*in.color*0.5;
}


vertex OutVertex
fillVertexShader(uint vertexID [[vertex_id]],
             constant InVertex *vertices [[buffer(0)]],
                 constant float4x4 &mvp_matrix [[ buffer(1) ]]) {
    OutVertex out;
    
    InVertex inVertex = vertices[vertexID];
    
    float2 pixelSpacePosition = inVertex.position.xy;
    out.position = float4(pixelSpacePosition,0,1)*mvp_matrix;
    out.color = inVertex.color;
    out.thickness = inVertex.thickness;
    return out;
}

fragment float4 fillFragmentShader(OutVertex in [[stage_in]])
{
    return in.color;
}
