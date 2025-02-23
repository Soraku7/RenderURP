Shader "Effect/Sequence"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "white" {}
        _Opacity ("透明度", Range(0,1)) = 1
        _Sequence ("序列帧", 2D) = "gray" {}
        _RowCount ("行数", Float) = 1
        _ColumnCount ("列数", Float) = 1
        _Speed ("速度", Range(1 , 10)) = 1
    }
    SubShader
    {
        Tags {
            "Queue" = "Transparent"
            "RenderType"="TransparentCutout"
            "ForceNoShadowCasting"="True"  // 不产生阴影
            "IgnoreProject"="True"  // 忽略投影
        }
        LOD 100

        Pass
        {
            Name "FORWARD_AB"
            Tags {
                "LightMode" = "ForwardBase"
            }
            Blend One OneMinusSrcAlpha
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            uniform sampler2D _MainTex;
            uniform float4 _MainTex_ST;
            uniform half _Opacity;
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };


            v2f vert (appdata v)
            {
                v2f o = (v2f)0;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                half4 var_MainTex = tex2D(_MainTex, i.uv);

                half3 finalRGB = var_MainTex.rgb;
                half _opacity = var_MainTex.a * _Opacity;
                return half4(finalRGB * _opacity,_opacity);
            }
            ENDCG
        }

        Pass
        {
            Name "FORWARD_AD"
            Tags {
                "LightMode" = "ForwardBase"
            }
            Blend One One
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            uniform sampler2D _Sequence;
            uniform float4 _Sequence_ST;
            uniform half _RowCount;
            uniform half _ColumnCount;
            uniform half _Speed;
            
            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };


            v2f vert (appdata v)
            {
                v2f o = (v2f)0;
                v.vertex.xyz += v.normal * 0.01;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv , _Sequence);

                float _SeqID = floor(_Time.y * _Speed);
                
                float idv = floor(_SeqID / _ColumnCount);
                float idu = _SeqID - idv * _ColumnCount;

                float stepU = 1.0 / _ColumnCount;
                float stepV = 1.0 / _RowCount;

                float2 initUV = o.uv * float2(stepU , stepV) + float2(0.0 , stepV * (_RowCount - 1.0));
                o.uv = initUV + float2(idu * stepU , -idv * stepV);
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                half4 var_Sequence = tex2D(_Sequence, i.uv);
                half3 finalRGB = var_Sequence.rgb;
                half opacity = var_Sequence.a;
                return half4(finalRGB * opacity,opacity);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"	
}
