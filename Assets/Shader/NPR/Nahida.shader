Shader "NRP/Nahida"
{
    Properties
    {
        [Header(Texture)]
        _BaseTex ("Texture", 2D) = "white" {}
        _BaseTexFra ("BaseTexFra" , Range(0 , 1)) = 1
        _NormalMap("NormalMap", 2D) = "white" {}
        _ToonTex("ToonTex", 2D) = "white" {}
        _ToonTexFra("ToonTexFra", Range(0, 1)) = 1
        _LightMap("LightMap ,R:高光强度 G:灰色接受光照 黑色白色不接受光照 B:高光细节 A:传入材质信息", 2D) = "white" {}
        _RampTex("RampTex", 2D) = "white" {}
        _MatcapTex("MatcapTex", 2D) = "white" {}
        
        [Header(RampMap)]
        _RampMapRow0 ("RampMapRow0", Range(1 , 5)) = 1
        _RampMapRow1 ("RampMapRow1", Range(1 , 5)) = 4
        _RampMapRow2 ("RampMapRow2", Range(1 , 5)) = 3
        _RampMapRow3 ("RampMapRow3", Range(1 , 5)) = 5
        _RampMapRow4 ("RampMapRow4", Range(1 , 5)) = 2
        
        [Header(Diffuse)]
        _AmbientCol("AmbientColor", Color) = (1,1,1,1)
        _DiffuseCol("DiffuseColor", Color) = (1,1,1,1)
        
        [Header(Specular)]
        _SpecularPow("Specular", Range(1, 100)) = 30
        _KsNoMatallic("KsNoMat", Range(0.1, 5)) = 1
        _KsMatallic("KsMat", Range(1, 90)) = 30

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

                half fogFactor : TEXCOORD6;
            };

            sampler2D _BaseTex;
            float4 _BaseTex_ST;
            float _BaseTexFra;
            sampler2D _NormalMap;
            sampler2D _ToonTex;
            float _ToonTexFra;
            sampler2D _LightMap;
            sampler2D _RampTex;
            sampler2D _MatcapTex;

            float _RampTexRow0;
            float _RampTexRow1;
            float _RampTexRow2;
            float _RampTexRow3;
            float _RampTexRow4;
            
            half4 _AmbientCol;
            half4 _DiffuseCol;

            half _SpecularPow;
            half _KsNoMatallic;
            half _KsMatallic;
            
            half3 _ShadowColor;
            float _ShadowRange;

            v2f vert(appdata v)
            {
                v2f o;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);
                o.vertex = vertexInput.positionCS;
                o.uv = TRANSFORM_TEX(v.uv, _BaseTex);
                o.posWS = vertexInput.positionWS;
                o.nDirWS = TransformObjectToWorldNormal(v.normal);
                o.tDirWS = TransformObjectToWorldDir(v.tangent.xyz);
                o.bDirWS = cross(o.nDirWS , o.tDirWS) * v.tangent.w;

                o.fogFactor = ComputeFogFactor(o.posWS.z);

                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                Light mainLight = GetMainLight();
                half4 normalMap = tex2D(_NormalMap, i.uv);
                half4 lightMap = tex2D(_LightMap, i.uv);

                half3x3 TBN = half3x3(i.tDirWS , i.bDirWS, i.nDirWS);
                
                half3 nDirTS = UnpackNormal(normalMap);
                half3 nDirWS = normalize(mul(nDirTS, TBN));
                half3 nDirVS = normalize(mul(UNITY_MATRIX_V , nDirWS));
                half3 vDirWS = normalize(_WorldSpaceCameraPos - i.posWS.xyz);
                half3 lDirWS = normalize(mainLight.direction);
                half3 hDirWS = normalize(lDirWS + vDirWS);

                half ndotl = max(0, dot(nDirWS, lDirWS));
                half ndoth = max(0, dot(nDirWS, hDirWS));

                half halfLambort = pow(ndotl * 0.5 + 0.5 , 2);
                half lambortStep = smoothstep(0.432 , 0.450 , halfLambort);

                half2 matcapUV = nDirVS.rg * 0.5 + 0.5;
                
                float4 baseTex = tex2D(_BaseTex, i.uv);
                float4 toonTex = tex2D(_ToonTex, matcapUV);
                float4 matCapTex = tex2D(_MatcapTex, matcapUV);

                float matEnum0 = 0.0;
                float matEnum1 = 0.3;
                float matEnum2 = 0.5;
                float matEnum3 = 0.7;
                float matEnum4 = 1.0;

                float ramp0 = _RampTexRow0/10 - 0.05;
                float ramp1 = _RampTexRow1/10 - 0.05;
                float ramp2 = _RampTexRow2/10 - 0.05;
                float ramp3 = _RampTexRow3/10 - 0.05;
                float ramp4 = _RampTexRow4/10 - 0.05;

                //判断要采样哪一个RampTex
                float dayRampV = lerp(ramp4 , ramp3 , step(lightMap.a , (matEnum3 + matEnum4) / 2));
                dayRampV = lerp(dayRampV , ramp2 , step(lightMap.a , (matEnum2 + matEnum3) / 2));
                dayRampV = lerp(dayRampV , ramp1 , step(lightMap.a , (matEnum1 + matEnum2) / 2));
                dayRampV = lerp(dayRampV , ramp0 , step(lightMap.a , (matEnum0 + matEnum1) / 2));
                float nightRampV = dayRampV + 0.5;

                //用半兰伯特采样阴影的U坐标
                //防止采样到图片边缘
                float rampClampMin = 0.003;
                float rampCalampMax = 0.997;

                float rampU = clamp(smoothstep(0.2 , 0.4 , halfLambort), rampClampMin , rampCalampMax);
                //UnityUV坐标原点在左下角 V轴需要反向
                float2 rampUV = float2(rampU , 1 - dayRampV);
                float2 rampUVNight = float2(rampU , 1 - nightRampV);

                float rampDarkU = rampClampMin;
                float2 rampDarkUV = float2(rampDarkU , 1 - dayRampV);
                float2 rampDarkUVNight = float2(rampDarkU , 1 - nightRampV);

                float isDay = (lDirWS.y + 1) / 2;
                float3 rampCol = lerp(tex2D(_RampTex , rampUVNight).rgb , tex2D(_RampTex , rampUV).rgb , isDay);
                float3 rampDarkCol = lerp(tex2D(_RampTex , rampDarkUVNight).rgb , tex2D(_RampTex , rampDarkUV).rgb , isDay);
                
                half3 baseCol = _AmbientCol.rgb;
                baseCol = saturate(lerp(baseCol , baseCol + _DiffuseCol , 0.6));
                baseCol = lerp(baseCol , baseCol * baseTex.rgb , _BaseTexFra);
                baseCol = lerp(baseCol , baseCol * toonTex.rgb , _ToonTexFra);

                float3 shadowCol = baseCol * rampCol * _ShadowColor.rgb;
                float3 darkshadowCol = baseCol * rampDarkCol * _ShadowColor.rgb;

                float3 diffuse = 0;
                diffuse = lerp(shadowCol , baseCol , lambortStep);
                diffuse = lerp(darkshadowCol , diffuse , saturate(lightMap.g * 2));
                diffuse = lerp(diffuse , baseCol , saturate(lightMap.g - 0.5) * 2);

                float blinnPhong = step(0 , ndotl) * pow(ndoth , _SpecularPow);
                //设置1.04是防止采样到黑色的高光贴图
                float3 noMatallicSpec = step(1.04 - blinnPhong , lightMap.b) * lightMap.r * _KsNoMatallic;
                float3 matallicSpec = blinnPhong * lightMap.b * (lambortStep * 0.8 + 0.2) * baseCol * _KsMatallic;

                //取出金属高光区域
                float isMatallic = step(0.95 , lightMap.r);

                float3 specular = lerp(noMatallicSpec , matallicSpec , isMatallic);

                float3 matallic = lerp(0 , matCapTex.r * baseCol , isMatallic);

                float3 alebdo = diffuse + specular + matallic;

                float alpha = baseTex.a * toonTex.a;
                float4 col = float4(alebdo, alpha);
                col.rgb = MixFog(col.rgb , i.fogFactor);
                
                return col;
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