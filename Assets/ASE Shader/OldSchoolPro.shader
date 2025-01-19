// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "OldSchoolPro"
{
	Properties
	{
		_Specular(" Specular", Range( 0 , 10)) = 0
		_BaseColor("BaseColor", Color) = (0.7801076,1,0,0)
		_LightCol("LightCol", Color) = (0,1,0.6555786,0)
		_EnvUpCol("EnvUpCol", Color) = (0.8977057,1,0,0)
		_EnvMidCol("EnvMidCol", Color) = (0.764151,0,0,0)
		_EnvDownCol("EnvDownCol", Color) = (1,0,0.53233,0)
		_Occlusuion("Occlusuion", 2D) = "white" {}
		_NormalMap("NormalMap", 2D) = "white" {}
		_CubeMap("CubeMap", CUBE) = "white" {}
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" "IsEmissive" = "true"  }
		Cull Back
		CGINCLUDE
		#include "UnityCG.cginc"
		#include "UnityPBSLighting.cginc"
		#include "Lighting.cginc"
		#pragma target 3.0
		#ifdef UNITY_PASS_SHADOWCASTER
			#undef INTERNAL_DATA
			#undef WorldReflectionVector
			#undef WorldNormalVector
			#define INTERNAL_DATA half3 internalSurfaceTtoW0; half3 internalSurfaceTtoW1; half3 internalSurfaceTtoW2;
			#define WorldReflectionVector(data,normal) reflect (data.worldRefl, half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal)))
			#define WorldNormalVector(data,normal) half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal))
		#endif
		struct Input
		{
			float3 worldNormal;
			INTERNAL_DATA
			float3 worldPos;
			float2 uv_texcoord;
		};

		uniform float4 _BaseColor;
		uniform float _Specular;
		uniform float4 _LightCol;
		uniform float4 _EnvUpCol;
		uniform float4 _EnvMidCol;
		uniform float4 _EnvDownCol;
		uniform sampler2D _Occlusuion;
		uniform float4 _Occlusuion_ST;
		uniform samplerCUBE _CubeMap;
		uniform sampler2D _NormalMap;
		uniform float4 _NormalMap_ST;
		SamplerState sampler_NormalMap;


		float3x3 Inverse3x3(float3x3 input)
		{
			float3 a = input._11_21_31;
			float3 b = input._12_22_32;
			float3 c = input._13_23_33;
			return float3x3(cross(b,c), cross(c,a), cross(a,b)) * (1.0 / dot(a,cross(b,c)));
		}


		void surf( Input i , inout SurfaceOutputStandard o )
		{
			o.Normal = float3(0,0,1);
			float3 ase_worldNormal = WorldNormalVector( i, float3( 0, 0, 1 ) );
			float3 ase_worldPos = i.worldPos;
			#if defined(LIGHTMAP_ON) && UNITY_VERSION < 560 //aseld
			float3 ase_worldlightDir = 0;
			#else //aseld
			float3 ase_worldlightDir = normalize( UnityWorldSpaceLightDir( ase_worldPos ) );
			#endif //aseld
			float dotResult4 = dot( ase_worldNormal , ase_worldlightDir );
			float3 ase_worldViewDir = normalize( UnityWorldSpaceViewDir( ase_worldPos ) );
			float dotResult16 = dot( reflect( ( ase_worldlightDir * -1.0 ) , ase_worldNormal ) , ase_worldViewDir );
			float temp_output_27_0 = max( ase_worldNormal.y , 0.0 );
			float temp_output_31_0 = ( ase_worldNormal.y * -1.0 );
			float2 uv_Occlusuion = i.uv_texcoord * _Occlusuion_ST.xy + _Occlusuion_ST.zw;
			float2 uv_NormalMap = i.uv_texcoord * _NormalMap_ST.xy + _NormalMap_ST.zw;
			float4 tex2DNode45 = tex2D( _NormalMap, uv_NormalMap );
			float4 appendResult50 = (float4(tex2DNode45.r , tex2DNode45.g , tex2DNode45.b , 0.0));
			float3 ase_worldTangent = WorldNormalVector( i, float3( 1, 0, 0 ) );
			float3 ase_worldBitangent = WorldNormalVector( i, float3( 0, 1, 0 ) );
			float3x3 ase_worldToTangent = float3x3( ase_worldTangent, ase_worldBitangent, ase_worldNormal );
			float3x3 invertVal47 = Inverse3x3( ase_worldToTangent );
			float dotResult55 = dot( float4( mul( appendResult50.xyz, invertVal47 ) , 0.0 ) , float4( ase_worldlightDir , 0.0 ) );
			o.Emission = ( ( ( ( ( max( dotResult4 , 0.0 ) * _BaseColor ) + pow( max( dotResult16 , 0.0 ) , _Specular ) ) * _LightCol ) + ( ( ( temp_output_27_0 * _EnvUpCol ) + ( ( ( 1.0 - temp_output_27_0 ) - temp_output_31_0 ) * _EnvMidCol ) + ( temp_output_31_0 * _EnvDownCol ) ) * tex2D( _Occlusuion, uv_Occlusuion ) ) ) * texCUBE( _CubeMap, reflect( float4( ( ase_worldViewDir * -1.0 ) , 0.0 ) , tex2DNode45 ).rgb ) * ( tex2DNode45.r * max( dotResult55 , 0.0 ) ) ).rgb;
			o.Alpha = 1;
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf Standard keepalpha fullforwardshadows 

		ENDCG
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma multi_compile_shadowcaster
			#pragma multi_compile UNITY_PASS_SHADOWCASTER
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			#include "HLSLSupport.cginc"
			#if ( SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES || SHADER_API_GLES3 || SHADER_API_METAL || SHADER_API_VULKAN )
				#define CAN_SKIP_VPOS
			#endif
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			struct v2f
			{
				V2F_SHADOW_CASTER;
				float2 customPack1 : TEXCOORD1;
				float4 tSpace0 : TEXCOORD2;
				float4 tSpace1 : TEXCOORD3;
				float4 tSpace2 : TEXCOORD4;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};
			v2f vert( appdata_full v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_INITIALIZE_OUTPUT( v2f, o );
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				Input customInputData;
				float3 worldPos = mul( unity_ObjectToWorld, v.vertex ).xyz;
				half3 worldNormal = UnityObjectToWorldNormal( v.normal );
				half3 worldTangent = UnityObjectToWorldDir( v.tangent.xyz );
				half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				half3 worldBinormal = cross( worldNormal, worldTangent ) * tangentSign;
				o.tSpace0 = float4( worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x );
				o.tSpace1 = float4( worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y );
				o.tSpace2 = float4( worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z );
				o.customPack1.xy = customInputData.uv_texcoord;
				o.customPack1.xy = v.texcoord;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET( o )
				return o;
			}
			half4 frag( v2f IN
			#if !defined( CAN_SKIP_VPOS )
			, UNITY_VPOS_TYPE vpos : VPOS
			#endif
			) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				Input surfIN;
				UNITY_INITIALIZE_OUTPUT( Input, surfIN );
				surfIN.uv_texcoord = IN.customPack1.xy;
				float3 worldPos = float3( IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w );
				half3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				surfIN.worldPos = worldPos;
				surfIN.worldNormal = float3( IN.tSpace0.z, IN.tSpace1.z, IN.tSpace2.z );
				surfIN.internalSurfaceTtoW0 = IN.tSpace0.xyz;
				surfIN.internalSurfaceTtoW1 = IN.tSpace1.xyz;
				surfIN.internalSurfaceTtoW2 = IN.tSpace2.xyz;
				SurfaceOutputStandard o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutputStandard, o )
				surf( surfIN, o );
				#if defined( CAN_SKIP_VPOS )
				float2 vpos = IN.pos;
				#endif
				SHADOW_CASTER_FRAGMENT( IN )
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=18500
-9.6;99.2;1536;795;1188.596;-645.8302;1.648144;True;True
Node;AmplifyShaderEditor.CommentaryNode;23;-2075.87,-295.5873;Inherit;False;1412.557;430.4507;Phong;10;11;14;10;17;12;19;16;18;21;20;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;9;-2101.122,-785.9998;Inherit;False;1039.4;449;Lambort;7;2;3;6;4;5;8;7;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;11;-2025.87,-147.2365;Inherit;False;Constant;_Float1;Float 1;0;0;Create;True;0;0;False;0;False;-1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;41;-2212.855,266.7454;Inherit;False;1664.202;1105.107;3Col;14;28;26;35;27;37;36;31;32;33;30;38;34;29;39;;1,1,1,1;0;0
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;3;-2051.122,-534.9998;Inherit;False;False;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;28;-1896.681,513.0302;Inherit;False;Constant;_Float3;Float 3;3;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.WorldNormalVector;14;-1766.718,-45.73666;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldNormalVector;26;-2162.855,316.7454;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;10;-1767.572,-241.2611;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ReflectOpNode;12;-1515.718,-241.7367;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;17;-1490.395,-59.05494;Inherit;False;World;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;32;-1972.518,1139.06;Inherit;False;Constant;_Float4;Float 4;3;0;Create;True;0;0;False;0;False;-1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;27;-1736.084,362.8426;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;59;-2239.933,1969.611;Inherit;False;1446.514;582.8352;Normal;10;45;50;47;46;55;51;52;56;57;58;;1,1,1,1;0;0
Node;AmplifyShaderEditor.WorldNormalVector;2;-2046.122,-735.9998;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.OneMinusNode;35;-1593.332,725.672;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldToTangentMatrix;46;-2128.497,2424.123;Inherit;False;0;1;FLOAT3x3;0
Node;AmplifyShaderEditor.DotProductOpNode;4;-1739.122,-733.9998;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;16;-1277.927,-243.3535;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;6;-1690.122,-550.9998;Inherit;False;Constant;_Float0;Float 0;0;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;19;-1254.583,-39.20424;Inherit;False;Constant;_Float2;Float 2;0;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;45;-2189.933,2019.611;Inherit;True;Property;_NormalMap;NormalMap;7;0;Create;True;0;0;False;0;False;-1;None;0c8ba2f243fb4274e8a225003f437ace;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;31;-1786.642,1030.508;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;34;-1670.656,1162.852;Inherit;False;Property;_EnvDownCol;EnvDownCol;5;0;Create;True;0;0;False;0;False;1,0,0.53233,0;1,0,0.53233,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;30;-1605.228,508.5691;Inherit;False;Property;_EnvUpCol;EnvUpCol;3;0;Create;True;0;0;False;0;False;0.8977057,1,0,0;1,0.7008737,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.CommentaryNode;68;-2231.893,1435.839;Inherit;False;1234.583;388.2111;CubeMap;5;62;64;63;65;67;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;21;-1103.344,-49.97043;Inherit;False;Property;_Specular; Specular;0;0;Create;True;0;0;False;0;False;0;4.89;0;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.InverseOpNode;47;-1873.728,2423.034;Inherit;False;1;0;FLOAT3x3;0,0,0,1,0,0,1,0,1;False;1;FLOAT3x3;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;18;-1091.817,-245.5873;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;50;-1828.148,2211.845;Inherit;False;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.ColorNode;38;-1289.981,814.8923;Inherit;False;Property;_EnvMidCol;EnvMidCol;4;0;Create;True;0;0;False;0;False;0.764151,0,0,0;0.764151,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMaxOpNode;5;-1509.122,-733.9998;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;36;-1318.235,718.2369;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;8;-1453.122,-545.9998;Inherit;False;Property;_BaseColor;BaseColor;1;0;Create;True;0;0;False;0;False;0.7801076,1,0,0;1,1,1,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;33;-1428.274,1027.534;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;7;-1224.122,-735.9998;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;52;-1619.148,2371.845;Inherit;False;False;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.PowerNode;20;-840.5125,-242.3535;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;51;-1577.148,2210.845;Inherit;False;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT3x3;0,0,0,1,0,0,1,0,1;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;64;-2168.16,1708.65;Inherit;False;Constant;_Float6;Float 6;8;0;Create;True;0;0;False;0;False;-1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;62;-2181.893,1485.839;Inherit;False;World;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;37;-1044.625,718.2369;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;29;-1292.956,361.3555;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;63;-1910.576,1492.933;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;57;-1325.018,2397.762;Inherit;False;Constant;_Float5;Float 5;8;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;22;-585.4843,-485.6135;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;44;-470.0244,816.4583;Inherit;True;Property;_Occlusuion;Occlusuion;6;0;Create;True;0;0;False;0;False;-1;None;eabfa8d88fe328f4b952fb81f530c4a4;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DotProductOpNode;55;-1352.148,2212.845;Inherit;False;2;0;FLOAT4;0,0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;25;-569.5137,-276.3835;Inherit;False;Property;_LightCol;LightCol;2;0;Create;True;0;0;False;0;False;0,1,0.6555786,0;0,1,0.6555786,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;39;-701.853,706.5431;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;24;-307.5137,-403.3835;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;43;-190.3719,592.2551;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ReflectOpNode;65;-1639.969,1493.013;Inherit;False;2;0;FLOAT3;0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;56;-1123.018,2212.762;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;42;116.2872,573.9996;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;58;-979.3894,2053.403;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;67;-1318.91,1490.531;Inherit;True;Property;_CubeMap;CubeMap;8;0;Create;True;0;0;False;0;False;-1;None;None;True;0;False;white;LockedToCube;False;Object;-1;Auto;Cube;8;0;SAMPLER2D;;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;61;280.8075,1009.857;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;1;644.4025,895.2406;Float;False;True;-1;2;ASEMaterialInspector;0;0;Standard;OldSchoolPro;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;All;14;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;0;0;False;-1;0;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;False;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;10;0;3;0
WireConnection;10;1;11;0
WireConnection;12;0;10;0
WireConnection;12;1;14;0
WireConnection;27;0;26;2
WireConnection;27;1;28;0
WireConnection;35;0;27;0
WireConnection;4;0;2;0
WireConnection;4;1;3;0
WireConnection;16;0;12;0
WireConnection;16;1;17;0
WireConnection;31;0;26;2
WireConnection;31;1;32;0
WireConnection;47;0;46;0
WireConnection;18;0;16;0
WireConnection;18;1;19;0
WireConnection;50;0;45;1
WireConnection;50;1;45;2
WireConnection;50;2;45;3
WireConnection;5;0;4;0
WireConnection;5;1;6;0
WireConnection;36;0;35;0
WireConnection;36;1;31;0
WireConnection;33;0;31;0
WireConnection;33;1;34;0
WireConnection;7;0;5;0
WireConnection;7;1;8;0
WireConnection;20;0;18;0
WireConnection;20;1;21;0
WireConnection;51;0;50;0
WireConnection;51;1;47;0
WireConnection;37;0;36;0
WireConnection;37;1;38;0
WireConnection;29;0;27;0
WireConnection;29;1;30;0
WireConnection;63;0;62;0
WireConnection;63;1;64;0
WireConnection;22;0;7;0
WireConnection;22;1;20;0
WireConnection;55;0;51;0
WireConnection;55;1;52;0
WireConnection;39;0;29;0
WireConnection;39;1;37;0
WireConnection;39;2;33;0
WireConnection;24;0;22;0
WireConnection;24;1;25;0
WireConnection;43;0;39;0
WireConnection;43;1;44;0
WireConnection;65;0;63;0
WireConnection;65;1;45;0
WireConnection;56;0;55;0
WireConnection;56;1;57;0
WireConnection;42;0;24;0
WireConnection;42;1;43;0
WireConnection;58;0;45;1
WireConnection;58;1;56;0
WireConnection;67;1;65;0
WireConnection;61;0;42;0
WireConnection;61;1;67;0
WireConnection;61;2;58;0
WireConnection;1;2;61;0
ASEEND*/
//CHKSM=6B4DBFFB2F7A3F86A81703FFC3D8C8DD5377FB9F