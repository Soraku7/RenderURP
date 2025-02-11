Shader "Effect/BlendMode"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [Enum(UnityEngine.Rendering.BlendMode)]
        _BlendSrc ("源乘子", int) = 0
        [Enum(UnityEngine.Rendering.BlendMode)]
        _BlendDst ("目标乘子", int) = 0
        [Enum(UnityEngine.Rendering.BlendOp)]
        _BlendOp ("混合操作", int) = 0
        
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
                "LightMode" = "ForwardBase"
            }
            BlendOp [_BlendOp]
            Blend [_BlendSrc] [_BlendDst]
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            uniform sampler2D _MainTex;
            uniform float4 _MainTex_ST;
            
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
