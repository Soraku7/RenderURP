Shader "NRP/Outline"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BaseColor("BaseColor", Color) = (1,0,0,1)
        
        [Header(Outline)]
        _OutlineCol("OutlineCol", Color) = (1,1,1,1)  
        _OutlineWidth("OutlineWidth", Range(0,1)) = 0.1  
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

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            half4 _BaseColor;

            v2f vert(appdata v)
            {
                v2f o;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);
                o.vertex = vertexInput.positionCS;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                half4 texColor = tex2D(_MainTex, i.uv);
                half3 color = texColor.rgb * _BaseColor.rgb;
                return half4(color, texColor.a);
            }
            ENDHLSL
        }

        Pass
        {
            Cull Front
            Name "Outline"

            Stencil
            {
                Ref 250
                Comp NotEqual
            }

            Tags
            {
                //URP描边标签
                "LightMode" = "SRPDefaultUnlit"
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            float4 _OutlineCol;
            float _OutlineWidth;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
            };


            v2f vert(appdata v)
            {
                v2f o;

                VertexPositionInputs positionInputs = GetVertexPositionInputs(v.vertex.xyz);
                float4 pos = positionInputs.positionCS;

                //获得屏幕缩放比例
                float4 scaledScreenParams = GetScaledScreenParams();
                float ScaleX = abs(scaledScreenParams.x / scaledScreenParams.y);

                //不光滑物体描边会被截断
                //使用外扩法线将发现数据转入裁剪空间
                float3 nDirCS = TransformObjectToHClip(v.tangent.xyz);
                //根据法线计算线宽偏移量
                float2 extendDis = normalize(nDirCS.xy) * (_OutlineWidth*0.01);
                //偏移量会被拉伸 故使用缩放比例进行修正
                extendDis.x /= ScaleX ;
                //屏幕下描边宽度不变，则需要顶点偏移的距离在NDC坐标下为固定值
                //因为后续会转换成NDC坐标，会除w进行缩放，所以先乘一个w，那么该偏移的距离就不会在NDC下有变换
                pos.xy += extendDis * pos.w;
                o.pos = pos;
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                return _OutlineCol;
            }
            ENDHLSL
        }
    }

    FallBack "Hidden/Universal Render Pipeline/FallbackError"

}