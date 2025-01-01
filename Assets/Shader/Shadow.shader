Shader "Unlit/Shadow"
{
    Properties
    {

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

            struct appdata
            {
                float4 vertex : POSITION;

            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                LIGHTING_COORDS(0,1)
            };



            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                TRANSFER_VERTEX_TO_FRAGMENT(o)

                return o;
            }

            fixed4 frag (v2f i) : COLOR
            {
                float shadow = LIGHT_ATTENUATION(i);        // 同样Unity封装好的函数 可取出投影
                return float4(shadow, shadow, shadow, 1.0);  
            }
            ENDCG
        }
    }
    FallBack "Diffuse"

}
