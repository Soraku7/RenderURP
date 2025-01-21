Shader "Unlit/OldSchoolPlus"
{
    Properties
    {
        _Occlusion ("Occlusion", 2D) = "white" {}
        _EnvUpCol ("EnvUpCol" , color) = (1.0 , 1.0 , 1.0 , 1.0)
        _EnvSideCol ("EnvUpCol" , color) = (1.0 , 1.0 , 1.0 , 1.0)
        _EnvDownCol ("EnvDownCol" , color) = (1.0 , 1.0 , 1.0 , 1.0)
        _EnvInt ("环境光强度" , Range(0 , 1)) = 0.5
        _BaseColor ("BaseColor", Color) = (1,1,1,1)
        _LightColor ("LightColor", Color) = (1,1,1,1)
        _SpecularPow ("Specular" , Range(10 , 90)) = 30  
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
            uniform float _EnvInt;
            uniform float4 _BaseColor;
            uniform float4 _LightColor;
            uniform float _SpecularPow;
                
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
                float3 normalWS : TEXCOORD2;
                
                LIGHTING_COORDS(3,4)
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
                float3 envCol = upMask * _EnvUpCol + sideMask * _EnvSideCol + downMask * _EnvDownCol;
                //Lambort
                float3 lambort = _BaseColor.rgb * max(0.0 , dot(nDirWS , lDir));
                //Phong
                float3 lReflect = normalize(reflect(-lDir , nDirWS));
                float3 phong = pow(max(0.0 , dot(lReflect , vDir)) , _SpecularPow);
                float occlusion = tex2D(_Occlusion , i.uv).r;

                //直接光照部分
                float3 dirLighting = (_BaseColor * lambort + phong) * _LightColor * shadow;
                //间接光照部分
                float3 envLighting = envCol * occlusion * _EnvInt * occlusion;
                
                float3 final = dirLighting + envLighting;
                
                return float4(final.x, final.y, final.z, 1.0);  
            }
            ENDCG
        }
    }
    FallBack "Diffuse"

}
