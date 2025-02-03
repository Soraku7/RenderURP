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
            uniform sampler2D _MaskTex;
            uniform sampler2D _NormalMap;
            uniform sampler2D _MatlnessMask;
            uniform sampler2D _EmissionMask;
            uniform sampler2D _DiffWarpTex;
            uniform sampler2D _FressnalMap;
            uniform samplerCUBE _CubeMap;
            
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
                half4 var_NormalMap = tex2D(_NormalMap , i.uv0);
                half var_MatlnessMask = tex2D(_MatlnessMask , i.uv0).r;
                half var_EmissionMask = tex2D(_EmissionMask , i.uv0).r;
                half3 var_Cubemap = texCUBE(_CubeMap , float4(vrDirWS , lerp(8.0 , 0.0 , var_MaskTex.a))).rgb;
                
                return float4(1.0 , 1.0 , 1.0, 1.0);  
            }
            ENDCG
        }
    }
    FallBack "Diffuse"

}
