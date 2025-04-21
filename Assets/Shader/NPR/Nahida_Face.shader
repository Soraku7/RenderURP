Shader "NRP/Nahida_Face"
{
    Properties
    {
        [Header(Texture)]
        _BaseTex ("Texture", 2D) = "white" {}
        _BaseTexFra ("BaseTexFra" , Range(0 , 1)) = 1
        _ToonTex("ToonTex", 2D) = "white" {}
        _ToonTexFra("ToonTexFra", Range(0, 1)) = 1
        _RampTex("RampTex", 2D) = "white" {}
        _ShadowTex("R , G: 黑色不受sdf控制白色受到sdf控制 A:黑色为受到阴影 白色为不受阴影", 2D) = "white" {}
        
        [Header(Diffuse)]
        _AmbientCol("AmbientColor", Color) = (1,1,1,1)
        _DiffuseCol("DiffuseColor", Color) = (1,1,1,1)
        _ShadowCol("ShadowColor", Color) = (1,1,1,1)
        
        [Header(Ramp)]
        _RampRow("RampRow", Range(0, 10)) = 1
        
        [Header(SDF)]
        _SDF("SDFTex", 2D) = "white" {}
        _ForwardVector("ForwardVector", Vector) = (0, 0, 1, 0)
        _RightVector("RightVector", Vector) = (1, 0, 0, 0)
        
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
                half fogFactor : TEXCOORD3;
            };

            sampler2D _BaseTex;
            float4 _BaseTex_ST;
            float _BaseTexFra;
            sampler2D _NormalMap;
            sampler2D _ToonTex;
            float _ToonTexFra;
            sampler2D _RampTex;
            sampler2D _ShadowTex;

            half4 _AmbientCol;
            half4 _DiffuseCol;
            half4 _ShadowCol;

            half _RampRow;

            sampler2D _SDF;
            float4 _ForwardVector;
            float4 _RightVector;

            v2f vert(appdata v)
            {
                v2f o;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);
                o.vertex = vertexInput.positionCS;
                o.uv = TRANSFORM_TEX(v.uv, _BaseTex);
                o.posWS = vertexInput.positionWS;
                o.nDirWS = TransformObjectToWorldNormal(v.normal);
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                Light mainLight = GetMainLight();
                half3 nDirWS = normalize(i.nDirWS);
                half3 nDirVS = normalize(mul(UNITY_MATRIX_V , nDirWS));
                half3 lDirWS = normalize(mainLight.direction);
                half3 vDirWS = normalize(_WorldSpaceCameraPos - i.posWS.xyz);

                half ndotv = dot(nDirWS, vDirWS);

                half2 matcapUV = nDirVS.rg * 0.5 + 0.5;
                
                float4 baseTex = tex2D(_BaseTex, i.uv);
                float4 toonTex = tex2D(_ToonTex, matcapUV);
                
                half3 baseCol = _AmbientCol.rgb;
                baseCol = saturate(lerp(baseCol , baseCol + _DiffuseCol , 0.6));
                baseCol = lerp(baseCol , baseCol * baseTex.rgb , _BaseTexFra);
                baseCol = lerp(baseCol , baseCol * toonTex.rgb , _ToonTexFra);

                //皮肤一般使用第二行
                float rampV = _RampRow / 10 - 0.05;
                float rampClampMin = 0.003;
                float2 rampUV = float2(rampClampMin , 1 - rampV);
                float2 rampUVNight = float2(rampClampMin , 1 - (rampV + 0.5));

                float isDay = (lDirWS.y + 1) / 2;
                float rampCol = lerp(tex2D(_RampTex , rampUVNight).rgb , tex2D(_RampTex , rampUV).rgb , isDay);

                float3 forwardVec = _ForwardVector;
                float3 rightVec = _RightVector;

                float3 upVector = cross(forwardVec , rightVec);
                //光线在上向量上的投影
                float3 LpU = length(lDirWS) * (dot(lDirWS, upVector) / (length(lDirWS) * length(upVector))) * (upVector
                    / length(upVector));
                //头部朝向光方向向量
                float3 LpHeadHorizon = lDirWS - LpU;

                //脸部右侧向量点乘光线方向向量 结果0-0.5则为左侧 0.5-1为右侧
                //此处仅能判断面向头部正面方向 后方向无法判断
                float value = acos(dot(normalize(LpHeadHorizon) , normalize(rightVec))) / PI;
                float exposeRight = step(value , 0.5);

                //将值映射成0-1
                float valueR = pow(1 - value * 2 , 3);
                float valueL = pow(value * 2 - 1 , 3);
                float mixValue = lerp(valueL , valueR , exposeRight);

                float sdfRambrandLeft = tex2D(_SDF , float2(1 - i.uv.x , i.uv.y)).r;
                float sdfRambrandRight = tex2D(_SDF , i.uv).r;
                float mixSDF = lerp(sdfRambrandRight , sdfRambrandLeft , exposeRight);

                //value小于灰度值则为亮部
                float sdf = step(mixValue , mixSDF);
                //判断光照是否在脑后
                sdf = lerp(0 , sdf , step(0 , dot(normalize(LpHeadHorizon) , normalize(forwardVec))));

                float4 shadowTex = tex2D(_ShadowTex , i.uv);
                sdf *= shadowTex.r;
                sdf = lerp(sdf , 1 , shadowTex.a);

                float3 shadowCol = baseCol * rampCol * _ShadowCol.rgb;

                float3 diffuse = lerp(shadowCol , baseCol , sdf);

                float3 albedo = diffuse;

                float alpha = baseTex.a * toonTex.a;

                float4 col = float4(albedo, alpha);
                col.rgb = MixFog(col.rgb , i.fogFactor);
                
                return col;
            }
            ENDHLSL
        }

    }
}