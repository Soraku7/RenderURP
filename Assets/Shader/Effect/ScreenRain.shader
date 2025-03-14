Shader "Effect/ScreenRain"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Size("Size", Range(1, 100)) = 0.5
        _T("Time", Float) = 1.0
        _Distortion("Distortion", Float) = 0.5
        _Blur("Blur", Range(0 , 1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
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
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            #define PI2 6.283185307179586476925286766559f
            
            uniform sampler2D _MainTex;
            uniform float4 _MainTex_ST;
            uniform float _Size;
            uniform float _T;
            uniform float _Distortion;
            uniform float _Blur;

            //伪随机数
            half N21(half2 p)
            {
                p = frac(p * half2(123.34 , 345.45));
                p += dot(p , p + 34.345);
                return frac(p.x + p.y);
            }

            half3 DropLayer(half2 UV, half T)
            {
                //每2h重置一次
                half t = fmod(_Time.y * T , 7200);
                // UV多次平铺
                half4 col = half4(0 , 0 , 0 ,1.0);
                //长宽比
                half2 aspect = half2(3 , 1);

                half2 uv = UV * _Size * aspect;
                //水滴向下移动同时UV向下移动
                uv.y += t * 0.25;
                //将左下角原点调整为中心
                half2 gv = frac(uv) - 0.5;

                half2 id = floor(uv);
                half n = N21(id);
                t += n * PI2;

                half w = UV.y * 10;
                //更复杂的水滴移动轨迹
                half x = (n - 0.5) * 0.8;
                x += (0.4 - abs(x)) * sin(3 * w) * pow(sin(w), 6) * 0.45;
                half y = -sin(t + sin(t + sin(t) * 0.5)) * 0.45;
                //改变水滴形状
                y -= (gv.x - x) * (gv.x - x);
                half2 dropPos = (gv - half2(x , y)) / aspect;

                half2 trailPos = (gv - half2(x , t * 0.25)) / aspect;
                trailPos.y = (frac(trailPos.y * 8) - 0.5) / 8;
                //水滴轨迹
                half trail = smoothstep(0.03 , 0.01 , length(trailPos));
                
                //画圆
                half drop = smoothstep(0.05 , 0.03 , length(dropPos));

                //消除多余拖尾轨迹
                half fogTrail = smoothstep(-0.05 , 0.05 , dropPos.y);
                //水滴渐变
                fogTrail *= smoothstep(0.5 , y , gv.y);
                //缩小雾效
                fogTrail *= smoothstep(0.05 , 0.04 , abs(dropPos.x));

                trail *= fogTrail;

                // col += fogTrail * 0.5;
                // col += drop;
                // col += trail;
                //辅助线
                // if(gv.x > 0.48 || gv.y > 0.49) col = half4(1.0, 0, 0, 1.0);

                half2 offset = drop * dropPos + trail * trailPos;
                return half3(offset , fogTrail);
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                half3 drops = DropLayer(i.uv, _T);
		        //这里的参数读者可自行测试控制
		        drops += DropLayer(i.uv * 1.25 + 7.52, _T);
		        drops += DropLayer(i.uv * 1.57 - 7.52, _T);
                half blur = _Blur * 7 * (1 - drops.z);
                half4 finalCol = tex2Dlod(_MainTex, half4(i.uv + drops.xy * _Distortion, 0 , blur));
                
                return finalCol;
            }
            ENDCG
        }
    }
}
