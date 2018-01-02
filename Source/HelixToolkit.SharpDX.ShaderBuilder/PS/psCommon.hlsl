#ifndef PSCOMMON_HLSL
#define PSCOMMON_HLSL
#define MATERIAL

#include"..\Common\Common.hlsl"
#include"..\Common\DataStructs.hlsl"


//--------------------------------------------------------------------------------------
// normal mapping
//--------------------------------------------------------------------------------------
// This function returns the normal in world coordinates.
// The input struct contains tangent (t1), bitangent (t2) and normal (n) of the
// unperturbed surface in world coordinates. The perturbed normal in tangent space
// can be read from texNormalMap.
// The RGB values in this texture need to be normalized from (0, +1) to (-1, +1).
float3 calcNormal(PSInput input)
{
    if (bHasNormalMap)
    {
		// Normalize the per-pixel interpolated tangent-space
        input.n = normalize(input.n);
        input.t1 = normalize(input.t1);
        input.t2 = normalize(input.t2);

		// Sample the texel in the bump map.
        float4 bumpMap = texNormalMap.Sample(samplerNormal, input.t);
		// Expand the range of the normal value from (0, +1) to (-1, +1).
        bumpMap = (bumpMap * 2.0f) - 1.0f;
		// Calculate the normal from the data in the bump map.
        input.n = input.n + bumpMap.x * input.t1 + bumpMap.y * input.t2;
    }
    return normalize(input.n);
}

//--------------------------------------------------------------------------------------
// Blinn-Phong Lighting Reflection Model
//--------------------------------------------------------------------------------------
// Returns the sum of the diffuse and specular terms in the Blinn-Phong reflection model.
float4 calcBlinnPhongLighting(float4 LColor, float4 vMaterialTexture, float3 N, float4 diffuse, float3 L, float3 H)
{
    float4 Id = vMaterialTexture * diffuse * saturate(dot(N, L));
    float4 Is = vMaterialSpecular * pow(saturate(dot(N, H)), sMaterialShininess);
    return (Id + Is) * LColor;
}


//--------------------------------------------------------------------------------------
// reflectance mapping
//--------------------------------------------------------------------------------------
float4 cubeMapReflection(PSInput input, float4 I)
{
    float3 v = normalize((float3) input.wp - vEyePos);
    float3 r = reflect(v, input.n);
    return (1.0f - vMaterialReflect) * I + vMaterialReflect * texCubeMap.Sample(samplerCube, r);
}



float lookUp(in float4 loc, in float2 offset)
{
    return texShadowMap.SampleCmpLevelZero(samplerShadow, loc.xy + offset, loc.z);
}

//--------------------------------------------------------------------------------------
// get shadow color
//--------------------------------------------------------------------------------------
float shadowStrength(float4 sp)
{
    sp = sp / sp.w;
    if (sp.x < -1.0f || sp.x > 1.0f || sp.y < -1.0f || sp.y > 1.0f || sp.z < 0.0f || sp.z > 1.0f)
    {
        return 1;
    }
    sp.x = sp.x / 2 + 0.5f;
    sp.y = sp.y / -2 + 0.5f;

	//apply shadow map bias
    sp.z -= vShadowMapInfo.z;

	//// --- not in shadow, hard cut
    //float shadowMapDepth = texShadowMap.Sample(PointSampler, sp.xy+offsets[1]).r;
    //return whengt(shadowMapDepth, sp.z);

	//// --- basic hardware PCF - single texel
    //float shadowFactor = texShadowMap.SampleCmpLevelZero(samplerShadow, sp.xy, sp.z).r;

	//// --- PCF sampling for shadow map
    float sum = 0;
    float x = 0, y = 0;
    const float range = 1.5;
    float2 scale = 1 / vShadowMapSize;

	//// ---perform PCF filtering on a 4 x 4 texel neighborhood
	[unroll]
    for (y = -range; y <= range; y += 1.0f)
    {
        for (x = -range; x <= range; x += 1.0f)
        {
            sum += lookUp(sp, float2(x, y) * scale);
        }
    }

    float shadowFactor = sum / 16;

    float fixTeil = vShadowMapInfo.x;
    float nonTeil = 1 - vShadowMapInfo.x;
	// now, put the shadow-strengh into the 0-nonTeil range
    nonTeil = shadowFactor * nonTeil;
    return (fixTeil + nonTeil);
}

#endif