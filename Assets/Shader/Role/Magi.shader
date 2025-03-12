Shader "Unlit/Dota2/Magi"
{
    Properties
    {
        [Header(Texture)]
        _MainTex ("RGB基础颜色 , A透贴", 2D) = "white" {}
        _MaskTex ("R高光强度 G边缘光强度 B高光染色 A 高光次幂" , 2D) = "black" {}
        _NormalMap ("NormalMap" , 2D) = "white" {}
        _MatlnessMask ("金属度遮罩" , 2D) = "black" {}
        _EmissionMask ("自发光遮罩" , 2D) = "black" {}
        _DiffWarpTex ("颜色Warp图" , 2D) = "black" {}
        _FressnalMap ("菲涅尔Warp图" , 2D) = "black" {}
        _CubeMap ("CubeMap" , CUBE) = "_Skybox" {}
        
        [Header(Light)]
        _LightColor ("LightColor" , Color) = (1 , 1 , 1 , 1)
        
        [Header(Specular)]
        _SpecPow ("高光次幂" , range(0.0 , 30.0)) = 5.0
        _SpecInt ("高光强度" , range(0.0 , 10.0)) = 5.0
        
        [Header(Environment)]
        _EnvColor ("环境光颜色" , Color) = (1 , 1 , 1 , 1)
        _EnvSpecInt ("环境高光强度" , range(0.0 , 100.0)) = 50.0
        
        [Header(RimLight)]
        _RimColor ("边缘光颜色" , Color) = (1 , 1 , 1 , 1)
        _RimInt ("边缘光强度" , range(0.0 , 50.0)) = 1.0
        
        [Header(Emit)]
        _EmitInt ("自发光强度" , range(0.0 , 10.0)) = 1.0
        
        [HideInInspector] _Cutoff ("Alpha Cutoff" , Range(0.0 , 1.0)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Name "FORWARD"
            Tags{
                "LightMode" = "UniversalForward"
            }
            Cull Off
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
            uniform sampler2D _MaskTex;
            uniform sampler2D _NormalMap;
            uniform sampler2D _MatlnessMask;
            uniform sampler2D _EmissionMask;
            uniform sampler2D _DiffWarpTex;
            uniform sampler2D _FressnalMap;
            uniform samplerCUBE _CubeMap;

            //Light
            uniform half3 _LightColor;

            //Specular
            uniform half _SpecPow;
            uniform half _SpecInt;

            //Environment
            uniform half3 _EnvColor;
            uniform half _EnvSpecInt;

            //RimLight
            uniform half3 _RimColor;
            uniform half _RimInt;

            //Emit
            uniform half _EmitInt;

            //Other
            uniform half _Cutoff;
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv0 : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float4 posWS : TEXCOORD1;
                float3 nDirWS : TEXCOORD2;
                float3 tDirWS : TEXCOORD3;
                float3 bDirWS : TEXCOORD4;

                LIGHTING_COORDS(5 , 6)
            };



            v2f vert (appdata v)
            {
                v2f o = (v2f)0;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv0 = v.uv0;
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
                //向量
                half3 nDirTS = UnpackNormal(tex2D(_NormalMap , i.uv0));
                half3x3 TBN = half3x3(i.tDirWS , i.bDirWS , i.nDirWS);
                half3 nDirWS = mul(TBN , nDirTS);
                half3 vDirWS = normalize(UnityWorldSpaceViewDir(i.posWS));
                half3 vrDirWS = reflect(-vDirWS , nDirWS);
                half3 lDirWS = _WorldSpaceLightPos0.xyz;
                half3 lrDirWS = reflect(-lDirWS , nDirWS);
                
                half ndotl = dot(nDirWS , lDirWS);
                half ndotv = dot(nDirWS , vDirWS);
                half vdotr = dot(vDirWS , lrDirWS);

                //纹理
                half4 var_MainTex = tex2D(_MainTex , i.uv0);
                half4 var_MaskTex = tex2D(_MaskTex , i.uv0);
                half var_MatlnessMask = tex2D(_MatlnessMask , i.uv0).r;
                half var_EmissionMask = tex2D(_EmissionMask , i.uv0).r;
                half3 var_FressWarpTex = tex2D(_FressnalMap , ndotv);
                half3 var_Cubemap = texCUBE(_CubeMap , float4(vrDirWS , lerp(8.0 , 0.0 , var_MaskTex.a))).rgb;

                half3 baseCol = var_MainTex.rgb;
                half opacity = var_MainTex.a;
                half specInt = var_MaskTex.r;
                //轮廓光强度
                half rimInt = var_MaskTex.g;
                half specTint = var_MaskTex.b;
                half specPow = var_MaskTex.a;
                half matellic = var_MatlnessMask;
                half emitInt = var_EmissionMask;
                half3 envCube = var_Cubemap;
                half shadow = SHADOW_ATTENUATION(i);
                
                half3 diffCol = lerp(baseCol , half3(0.0 , 0.0 , 0.0) , matellic);
                half3 specCol = lerp(baseCol , half3(0.3 , 0.3 , 0.3) , specTint);

                half3 fresnel = lerp(var_FressWarpTex , half3(0.0 , 0.0 , 0.0) , matellic);

                //R 菲涅尔颜色 G 轮廓光菲涅尔 B 高光菲涅尔   
                half fresnelCol = fresnel.r;
                half fresnelRim = fresnel.g;
                half fresnelSpec = fresnel.b;

                //光源漫反射
                half halflambort = ndotl * 0.5 + 0.5;
                half3 var_DiffWarpTex = tex2D(_DiffWarpTex , half2(halflambort , 0.2)).rgb;
                half3 dirDiff = diffCol * var_DiffWarpTex * _LightColor;

                //光源镜面反射
                half phong = pow(max(0.0 , vdotr) , specPow);
                half spec = phong * max(0.0 , ndotl);
                half3 dirSpec = max(spec , fresnelSpec) * specInt;

                //环境漫反射
                half3 envDiff = diffCol * _EnvColor;

                //环境镜面反射
                half reflectInt = max(fresnelSpec , matellic) * specInt;
                half3 envSpec = specCol  * reflectInt * envCube * _EnvSpecInt;

                //轮廓光
                half3 rimLight = _RimColor * fresnelRim * rimInt * max(0.0 , nDirWS.g);

                //自发光
                half3 emission = diffCol * emitInt * _EmitInt;

                half3 finalColor = (dirSpec + dirDiff) * shadow + (envDiff + envSpec) + rimLight + emission;

                //透明剪切
                clip(opacity - _Cutoff);
                
                return float4(finalColor, 1.0);
                // return float4(shadow , shadow , shadow , 1.0);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"

}
