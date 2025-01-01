Shader "Unlit/Jade"
{
    Properties
    {
        _RampTex("RampTex" , 2D) = "white"{}
        _FresnelCol("FresnelCol" , Color) = (1 , 1 , 1 ,1)
        _HighlightCol ("HighlightCol" , Color) = (1 , 1 , 1 , 1)
        _Offset1 ("HightLight Offset 1" , Vector) = (0 , -0.33 , 0 , 0)
        _Offset2 ("HightLight Offset 2" , Vector) = (0 , 0 , 0 , 0)
        _Threshold1 ("Hightlight threshold 1" , Range(0 , 1)) = 0.993
        _Threshold2 ("Hightlight threshold 2" , Range(0 , 2)) = 0.955
    }
    SubShader
    {
        Tags { 
            "RenderType"="Opaque" 
            "LightMode" = "ForwardBase"
            
        }
        LOD 100


        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 WorldPos : TEXCOORD1;
                float3 nDir : TEXCOORD2;
            };

            sampler2D _RampTex;
            float4 _RampTex_ST; //uv坐标

            float4 _FresnelCol;

            fixed4 _HighlightCol;
            float3 _Offset1;
            float3 _Offset2;
            float _Threshold1;
            float _Threshold2;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                //计算模型uv与实际uv计算
                o.uv = TRANSFORM_TEX(v.texcoord , _RampTex);
                o.WorldPos = mul(unity_ObjectToWorld , v.vertex).xyz;

                o.nDir = UnityObjectToWorldDir(v.normal);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //RampTexture 渐变纹理
                float3 nDir = normalize(i.nDir);
                float3 lDir = normalize(UnityWorldSpaceLightDir(i.WorldPos));
                fixed halfLambort = dot(nDir , lDir) * 0.5 + 0.5;
                fixed3 RampCol = tex2D(_RampTex , fixed2(halfLambort , halfLambort)).rgb;

                //Hightlight1
                float3 lDir1 = normalize(lDir + _Offset1);
                //saturate 将数值归为0到1
                fixed halfLambort1 = saturate(dot(nDir , lDir1));
                //超过Threshold的值返回halfLambort 否则返回1
                fixed highlight1 = step(_Threshold1 , halfLambort1);

                //Hightlight1
                float3 lDir2 = normalize(lDir + _Offset2);
                //saturate 将数值归为0到1
                fixed halfLambort2 = saturate(dot(nDir , lDir2));
                //超过Threshold的值返回halfLambort 否则返回1
                fixed highlight2 = step(_Threshold2 , halfLambort2);
                
                //max(hightlight1 , hightlight2) 合并光线
                fixed highlight = saturate(max(highlight1 , highlight2));
                
                //lerp highlight = 0 返回rampcol =1 返回_HighlightCol
                fixed3 color = lerp(RampCol , _HighlightCol , highlight);

                //_FresnelCol
                float3 vDir = normalize(UnityWorldSpaceViewDir(i.WorldPos));
                float3 fresnel = saturate(dot(nDir , vDir));
                float3 fresnelColor = pow(1.0 - fresnel , 3.0) * _FresnelCol.rgb; //外部亮 中间暗

                //Screen Blend
                color = 1 - (1 - color) * (1 - fresnelColor);

                return float4(color, 1);
            }
            ENDCG
        }
    }
}
