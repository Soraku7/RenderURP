Shader "Unlit/LambortPlus"
{
    Properties
    {
        _Occlusion ("Occlusion", 2D) = "white" {}
        _BaseCol ("BaseCol" , Color) = (0.5 , 0.5 , 0.5 , 1.0)
        _LightCol ("LightCol" , Color) = (1.0 , 1.0 , 1.0 , 1.0)
        _SpecPow ("SpecPow" , Range(1 , 90)) = 30

        _EnvInt ("EnvInt" , Range(0 , 1)) = 0.2 
        _EnvUpCol ("EnvUpCol" , Color) = (1.0 , 1.0 , 1.0 , 1.0)
        _EnvSideCol ("EnvSideCol" , Color) = (0.5 , 0.5 , 0.5 , 1.0)
        _EnvDownCol ("EnvDownCol" , Color) = (0.0 , 0.0 , 0.0 , 0.0)
    } 
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            tags{"LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"

            uniform float3 _BasCol;
            uniform float3 _LightCol;
            uniform float _SpecPow;
            uniform sampler2D _Occlusion;
            uniform float _EnvInt;
            uniform float3 _EnvUpCol;
            uniform float3 _EnvSideCol;
            uniform float3 _EnvDownCol;


            struct appdata
            {
                float4 vertex : POSITION;
                float4 normal : NORMAL;
                float2 uv :TEXCOORD1;
            };

            struct v2f
            {
                float4 pos :SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float4 posWS : TEXCOORD1;
                float3 nDirWS : TEXCOORD2;
                LIGHTING_COORDS(3,4)
            };



            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.posWS = mul(unity_ObjectToWorld , v.vertex);
                o.uv0 = v.uv;
                o.nDirWS = UnityObjectToWorldNormal(v.normal);

                TRANSFER_VERTEX_TO_FRAGMENT(o);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {   
                float3 nDir = normalize(i.nDirWS);
                float3 lDir = _WorldSpaceLightPos0.xyz;
                float3 vDir = normalize(_WorldSpaceCameraPos.xyz - i.posWS);
                float3 rDir = reflect(-lDir , nDir); //光线方向 法线方向计算反射光方向

                float ndotl = dot(nDir , lDir);
                float vdotr = dot(vDir , rDir);

                float shadow = LIGHT_ATTENUATION(i);  //获取阴影
                float lambort = max(0.0 , ndotl);
                float phong = pow(max(0.0 , vdotr) , _SpecPow);
                float3 dirLighting = (_BasCol * lambort + phong) * _LightCol * shadow;   
                
                float upMask = max(0.0 , nDir.g);
                float downMask = max(0.0 , -nDir.g);
                float sideMask = 1.0 - upMask - downMask;

                float3 envCol = _EnvUpCol * upMask + _EnvSideCol * sideMask + _EnvDownCol * downMask;
                float occlusion = tex2D(_Occlusion , i.uv0);
                float3 envLighting = envCol * _EnvInt * occlusion;

                float3 finalRGB = dirLighting + envLighting;
                return float4(finalRGB , 1.0);
            }
            ENDCG
        }
    }
}
