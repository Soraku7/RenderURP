Shader "Unlit/OldSchoolPlus"
{
    Properties
    {
        _Occlusion ("Occlusion", 2D) = "white" {}
        _EnvUpCol ("EnvUpCol" , color) = (1.0 , 1.0 , 1.0 , 1.0)
        _EnvSideCol ("EnvUpCol" , color) = (1.0 , 1.0 , 1.0 , 1.0)
        _EnvDownCol ("EnvDownCol" , color) = (1.0 , 1.0 , 1.0 , 1.0)
        _BaseColor ("BaseColor", Color) = (1,1,1,1)
        _LightColor ("LightColor", Color) = (1,1,1,1)
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

            uniform sampler2D _Occlusion;
            uniform float3 _EnvUpCol;
            uniform float3 _EnvSideCol;
            uniform float3 _EnvDownCol;
            uniform float4 _BaseColor;
            uniform float4 _LightColor;
                
            struct appdata
            {
                float4 vertex : POSITION;
                float3 normalWS : NORMAL;
                float2 uv0 : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                
                LIGHTING_COORDS(0,1)
            };



            v2f vert (appdata v)
            {
                v2f o = (v2f)0;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.normalWS = UnityObjectToWorldNormal(v.normalWS);
                o.uv = v.uv0;
                
                TRANSFER_VERTEX_TO_FRAGMENT(o)
                return o;
            }

            fixed4 frag (v2f i) : COLOR
            {
                float shadow = LIGHT_ATTENUATION(i);        // 同样Unity封装好的函数 可取出投影
                float3 nDirWS = i.normalWS;
                float3 lDir = _WorldSpaceLightPos0.xyz;
                float3 vDir = normalize(_WorldSpaceCameraPos.xyz - i.pos.xyz);

                //3Col
                float upMask = max(0.0 , i.normalWS.y);
                float downMask = max(0.0 , -i.normalWS.y);
                float sideMask = 1 - upMask - downMask;
                //Lambort
                float3 lambort = _BaseColor.rgb * max(0.0 , dot(nDirWS , lDir));
                //Phong
                
                
                
                return float4(shadow, shadow, shadow, 1.0);  
            }
            ENDCG
        }
    }
    FallBack "Diffuse"

}
