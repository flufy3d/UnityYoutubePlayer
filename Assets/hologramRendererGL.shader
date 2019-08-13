Shader "Unlit/hologramRendererGL"
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
			#pragma target 3.0
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
				//x for visibility
				float2 data : TEXCOORD1;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
				float psize : PSIZE;
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

			float depth_fix(float z)
			{
				const float minD = 555.0;
				const float maxD = 1005.0;

				float ret = (maxD - minD)*z + minD;
				ret = ret / 1000.0;

				return ret;
			}

			
			v2f vert (appdata v)
			{
				v2f o;
								
				float2 _uv;
				_uv.x = v.uv.x * 0.5f;
				_uv.y = v.uv.y;
				fixed4 col = tex2Dlod(_MainTex, float4(_uv, 0, 0));

				float3 hsl = rgb2hsl(col.xyz);

				o.data = float2(1.0,0);

				float4 pos = float4(v.vertex.x,v.vertex.y, depth_fix(hsl.x),1.0);
				o.data.x = hsl.z * 2.0;

				o.psize = _PointSize;


				o.vertex = UnityObjectToClipPos(pos);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o, o.vertex);				

				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target
			{
				if (i.data.x < 0.95f) discard;
		
				float2 _uv;
				_uv.x = i.uv.x * 0.5f + 0.5f;
				_uv.y = i.uv.y;
				// sample the texture
				fixed4 col = tex2D(_MainTex, _uv);
				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);

				return col;
			}

			ENDCG
		}
	}
}