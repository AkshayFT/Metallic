//
//  textureQuad.metal
//  NSMetalRender
//
//  Created by Amar on 20/02/20.
//  Copyright © 2020 Fluid Touch. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct VertexInOut
{
    float4 m_Position [[position]];
    float2 m_TexCoord [[user(texturecoord)]];
};

vertex VertexInOut textureQuadVertex(constant float4         *pPosition   [[ buffer(0) ]],
                                             constant packed_float2  *pTexCoords  [[ buffer(1) ]],
                                             constant float4x4       *pMVP        [[ buffer(2) ]],
                                             uint                     vid         [[ vertex_id ]])
{
    VertexInOut outVertices;

    outVertices.m_Position = pPosition[vid];
    outVertices.m_TexCoord = pTexCoords[vid];

    return outVertices;
}

fragment half4 textureQuadFragment(VertexInOut     inFrag    [[ stage_in ]],
                                           texture2d<half>  tex2D     [[ texture(0) ]])
{
    constexpr sampler quad_sampler(coord::normalized,
                                   address::repeat,
                                   filter::linear);
    half4 color = tex2D.sample(quad_sampler, inFrag.m_TexCoord);

    return color;
}
