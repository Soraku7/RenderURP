Shader "Unlit/Hatch" {
    Properties {
        _Outline ("Outline", Range(0, 1)) = 0.1
        _OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)
        _HatchTex ("Hatch Texture", 2D) = "white" {}
        _DarkColor ("Dark Color", Color) = (1, 1, 1, 1)
        _LightColor ("Light Color", Color) = (1, 1, 1, 1)
        _MultiplyColor ("Multiply Color", Color) = (1, 1, 1, 1)
    }
    SubShader {
        Tags {
            "LightMode" = "ForwardBase"
            "RenderType"="Opaque"
            "Queue" = "Geometry"
        }
        Pass {
            NAME "OUTLINE"

            Cull Front

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            float _Outline;
            fixed4 _OutlineColor;

            struct a2v {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f {
                float4 pos : SV_POSITION;
            };

            v2f vert(a2v v) {
                v2f o;

                // 将顶点从模型空间变换到视角空间
                float4 pos = mul(UNITY_MATRIX_MV, v.vertex);
                // 将法线从模型空间转换到视角空间
                float3 normal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
                normal.z = -0.5;
                // 将顶点在视角空间向外扩张
                pos = pos + float4(normalize(normal), 0) * _Outline;
                // 将顶点从视角空间转换到裁剪空间
                o.pos = mul(UNITY_MATRIX_P, pos);

                return o;
            }

            float4 frag(v2f i) : SV_Target {
                return float4(_OutlineColor.rgb, 1);
            }
            ENDCG
        }
        Pass {
            NAME "SHADING"

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _HatchTex;
            float4 _HatchTex_ST;

            float4 _DarkColor;
            float4 _LightColor;
            float4 _MultiplyColor;

            struct a2v {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f {
                float4 pos : SV_POSITION;
                float4 scrPos : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float3 nDir : TEXCOORD2;
            };

            v2f vert(a2v v) {
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex);

                o.scrPos = ComputeScreenPos(o.pos); // 齐次坐标下的屏幕坐标 (0, w)
                COMPUTE_EYEDEPTH(o.scrPos.z);

                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.nDir = UnityObjectToWorldNormal(v.normal);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target {
                // 计算lambert光照模型
                float3 nDir = normalize(i.nDir);
                float3 lDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed lambert = dot(nDir, lDir);

                // 计算HatchTex采样颜色 HatchTex采样结果密度不随相机移动而改变
                // 计算屏幕UV坐标
                float aspecet = _ScreenParams.x / _ScreenParams.y;// 保持拉伸正常
                float2 screenUV = i.scrPos.xy / i.scrPos.w;// [0, 1]
                screenUV = float2((screenUV.x * 2 - 1) * aspecet, screenUV.y * 2 - 1);// [-1, 1]
                // 计算深度=视图空间深度z-摄像机近平面
                float partZ = max(0, i.scrPos.z - _ProjectionParams.y);
                screenUV *= partZ;
                screenUV = TRANSFORM_TEX(screenUV, _HatchTex);
                float hatch = tex2D(_HatchTex, screenUV.xy).r;

                // 将Hatch线条和明暗结合（黑白）
                float4 color = step(hatch, lambert);
                // 用上述结果进行遮罩
                color = lerp(_DarkColor, _LightColor, color);
                // 加上明暗结果
                color += lambert * _MultiplyColor;
                // 范围约束
                saturate(color);

                return color;
            }
            ENDCG
        }
    }
}