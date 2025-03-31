Shader "URP/Jade1"
{
    Properties
    {
        _Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
        _Specular ("Specular", Color) = (1, 1, 1, 1)
        _Gloss ("Gloss", Range(8.0, 256)) = 20
        [Toggle(_AdditionalLights)] _AddLights ("AddLights", Float) = 1
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }
        
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        
        CBUFFER_START(UnityPerMaterial)
        float4 _Diffuse;
        float4 _Specular;
        float _Gloss;
        CBUFFER_END
        ENDHLSL
        
        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            
            HLSLPROGRAM
            
            #pragma shader_feature _AdditionalLights
            
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            
            struct appdata
            {
                float4 pos: POSITION;
                float3 normal: NORMAL;
            };
            
            struct v2f
            {
                float4 pos: SV_POSITION;
                float3 positionWS: TEXCOORD0;
                float3 normal: TEXCOORD1;
            };
            
            
            v2f vert(appdata v)
            {
                v2f o;
                // 获取不同空间下坐标信息
                VertexPositionInputs positionInputs = GetVertexPositionInputs(v.pos.xyz);
                o.pos = positionInputs.positionCS;
                o.positionWS = positionInputs.positionWS;
                
                o.normal = TransformObjectToWorldNormal(v.normal);
                
                
                return o;
            }
            
            /// lightColor：光源颜色
            /// lightDirectionWS：世界空间下光线方向
            /// lightAttenuation：光照衰减
            /// normalWS：世界空间下法线
            /// viewDirectionWS：世界空间下视角方向
            half3 LightingBased(half3 lightColor, half3 lightDirectionWS, half lightAttenuation, half3 normalWS)
            {
                // 兰伯特漫反射计算
                half NdotL = saturate(dot(normalWS, lightDirectionWS));
                half3 radiance = lightColor * (lightAttenuation * NdotL) * _Diffuse.rgb;
                
                
                return radiance;
            }

            half3 LightingBased(Light light, half3 normalWS)
            {
                // 注意light.distanceAttenuation * light.shadowAttenuation，这里已经将距离衰减与阴影衰减进行了计算
                return LightingBased(light.color, light.direction, light.distanceAttenuation * light.shadowAttenuation, normalWS);
            }
            
            half4 frag(v2f i): SV_Target
            {
                half3 normalWS = NormalizeNormalPerPixel(i.normal);
                
                // 使用HLSL的函数获取主光源数据
                Light mainLight = GetMainLight();
                half3 diffuse = LightingBased(mainLight, normalWS);
                
                // 计算其他光源
                #ifdef _AdditionalLights
                    uint pixelLightCount = GetAdditionalLightsCount();
                    for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++ lightIndex)
                    {
                        // 获取其他光源
                        Light light = GetAdditionalLight(lightIndex, i.positionWS);
                        diffuse += LightingBased(light, normalWS);
                    }
                #endif
                
                // 采用球谐光照计算环境光
                half3 ambient = SampleSH(normalWS);
                return half4(ambient + diffuse, 1.0);
            }
            
            ENDHLSL
            
        }
    }
    FallBack "Packages/com.unity.render-pipelines.universal/FallbackError"
}
