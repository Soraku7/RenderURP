Shader "URP/PBR"
{
    Properties
    {
        _AlebdoTex ("Texture", 2D) = "white" {}
        _MetallicTex ("MetallicTex", 2D) = "white" {}
        _RoughnessTex ("RoughnessTex", 2D) = "white" {}
        _NormalTex ("NormalTex", 2D) = "white" {}
        _OcclusionTex ("Occlusion", 2D) = "white" {}
        _EmissionTex ("Emission", 2D) = "black" {}
    }

    SubShader
    {
        Tags
        {
            "Queue"="Geometry"
            "RenderPipeline" = "UniversalPipeline"
        }
        Pass
        {
            Name "URPUnlit"

            Tags
            {
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ EVALUATE_SH_MIXED EVALUATE_SH_VERTEX
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
            #pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 posWS : TEXCOORD1;
                float3 nDirWS : TEXCOORD2;
                float3 tDirWS : TEXCOORD3;
                float3 bDirWS : TEXCOORD4;
            };

            sampler2D _AlebdoTex;
            sampler2D _MetallicTex;
            sampler2D _RoughnessTex;
            sampler2D _NormalTex;
            sampler2D _OcclusionTex;
            sampler2D _EmissionTex;

            v2f vert(appdata v)
            {
                v2f o;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);
                o.vertex = vertexInput.positionCS;
                o.posWS = vertexInput.positionWS;
                o.uv = v.uv;
                o.nDirWS = TransformObjectToWorldNormal(v.normal);
                o.tDirWS = TransformObjectToWorldDir(v.tangent.xyz);
                o.bDirWS = cross(o.nDirWS, o.tDirWS) * v.tangent.w;
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                float3 nDirTS = UnpackNormal(tex2D(_NormalTex, i.uv)).rgb;
                float3x3 TBN = float3x3(i.tDirWS, i.bDirWS, i.nDirWS);
                float3 nDirWS = normalize(mul(nDirTS, TBN));
                float3 vDirWS = normalize(GetCameraPositionWS() - i.posWS);

                float3 vdotn = dot(nDirWS, vDirWS);

                float4 alebdo = tex2D(_AlebdoTex, i.uv);
                float metallic = tex2D(_MetallicTex, i.uv).r;
                float smoothness = 1 - sqrt(tex2D(_RoughnessTex, i.uv)).r;
                float occlusion = tex2D(_OcclusionTex, i.uv).r;
                float emission = tex2D(_EmissionTex, i.uv).r;

                //Dielectric Specular
                float dielectricSpec = 0.04;
                float reflectivity = lerp(dielectricSpec, 1, metallic);
                float grazingTerm = saturate(smoothness + reflectivity);
                float perceptualRoughness = 1 - smoothness;
                float roughness = max(HALF_MIN_SQRT, pow(1 - smoothness, 2));
                float roughnessPow2 = pow(roughness, 2);

                //双向反射
                float3 diffuse = lerp(alebdo.rgb * (1 - dielectricSpec), 0, metallic);
                float3 specular = lerp(dielectricSpec, alebdo, metallic);

                //fressnal
                float fressnal = pow(1 - vdotn, 4);
                specular = lerp(specular, grazingTerm, fressnal);

                half3 finalColor;

                //直接光
                Light lights[MAX_VISIBLE_LIGHTS];
                lights[0] = GetMainLight(TransformWorldToShadowCoord(i.posWS), i.posWS, 1);
                for (int index = 0; index < GetAdditionalLightsCount(); index++)
                {
                    lights[index + 1] = GetAdditionalLight(index, i.posWS, 1);
                }
                int lightCount = 1 + GetAdditionalLightsCount();

                for (int index = 0; index < lightCount; index++)
                {
                    Light light = lights[index];
                    //辐照率与辐射率
                    float3 irradiance = light.color * light.distanceAttenuation * light.shadowAttenuation;
                    float3 radiance = irradiance * saturate(dot(nDirWS, light.direction));

                    float3 h = normalize(vDirWS + light.direction);

                    float ggx = roughnessPow2 / pow(1.0001f + (roughnessPow2 - 1) * pow(saturate(dot(nDirWS, h)), 2),
                        2);
                    //几何遮蔽
                    float G = saturate(dot(nDirWS, light.direction) * dot(nDirWS, vDirWS)) / lerp(
                        roughness, 1, pow(saturate(dot(light.direction, h)), 2));
                    float specularTerm = ggx * G;

                    finalColor += (diffuse * 1 + specular * specularTerm) * radiance;
                }

                //间接光
                float3 diffuseRadiance = SampleSH(nDirWS);
                float mipLevel = perceptualRoughness * (1.7 - 0.7 * perceptualRoughness) * UNITY_SPECCUBE_LOD_STEPS;
                float3 specularRadiance = unity_SpecCube0.SampleLevel(samplerunity_SpecCube0, reflect(-vDirWS, nDirWS),
                    mipLevel);
                float3 specularTerm = 1 / (1 + pow(roughness, 2));

                finalColor += diffuseRadiance * 1 * diffuse + specularRadiance * specularTerm * specular;

                //自发光
                finalColor += emission;

                half4 color = half4(finalColor, 1.0);

                return color;
            }
            ENDHLSL
        }

        UsePass "Universal Render Pipeline/Lit/DEPTHONLY"
        UsePass "Universal Render Pipeline/Lit/SHADOWCASTER"
    }
}