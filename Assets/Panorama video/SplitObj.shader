Shader "Custom/Rhombus"
{
    Properties
    {
        [PerRendererData] _MainTex("Sprite Texture", 2D) = "white" {}
        _Color("Tint", Color) = (1,1,1,1)
        [MaterialToggle] PixelSnap("Pixel snap", Float) = 0
    }
 
        SubShader
        {
            Tags
            {
                "Queue" = "Transparent"
                "IgnoreProjector" = "True"
                "RenderType" = "Transparent"
                "PreviewType" = "Plane"
                "CanUseSpriteAtlas" = "True"
            }
 
            Cull Off
            Lighting Off
            ZWrite Off
            Blend One OneMinusSrcAlpha
 
            Pass
            {
            CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #pragma multi_compile _ PIXELSNAP_ON
                #include "UnityCG.cginc"
 
                struct appdata_t
                {
                    float4 vertex   : POSITION;
                    float4 color    : COLOR;
                    float2 texcoord : TEXCOORD0;
                };
 
                struct v2f
                {
                    float4 vertex   : SV_POSITION;
                    fixed4 color : COLOR;
                    float2 texcoord  : TEXCOORD0;
                };
 
                fixed4 _Color;
 
                v2f vert(appdata_t IN)
                {
                    v2f OUT;
                    OUT.vertex = UnityObjectToClipPos(IN.vertex);
                    OUT.texcoord = IN.texcoord;
                    OUT.color = IN.color * _Color;
                    #ifdef PIXELSNAP_ON
                    OUT.vertex = UnityPixelSnap(OUT.vertex);
                    #endif
 
                    return OUT;
                }
 
                sampler2D _MainTex;
                sampler2D _AlphaTex;
                float _AlphaSplitEnabled;

                float lineWidth;
                fixed4 SampleSpriteTexture(float2 uv)
                {
                    fixed4 color = tex2D(_MainTex, uv);
 
    #if UNITY_TEXTURE_ALPHASPLIT_ALLOWED
                    if (_AlphaSplitEnabled)
                        color.a = tex2D(_AlphaTex, uv).r;
    #endif //UNITY_TEXTURE_ALPHASPLIT_ALLOWED
                    // if (uv.x + uv.y < 0.5) //切除A区
                    //     color.a = 0;
                    // else if (uv.x > 0.5 && uv.x - 0.5 > uv.y) //切除B区
                    //     color.a = 0;
                    // else if (uv.y > 0.5 && uv.y - 0.5 > uv.x) //切除C区
                    //     color.a = 0;
                    // else if (uv.x > 0.5 && uv.y > 0.5 && uv.x + uv.y > 1.5) //切除D区
                    //     color.a = 0;
                    if(uv.y == 0.5)
                    {
                        color = fixed4(0 , 0 , 0 , 1);
                    }
                    if(uv.x == 0.3)
                    {
                        color = fixed4(0 , 0 , 0 , 1);
                    }
                    if(uv.y == 0.6)
                    {
                        color = fixed4(0 , 0 , 0 , 1);
                    }
                    return color;
                }
 
                fixed4 frag(v2f IN) : SV_Target
                {
                    fixed4 c = SampleSpriteTexture(IN.texcoord) * IN.color;
                    c.rgb *= c.a;
                    return c;
                }
            ENDCG
            }
        }
}