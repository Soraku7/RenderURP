Shader "NRP/Nahida"
{
    Properties
    {
        [Header(Texture)]
        _MainTex ("Texture", 2D) = "white" {}
        _BaseColor("BaseColor", Color) = (1,0,0,1)
        _NormalMap("NormalMap", 2D) = "white" {}

        [Header(Outline)]
        _OutlineCol("OutlineCol", Color) = (1,1,1,1)
        _OutlineWidth("OutlineWidth", Range(0,1)) = 0.1
        
        [Header(CelRender)]
        _ShadowColor("ShadowColor", Color) = (1,1,1,1)
        _ShadowRange("ShadowRange", Range(0,1)) = 0.5
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
            Cull Off

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
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 nDirWS : TEXCOORD1;
                float3 posWS : TEXCOORD2;
                float3 tDirWS : TEXCOORD4;
                float3 bDirWS : TEXCOORD5;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _NormalMap;
            
            half4 _BaseColor;
            
            half3 _ShadowColor;
            float _ShadowRange;

            v2f vert(appdata v)
            {
                v2f o;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);
                o.vertex = vertexInput.positionCS;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.posWS = vertexInput.positionWS;
                o.nDirWS = TransformObjectToWorldNormal(v.normal);
                o.tDirWS = TransformObjectToWorldDir(v.tangent.xyz);
                o.bDirWS = cross(o.nDirWS , o.tDirWS) * v.tangent.w;

                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                Light mainLight = GetMainLight();
                half4 mainTex = tex2D(_MainTex, i.uv);

                half3x3 TBN = half3x3(i.tDirWS , i.bDirWS, i.nDirWS);
                half4 normalMap = tex2D(_NormalMap, i.uv);
                half3 nDirTS = UnpackNormal(normalMap);

                half3 vDirWS = normalize(_WorldSpaceCameraPos - i.posWS.xyz);
                half3 nDirWS = TransformTangentToWorld(nDirTS, TBN, true);
                half3 lDirWS = normalize(mainLight.direction);
                half3 H = normalize(-lDirWS + vDirWS);

                half ndotl = max(0, dot(nDirWS, lDirWS));

                half halfLambort = ndotl * 0.5 + 0.5;
                

                half3 diffuse = halfLambort > _ShadowRange ? _BaseColor : _ShadowColor;
                diffuse *= mainTex;
                half3 col = diffuse * mainLight.color;
                return half4(col, mainTex.a);
            }
            ENDHLSL
        }

        Pass
        {
            Name "Outline"
            Cull Front

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
                VertexNormalInputs normalInputs = GetVertexNormalInputs(v.normal.xyz);
                float4 pos = positionInputs.positionCS;

                //获得屏幕缩放比例
                float4 scaledScreenParams = GetScaledScreenParams();
                float ScaleX = abs(scaledScreenParams.x / scaledScreenParams.y);

                //不光滑物体描边会被截断
                //使用外扩法线将发现数据转入裁剪空间
                // float3 nDirCS = TransformWorldToHClipDir(v.tangent.xyz);
                float3 nDirCS = TransformWorldToHClipDir(normalInputs.normalWS);
                //根据法线计算线宽偏移量
                float2 extendDis = normalize(nDirCS.xy) * (_OutlineWidth * 0.01);
                //偏移量会被拉伸 故使用缩放比例进行修正
                extendDis.x /= ScaleX;
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