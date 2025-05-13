Shader "URP/Sea"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NormalMap ("Normal", 2D) = "white" {}

        _BaseColor("BaseColor", Color) = (1,0,0,1)
    }

    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "RenderType" = "Transparent"
            "RenderPipeline" = "UniversalPipeline"

        }
        Pass
        {
            Name "URPUnlit"

            Tags
            {
                "LightMode" = "UniversalForward"
            }

            Blend SrcAlpha OneMinusDstAlpha

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

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
                float3 nDirWS : TEXCOORD1;
                float3 tDirWS : TEXCOORD2;
                float3 bDirWS : TEXCOORD3;
                float4 screenPos : TEXCOORD4;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _NormalMap;
            sampler2D _ReflectTex;

            float _reflectionFactor;


            half4 _BaseColor;


            float2 Panner(float2 uv, float2 direction, float2 speed)
            {
                return uv + normalize(direction) * speed * _Time.y;
            }

            float3 MotionFourWayChaos(sampler2D tex, float2 uv, float speed, bool unpackNormal)
            {
                float2 uv1 = Panner(uv + float2(0.000, 0.000), float2(0.1, 0.1), speed);
                float2 uv2 = Panner(uv + float2(0.418, 0.355), float2(-0.1, -0.1), speed);
                float2 uv3 = Panner(uv + float2(0.865, 0.148), float2(-0.1, 0.1), speed);
                float2 uv4 = Panner(uv + float2(0.651, 0.752), float2(0.1, -0.1), speed);

                float3 sample1;
                float3 sample2;
                float3 sample3;
                float3 sample4;

                if (unpackNormal)
                {
                    sample1 = UnpackNormal(tex2D(tex, uv1)).rgb;
                    sample2 = UnpackNormal(tex2D(tex, uv2)).rgb;
                    sample3 = UnpackNormal(tex2D(tex, uv3)).rgb;
                    sample4 = UnpackNormal(tex2D(tex, uv4)).rgb;

                    return normalize(sample1 + sample2 + sample3 + sample4);
                }
                else
                {
                    sample1 = tex2D(tex, uv1).rgb;
                    sample2 = tex2D(tex, uv2).rgb;
                    sample3 = tex2D(tex, uv3).rgb;
                    sample4 = tex2D(tex, uv4).rgb;

                    return (sample1 + sample2 + sample3 + sample4) / 4.0;
                }
            }

            v2f vert(appdata v)
            {
                v2f o;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);
                o.vertex = vertexInput.positionCS;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.nDirWS = TransformObjectToWorldNormal(v.normal);
                o.tDirWS = TransformObjectToWorldDir(v.tangent.xyz);
                o.bDirWS = cross(o.nDirWS, o.tDirWS) * v.tangent.w;

                o.screenPos = ComputeScreenPos(v.vertex);
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                half4 texColor = tex2D(_MainTex, i.uv);
                half4 normalMap = tex2D(_NormalMap, i.uv);

                half3x3 TBN = half3x3(i.tDirWS, i.bDirWS, i.nDirWS);

                half3 nDirTS = UnpackNormal(normalMap);
                half3 nDirWS = normalize(mul(nDirTS, TBN));

                half2 screenUV = half2( 1 - i.screenPos.x  , i.screenPos.y);
                half3 col = tex2D(_ReflectTex, i.uv);
                half3 color = texColor.rgb * _BaseColor.rgb;

                return half4(col, 1.0);
            }
            ENDHLSL
        }

    }
}