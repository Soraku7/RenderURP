// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "OldSchoolPlus"
{
	Properties
	{
		_Specular("Specular", Range( 1 , 10)) = 1
		_BaseCol("BaseCol", Color) = (0,0.1698113,0.001764873,0)
		_TextureSample0("Texture Sample 0", 2D) = "white" {}
		_EnvUpCol("EnvUpCol", Color) = (0.4968057,0.7169812,0.3551086,0)
		_EnvSideCol("EnvSideCol", Color) = (0.3127408,0.7924528,0.1233535,0)
		_EnvDownCol("EnvDownCol", Color) = (0.1191118,0.5471698,0,0)
		_LightCol("LightCol", Color) = (0,0.8980392,0.6733639,0)
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
		struct Input
		{
			float3 worldNormal;
			float3 worldPos;
			float3 viewDir;
			float2 uv_texcoord;
		};

		uniform float4 _BaseCol;
		uniform float _Specular;
		uniform float4 _LightCol;
		uniform float4 _EnvUpCol;
		uniform float4 _EnvSideCol;
		uniform float4 _EnvDownCol;
		uniform sampler2D _TextureSample0;
		SamplerState sampler_TextureSample0;
		uniform float4 _TextureSample0_ST;

		void surf( Input i , inout SurfaceOutputStandard o )
		{
			float3 ase_worldNormal = i.worldNormal;
			float3 ase_worldPos = i.worldPos;
			#if defined(LIGHTMAP_ON) && UNITY_VERSION < 560 //aseld
			float3 ase_worldlightDir = 0;
			#else //aseld
			float3 ase_worldlightDir = normalize( UnityWorldSpaceLightDir( ase_worldPos ) );
			#endif //aseld
			float dotResult3 = dot( ase_worldNormal , ase_worldlightDir );
			float dotResult22 = dot( reflect( ( ase_worldlightDir * -1.0 ) , ase_worldNormal ) , i.viewDir );
			float temp_output_29_0 = max( ase_worldNormal.y , 0.0 );
			float temp_output_35_0 = max( ( ase_worldNormal.y * -1.0 ) , 0.0 );
			float2 uv_TextureSample0 = i.uv_texcoord * _TextureSample0_ST.xy + _TextureSample0_ST.zw;
			o.Emission = ( ( ( ( max( dotResult3 , 0.0 ) * _BaseCol ) + pow( max( dotResult22 , 0.0 ) , _Specular ) ) * _LightCol ) + ( ( ( ( temp_output_29_0 * _EnvUpCol ) + ( ( ( 1.0 - temp_output_29_0 ) - temp_output_35_0 ) * _EnvSideCol ) ) + ( temp_output_35_0 * _EnvDownCol ) ) * tex2D( _TextureSample0, uv_TextureSample0 ).r ) ).rgb;
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
				float3 worldPos : TEXCOORD2;
				float3 worldNormal : TEXCOORD3;
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
				o.worldNormal = worldNormal;
				o.customPack1.xy = customInputData.uv_texcoord;
				o.customPack1.xy = v.texcoord;
				o.worldPos = worldPos;
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
				float3 worldPos = IN.worldPos;
				half3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				surfIN.viewDir = worldViewDir;
				surfIN.worldPos = worldPos;
				surfIN.worldNormal = IN.worldNormal;
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
97;228;1280;707;2280.915;561.8579;1;True;True
Node;AmplifyShaderEditor.CommentaryNode;21;-1824.219,-288.1083;Inherit;False;1506.475;383.0322;Phong;11;20;10;11;13;12;14;16;17;19;22;51;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;46;-2008.355,340.9815;Inherit;False;2275.619;1038.973;3Col;19;44;37;39;43;32;38;42;41;31;40;35;33;29;36;27;34;30;47;48;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;34;-1831.296,1171.282;Inherit;False;Constant;_Float4;Float 4;1;0;Create;True;0;0;False;0;False;-1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.WorldNormalVector;27;-1958.355,491.8284;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;51;-1764.915,-240.8579;Inherit;False;False;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;30;-1638.441,558.2702;Inherit;False;Constant;_Float3;Float 3;1;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;10;-1695.334,-63.10829;Inherit;False;Constant;_Float1;Float 1;0;0;Create;True;0;0;False;0;False;-1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;8;-1550.65,-888.884;Inherit;False;1004.964;474.0526;Lambort;7;3;5;4;6;7;2;1;;1,1,1,1;0;0
Node;AmplifyShaderEditor.WorldNormalVector;13;-1470.922,-101.0761;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;11;-1483.334,-238.1083;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;29;-1473.934,391.279;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;33;-1622.296,1068.282;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;36;-1546.637,1203.134;Inherit;False;Constant;_Float5;Float 5;1;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;35;-1355.637,1069.134;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;14;-1182.922,-93.0761;Inherit;False;World;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;2;-1515.65,-614.7446;Inherit;False;False;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.ReflectOpNode;12;-1269.922,-238.076;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.OneMinusNode;40;-1351.524,739.2437;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldNormalVector;1;-1509.328,-795.9985;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;5;-1156.299,-618.3008;Inherit;False;Constant;_Float0;Float 0;0;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;42;-1143.596,856.1874;Inherit;False;Property;_EnvSideCol;EnvSideCol;4;0;Create;True;0;0;False;0;False;0.3127408,0.7924528,0.1233535,0;0.3127408,0.7924528,0.1233535,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;31;-1295.056,527.9814;Inherit;False;Property;_EnvUpCol;EnvUpCol;3;0;Create;True;0;0;False;0;False;0.4968057,0.7169812,0.3551086,0;0.4968057,0.7169812,0.3551086,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;17;-920.6556,-50.29402;Inherit;False;Constant;_Float2;Float 2;0;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;22;-980.9948,-231.7096;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;41;-1143.601,739.9014;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;3;-1206.127,-791.1749;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;32;-1026.056,390.9815;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;38;-1304.637,1194.134;Inherit;False;Property;_EnvDownCol;EnvDownCol;5;0;Create;True;0;0;False;0;False;0.1191118,0.5471698,0,0;0.1191118,0.5471698,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMaxOpNode;4;-958.2565,-789.1972;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;19;-746.7431,-50.96369;Inherit;False;Property;_Specular;Specular;0;0;Create;True;0;0;False;0;False;1;1;1;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;6;-945.6849,-626.8313;Inherit;False;Property;_BaseCol;BaseCol;1;0;Create;True;0;0;False;0;False;0,0.1698113,0.001764873,0;0,0.1698113,0.001764873,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;43;-891.5962,739.1874;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;16;-746.6556,-233.294;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;7;-684.0919,-788.6947;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;37;-1077.637,1071.134;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.PowerNode;20;-494.7427,-228.9636;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;39;-708.6,581.3088;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;18;-194.5337,-325.5052;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;48;-348.3044,826.8322;Inherit;True;Property;_TextureSample0;Texture Sample 0;2;0;Create;True;0;0;False;0;False;-1;eabfa8d88fe328f4b952fb81f530c4a4;eabfa8d88fe328f4b952fb81f530c4a4;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;25;-216.5561,-148.5264;Inherit;False;Property;_LightCol;LightCol;6;0;Create;True;0;0;False;0;False;0,0.8980392,0.6733639,0;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;44;-435.473,585.8522;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;47;-30.87027,588.4072;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;26;16.01153,-322.5264;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;45;277.6899,45.79346;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;575.1735,-93.43646;Float;False;True;-1;2;ASEMaterialInspector;0;0;Standard;OldSchoolPlus;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;All;14;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;0;0;False;-1;0;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;False;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;11;0;51;0
WireConnection;11;1;10;0
WireConnection;29;0;27;2
WireConnection;29;1;30;0
WireConnection;33;0;27;2
WireConnection;33;1;34;0
WireConnection;35;0;33;0
WireConnection;35;1;36;0
WireConnection;12;0;11;0
WireConnection;12;1;13;0
WireConnection;40;0;29;0
WireConnection;22;0;12;0
WireConnection;22;1;14;0
WireConnection;41;0;40;0
WireConnection;41;1;35;0
WireConnection;3;0;1;0
WireConnection;3;1;2;0
WireConnection;32;0;29;0
WireConnection;32;1;31;0
WireConnection;4;0;3;0
WireConnection;4;1;5;0
WireConnection;43;0;41;0
WireConnection;43;1;42;0
WireConnection;16;0;22;0
WireConnection;16;1;17;0
WireConnection;7;0;4;0
WireConnection;7;1;6;0
WireConnection;37;0;35;0
WireConnection;37;1;38;0
WireConnection;20;0;16;0
WireConnection;20;1;19;0
WireConnection;39;0;32;0
WireConnection;39;1;43;0
WireConnection;18;0;7;0
WireConnection;18;1;20;0
WireConnection;44;0;39;0
WireConnection;44;1;37;0
WireConnection;47;0;44;0
WireConnection;47;1;48;1
WireConnection;26;0;18;0
WireConnection;26;1;25;0
WireConnection;45;0;26;0
WireConnection;45;1;47;0
WireConnection;0;2;45;0
ASEEND*/
//CHKSM=090E3521EA2EA7AE7018BBE8779C0676A8AD3B75