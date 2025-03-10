Shader "Effect/CyberPunk"
{
    Properties
    {
        [Header(Texture)]
        _MainTex ("RGB基础颜色 A环境遮罩", 2D) = "white" {}
        _NormalMap ("NormalMap" , 2D) = "white" {}
        _SpecularMap ("RGB高光颜色 A高光次幂" , 2D) = "white" {}
        _EmitTex ("自发光贴图" , 2D) = "black" {}
        _CubeMap ("CubeMap" , CUBE) = "white" {}
        
        [Header(Diffuse)]
        _MainCol ("MainCol" , color) = (1.0 , 1.0 , 1.0 , 1.0) 
        _EnvDiffInt ("环境光漫反射强度" , Range(0 , 1)) = 0.5
        _EnvUpCol ("EnvUpCol" , color) = (1.0 , 1.0 , 1.0 , 1.0)
        _EnvSideCol ("EnvUpCol" , color) = (1.0 , 1.0 , 1.0 , 1.0)
        _EnvDownCol ("EnvDownCol" , color) = (1.0 , 1.0 , 1.0 , 1.0)
        
        [Header(Specular)]
        _SpecularPow ("Specular" , Range(1 , 90)) = 30
        _EnvSpecInt ("环境光镜面反射强度" , Range(0 , 5)) = 0.5
        _FresnelPow ("FresnelPow" , Range(0 , 5)) = 1
        _CubemapMip ("CubemapMip" , Range(0 , 7)) = 1
        
        [Header(Emission)]
        _EmitInt ("EmitInt" , Range(1 , 10)) = 1
        
        [Header(Effect)]
        _EffMap01 ("EffectMap01" , 2D) = "black" {}
        _EffMap02 ("EffectMap02" , 2D) = "black" {}
        [HDR] _EffCol ("EffectColor" , color) = (1.0 , 1.0 , 1.0 , 1.0)
        _EffectParams ("X 波密度 Y 波速度 Z 混乱度 W 消散强度" , Vector) = (0 , 0 , 0 , 0)
    }
    SubShader
    {
        Tags {
            "RenderType"="Transparent"
            "Queue" = "Transparent"
        }
        LOD 100

        Pass
        {
            Name "FORWARD"
            Tags{
                "LightMode" = "ForwardBase"
            }
            Blend One OneMinusSrcAlpha
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"      // 使用Unity投影必须包含这两个库文件
            #include "Lighting.cginc"       // 同上
            #pragma multi_compile_fwdbase_fullshadows
            #pragma target 3.0

            //Texture
            uniform sampler2D _MainTex;
            uniform sampler2D _NormalMap;
            uniform sampler2D _SpecularMap;
            uniform sampler2D _EmitTex;
            uniform samplerCUBE _CubeMap;

            //Diffuse
            uniform float3 _EnvUpCol;
            uniform float3 _EnvSideCol;
            uniform float3 _EnvDownCol;
            uniform float _EnvInt;
            uniform float4 _MainCol;
            uniform float _EnvDiffInt;

            //Specular
            uniform float _SpecularPow;
            uniform float _EnvSpecInt;
            uniform float _FresnelPow;
            uniform float _CubemapMip;

            //Emission
            uniform float _EmitInt;
            
            //Effect
            uniform sampler2D _EffMap01;
            uniform sampler2D _EffMap02;
            uniform float4 _EffCol;
            uniform float4 _EffectParams;
                
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 color : COLOR;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float4 posWS : TEXCOORD2;
                float3 nDirWS : TEXCOORD3;
                float3 tDirWS : TEXCOORD4;
                float3 bDirWS : TEXCOORD5;
                float4 effectMask : TEXCOORD6;

                LIGHTING_COORDS(7 , 8)
            };

            float4 SyberPunckAnim(float noise , float mask , float3 normal , inout float3 vertex)
            {
                //生成锯齿波
                float baseMask = abs(frac(vertex.y * _EffectParams.x -_Time.x * _EffectParams.y) - 0.5) * 2;
                baseMask = min(1 , baseMask * 2);

                //扰动偏移
                baseMask += (noise - 0.5) * _EffectParams.z;

                float4 effectMask = float4(0 , 0 , 0 , 0);
                effectMask.x = smoothstep(0.1 , 0.9 , baseMask);
                effectMask.y = smoothstep(0.2 , 0.7 , baseMask);
                effectMask.z = smoothstep(0.4 , 0.5 , baseMask);

                effectMask.w = mask;

                vertex.xz += normal.xz * (1.0 - effectMask.y)* _EffectParams.w * mask;
                return effectMask;
            }

            v2f vert (appdata v)
            {
                float noise = tex2Dlod(_EffMap02 , float4(v.uv1 , 0 , 0)).r;
                v2f o = (v2f)0;
                o.effectMask = SyberPunckAnim(noise , v.color.r , v.normal.xyz , v.vertex.xyz);
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv0 = v.uv0;
                o.uv1 = v.uv1;
                o.posWS = mul(unity_ObjectToWorld , v.vertex);
                o.nDirWS = UnityObjectToWorldNormal(v.normal);
                o.tDirWS = UnityObjectToWorldDir(v.tangent.xyz);
                o.bDirWS = cross(o.nDirWS , o.tDirWS) * v.tangent.w;

                //投影相关
                TRANSFER_VERTEX_TO_FRAGMENT(o);
                return o;
            }

            fixed4 frag (v2f i) : COLOR
            {
                float3 nDirTS = UnpackNormal(tex2D(_NormalMap , i.uv0)).rgb;
                float3x3 TBN = float3x3(i.tDirWS , i.bDirWS , i.nDirWS);
                float3 nDirWS = mul(TBN , nDirTS);
                float3 vDirWS = normalize(_WorldSpaceCameraPos - i.posWS).xyz;
                float3 vrDirWS = reflect(-vDirWS , nDirWS);
                float3 lDirWS = _WorldSpaceLightPos0.xyz;
                float3 lrDirWS = reflect(-lDirWS , nDirWS);

                float ndotl = dot(nDirWS , lDirWS);
                float vdotr = dot(vDirWS , lrDirWS);
                float vdotn = dot(vDirWS , nDirWS);

                float4 var_MainTedx = tex2D(_MainTex , i.uv0);
                float4 var_SpecularMap = tex2D(_SpecularMap , i.uv0);
                float3 var_EmitTex = tex2D(_EmitTex , i.uv0).rgb;
                float3 var_CubeMap = texCUBE(_CubeMap , float4(vrDirWS , lerp(_CubemapMip , 0.0 , var_SpecularMap.a))).rgb;

                //光源漫反射
                float3 baseCol = var_MainTedx.rgb * _MainCol.rgb;
                float lambort = max(0.0 , ndotl);

                //光源镜面反射
                float specCol = var_SpecularMap.rgb;
                float specPow = lerp(1 , _SpecularPow , var_SpecularMap.a);
                float phong = pow(max(0.0 , vdotr) , specPow);
                
                float shadow = LIGHT_ATTENUATION(i);
                float3 dirLighting = (baseCol * lambort + specCol * phong) * _LightColor0 *shadow;

                //环境漫反射
                float upMask = max(0.0 , nDirWS.g);
                float downMask = max(0.0 , -nDirWS.g);
                float sideMask = 1.0 - upMask - downMask;
                float3 envCol = _EnvUpCol * upMask + _EnvSideCol * sideMask + _EnvDownCol * downMask;

                //环境镜面反射
                float fresnal = pow(max(0.0 , 1.0 - vdotn) , _FresnelPow);
                
                float occlusion = var_MainTedx.a;
                float3 envLighting = (baseCol * envCol  * _EnvDiffInt + var_CubeMap * fresnal * _EnvSpecInt * var_SpecularMap.a) * occlusion;

                //自发光
                float3 emission = var_EmitTex * _EmitInt * (sin(_Time.z) * 0.5 + 0.5);

                //特效
                float3 _Effect01_var = tex2D(_EffMap01 , i.uv1).xyz;
                float meshMask = _Effect01_var.x;
                float faceRandomMask = _Effect01_var.y;
                float faceSlopMask = _Effect01_var.z;

                float smallMask = i.effectMask.x;
                float midMask = i.effectMask.y;
                float bigMask = i.effectMask.z;
                float baseMask = i.effectMask.w;

                float midOpacity = saturate(floor(min(faceRandomMask , 0.9999)+ midMask) );
                float bigOpacity = saturate(floor(min(faceSlopMask , 0.9999)+ bigMask) );
                float opacity = lerp(1.0 , min(bigOpacity , midOpacity) , baseMask);

                float meshEmitInt = (bigMask - smallMask) * meshMask;
                meshEmitInt = pow(meshEmitInt , 2);
                emission += _EffCol * meshEmitInt * baseMask;
                
                float3 final = dirLighting + envLighting + emission;
                
                return float4(final * opacity, opacity);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"

}
