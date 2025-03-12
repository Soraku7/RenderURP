Shader "Effect/Translation"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Opacity ("透明度", Range(0,1)) = 1
        _MoveRange ("移动范围", Range(0,3)) = 1
        _MoveSpeed ("移动速度", Range(0,3)) = 0.5
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
            Name "FORWARD"
            Tags {
                "LightMode" = "UniversalForward"
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
            uniform half _MoveRange;
            uniform half _MoveSpeed;
            
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

            #define PI2 6.283185307179586476925286766559f // 2 * PI

            void Translation(inout float3 vertex)
            {
                vertex.y += _MoveRange * sin(frac(_Time.y * _MoveSpeed) * PI2);
            }

            v2f vert (appdata v)
            {
                v2f o = (v2f)0;
                Translation(v.vertex.xyz);
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                half4 var_MainTex = tex2D(_MainTex, i.uv);
                return var_MainTex * var_MainTex.a;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"	
}
