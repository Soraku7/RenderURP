Shader "Unlit/OldSchoolPro"
{
    Properties
    {
        [Header(Texture)]
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _NormalMap ("NormalMap" , 2D) = "white" {}
        _SpecularMap ("SpecularMap" , 2D) = "white" {}
        _EmitTex ("环境贴图" , 2D) = "white" {}
        _CubeMap ("CubeMap" , CUBE) = "white" {}
        
        [Header(Diffuse)]
        _MainCol ("MainCol" , color) = (1.0 , 1.0 , 1.0 , 1.0) 
        _EnvDiffInt ("环境光反射强度" , Range(0 , 1)) = 0.5
        _EnvUpCol ("EnvUpCol" , color) = (1.0 , 1.0 , 1.0 , 1.0)
        _EnvSideCol ("EnvUpCol" , color) = (1.0 , 1.0 , 1.0 , 1.0)
        _EnvDownCol ("EnvDownCol" , color) = (1.0 , 1.0 , 1.0 , 1.0)
        
        [Header(Specular)]
        _SpecularPow ("Specular" , Range(10 , 90)) = 30
        _EnvSpecInt ("环境光反射强度" , Range(0 , 5)) = 0.5
        _FresnelPow ("FresnelPow" , Range(0 , 5)) = 1
        _CubemapMip ("CubemapMip" , Range(0 , 7)) = 1
        
        [Header(Emission)]
        _EmitInt ("EmitInt" , Range(0 , 1)) = 0.5
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
                float tangent : TANGENT;
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
                return o;
            }

            fixed4 frag (v2f i) : COLOR
            {
              
                return float4(1.0, 1.0, 1.0, 1.0);  
            }
            ENDCG
        }
    }
    FallBack "Diffuse"

}
