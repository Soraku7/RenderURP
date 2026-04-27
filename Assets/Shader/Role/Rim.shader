Shader "Custom/RimLight"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (1,1,1,1)
        _RimColor ("Rim Color", Color) = (0,1,1,1)
        _RimPower ("Rim Power", Float) = 4.0
        _RimIntensity ("Rim Intensity", Float) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        Pass
        {
            Name "RimLight"
            Tags {"LightMode"="UniversalForward"
                "Queue"="Geometry"
                "RenderType"="Opaque"}
            
            ZTest LEqual 
            ZWrite On          

            Blend One Zero 

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct VertexInput
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
            };

            struct VertexOutput
            {
                float4 positionHCS : SV_POSITION;
                float3 normalWS : TEXCOORD0;
                float3 viewDirWS : TEXCOORD1;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float4 _RimColor;
                float _RimPower;
                float _RimIntensity;
            CBUFFER_END

            VertexOutput vert(VertexInput IN)
            {
                VertexOutput o;
                float4 worldPos = TransformObjectToHClip(IN.positionOS);
                o.positionHCS = worldPos;
                o.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                float3 worldViewDir = _WorldSpaceCameraPos - TransformObjectToWorld(IN.positionOS.xyz);
                o.viewDirWS = normalize(worldViewDir);
                return o;
            }

            half4 frag(VertexOutput i) : SV_Target
            {
                float rim = 1.0 - saturate(dot(normalize(i.normalWS), normalize(i.viewDirWS)));
                rim = pow(rim, _RimPower) * _RimIntensity;
                float3 color = _BaseColor.rgb + _RimColor.rgb * rim;
                return float4(color, 1.0);
            }

            ENDHLSL
        }
    }
}
