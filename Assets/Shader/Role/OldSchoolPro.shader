Shader "Unlit/OldSchoolPro"
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
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Name "FORWARD"
            Tags{
                "LightMode" = "ForwardBase"
            }
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
                float3 emission = var_EmitTex * _EmitInt;

                float3 final = dirLighting + envLighting + emission;
                
                return float4(final, 1.0);  
            }
            ENDCG
        }
    }
    FallBack "Diffuse"

}
