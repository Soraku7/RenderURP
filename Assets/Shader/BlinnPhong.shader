Shader "Shader/Blinn-Phong" {
    Properties {
        _MainCol ("漫反射颜色", color) = (1.0, 1.0, 1.0, 1.0)
        _SpecularCol("高光颜色", color) = (1.0, 1.0, 1.0, 1.0)
        _SpecularPow ("高光次幂",range(1, 90)) = 30
    }
    SubShader {
        Tags {
            "RenderType"="Opaque"
        }
        Pass {
            Name "FORWARD"
            Tags {
                "LightMode"="ForwardBase"
            }
            
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"
            

            //输入参数，注意与开头声明的对应
            uniform float3 _MainCol;
            uniform float3 _SpecularCol;
            uniform float _SpecularPow;
            
            //输入结构
            struct VertexInput {
                float4 vertex : POSITION; //顶点
                float3 normal : NORMAL; //法线
            };

            //输出结构
            struct VertexOutput {
                float4 posCS : SV_POSITION; //裁剪空间下的坐标
                float4 posWS : TEXCOORD0; //世界空间下的坐标
                float3 nDirWS : TEXCOORD1; //法线向量
            };

            //顶点shader
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.posCS = UnityObjectToClipPos(v.vertex); //顶点转换到裁剪空间
                o.posWS = mul(unity_ObjectToWorld, v.vertex); //顶点位置位置转化到世界空间
                o.nDirWS = UnityObjectToWorldNormal(v.normal); //法线转换到世界空间

                return o;
            }

            //像素shader
            float4 frag(VertexOutput i) : COLOR {
                //准备向量
                float3 nDir = i.nDirWS; //法线向量
                float3 lDir = _WorldSpaceLightPos0.xyz; //光照方向
                float3 vDir = normalize(_WorldSpaceCameraPos.xyz - i.posWS); //视角方向，用相机位置-顶点位置就是视角方向
                float3 hDir = normalize(vDir + lDir); //视角方向和光照方向的中间方向
                //准备点积结果
                float ndotl = dot(nDir, lDir);
                float ndoth = dot(nDir, hDir);
                //光照模型计算
                float3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb; //环境光
                float3 diffuse = _LightColor0.rgb * _MainCol * max(0, ndotl); //漫反射
                float3 specular = _LightColor0.rgb * _SpecularCol * pow(max(0, ndoth), _SpecularPow); //高光
                float3 blinnPhong =  ambient + diffuse + specular; //最终颜色

                return float4(blinnPhong, 1.0);
            }
            ENDCG

        }
    }
    FallBack "Diffuse"  
}

