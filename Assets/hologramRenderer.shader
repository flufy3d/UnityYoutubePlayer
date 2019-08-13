Shader "Unlit/hologramRenderer"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_PointSize("PointSize", Range(0, 0.1)) = 0.005
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma target 4.0
			#pragma vertex vert
			#pragma geometry geom
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
				//x for visibility
				float2 data : TEXCOORD1;
				UNITY_FOG_COORDS(1)
				float4 pos : SV_POSITION;
				float4 col : COLOR;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _PointSize;

			const float minD = 555.0;
			const float maxD = 1005.0;

			// taken from freenect example
			const float wAmount = 640.0; // TODO move to uniform
			const float hAmount = 480.0; // TODO move to uniform
			const float f = 595.0; // devide by wAmoutn to normalize


			float3 rgb2hsl(float3 color) {
				float h = 0.0;
				float s = 0.0;
				float l = 0.0;
				float r = color.r;
				float g = color.g;
				float b = color.b;
				float cMin = min(r, min(g, b));
				float cMax = max(r, max(g, b));
				l = (cMax + cMin) / 2.0;
				if (cMax > cMin) {
					float cDelta = cMax - cMin;
					// saturation
					if (l < 0.5) {
						s = cDelta / (cMax + cMin);
					}
					else {
						s = cDelta / (2.0 - (cMax + cMin));
					}
					// hue
					if (r == cMax) {
						h = (g - b) / cDelta;
					}
					else if (g == cMax) {
						h = 2.0 + (b - r) / cDelta;
					}
					else {
						h = 4.0 + (r - g) / cDelta;
					}
					if (h < 0.0) {
						h += 6.0;
					}
					h = h / 6.0;
				}
				return float3(h, s, l);
			}

			float3 xyz(float x, float y, float depth) {
				float outputMin = 0.0;
				float outputMax = 1.0;
				float inputMax = maxD;
				float inputMin = minD;
				float zDelta = inputMin + (inputMax - inputMax) / 2.0;

				float z =
					((depth - outputMin) / (outputMax - outputMin)) * (inputMax - inputMin) +
					inputMin;

				return float3(x * (wAmount * 2.0) * z / f, // X = (x - cx) * d / fx
					y * (wAmount * 2.0) * z / f, // Y = (y - cy) * d / fy
					-z + zDelta);              // Z = d
			}

			
			v2f vert (appdata v)
			{
				v2f o;
								
				float2 _uv,_uv1;
				_uv.x = v.uv.x * 0.5f;
				_uv.y = v.uv.y;
				_uv1.x = v.uv.x * 0.5f + 0.5;
				_uv1.y = v.uv.y;
				fixed4 col = tex2Dlod(_MainTex, float4(_uv, 0, 0));

				float3 hsl = rgb2hsl(col.xyz);

				o.data = float2(1.0,0);

				float4 pos = float4(v.vertex.x,v.vertex.y,hsl.x,1.0);
				o.data.x = hsl.z * 2.0;



				o.pos = pos;
				o.col = tex2Dlod(_MainTex, float4(_uv1, 0, 0));
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o, o.vertex);				

				return o;
			}
			
			// Geometry Shader -----------------------------------------------------
			[maxvertexcount(4)]
			void geom(point v2f p[1], inout TriangleStream<v2f> triStream)
			{
				if (p[0].data.x > 0.95f)
				{
					float3 look = UNITY_MATRIX_IT_MV[2].xyz;
					float3 up = float3(0, 1, 0);
					up = normalize(up);
					look = normalize(look);
					float3 right = cross(up, look);

					float halfS = 0.5f * _PointSize;

					float4 v[4];
					v[0] = float4(p[0].pos + halfS * right - halfS * up, 1.0f);
					v[1] = float4(p[0].pos + halfS * right + halfS * up, 1.0f);
					v[2] = float4(p[0].pos - halfS * right - halfS * up, 1.0f);
					v[3] = float4(p[0].pos - halfS * right + halfS * up, 1.0f);

					v2f pIn = (v2f)0;					

					pIn.pos = UnityObjectToClipPos(v[0]);
					pIn.col = p[0].col;
					triStream.Append(pIn);

					pIn.pos = UnityObjectToClipPos(v[1]);
					pIn.col = p[0].col;
					triStream.Append(pIn);

					pIn.pos = UnityObjectToClipPos(v[2]);
					pIn.col = p[0].col;
					triStream.Append(pIn);

					pIn.pos = UnityObjectToClipPos(v[3]);
					pIn.col = p[0].col;
					triStream.Append(pIn);
				}
				
			}

			fixed4 frag(v2f i) : SV_Target
			{
				return i.col;
			}

			ENDCG
		}
	}
}
