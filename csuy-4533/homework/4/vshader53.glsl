/*
File Name: "vshader53.glsl":
Vertex shader:
  - Per vertex shading for a single point light source;
    distance attenuation is Yet To Be Completed.
  - Entire shading computation is done in the Eye Frame.
*/

#version 150

uniform bool flagWire;
uniform bool flagLight;
uniform bool flagShading;
uniform bool flagLightType;
uniform int flagFogType;
uniform bool flagTextureOrientation;
uniform bool flagTextureType;
uniform bool flagFrame;
uniform bool flagFloorTexture;
uniform bool flagSphereTexture;
uniform bool flagLattice;
uniform bool flagLatticeOrientation;

uniform vec4 fogColor;
uniform float fogStart;
uniform float fogEnd;
uniform float fogDensity;

in vec4 vPosition;
in vec4 vColor;
in vec4 vNormal;
in vec2 vTexture;

out vec4 fColor;
out float fTexture1d;
out vec2 fTexture2d;

uniform mat4 modelView;
uniform mat4 projection;
uniform mat3 normalMatrix;

// global
uniform vec4 globalLight;

// directional
uniform vec4 dDirection;
uniform vec4 dPosition;

uniform vec4 dAmbientProduct;
uniform vec4 dDiffuseProduct;
uniform vec4 dSpecularProduct;

uniform float dConstAtt;
uniform float dLinearAtt;
uniform float dQuadAtt;

uniform float shininess;

// positional
uniform vec4 pDirection;
uniform vec4 pPosition;

uniform vec4 pAmbientProduct;
uniform vec4 pDiffuseProduct;
uniform vec4 pSpecularProduct;

uniform float pConstAtt;
uniform float pLinearAtt;
uniform float pQuadAtt;

uniform float pAngle;
uniform float pExponent;


vec4 directional(void) {
	vec3 pos = (modelView * vPosition).xyz;

	vec3 L = normalize(-dDirection.xyz);
	vec3 E = normalize(-pos);
	vec3 H = normalize(L + E);

	// Transform vertex normal into eye coordinates
	vec3 N = normalize(normalMatrix * vNormal.xyz);

	float attenuation = 1.0;

	vec4 ambient = dAmbientProduct;

	float d = max(dot(L, N), 0.0);
	vec4 diffuse = d * dDiffuseProduct;

	float s = pow(max(dot(N, H), 0.0), shininess);
	vec4 specular = s * dSpecularProduct;

	if (dot(L, N) < 0.0) {
		specular = vec4(0.0, 0.0, 0.0, 1.0);
	}

	return attenuation * (ambient + diffuse + specular);
}

vec4 positional(void) {
	vec3 pos = (modelView * vPosition).xyz;

	vec3 L = normalize(pPosition.xyz - pos);
	vec3 E = normalize(-pos);
	vec3 H = normalize(L + E);

	vec3 N = normalize(normalMatrix * vNormal.xyz);

	float dist = distance(pPosition.xyz, pos);
	float attenuation = 1 / (pQuadAtt * pow(dist, 2) + pLinearAtt * dist + pConstAtt);

	vec4 ambient = pAmbientProduct;

	float d = max(dot(L, N), 0.0);
	vec4 diffuse = d * pDiffuseProduct;

	float s = pow(max(dot(N, H), 0.0), shininess);
	vec4 specular = s * pSpecularProduct;

	if (dot(L, N) < 0.0) {
		specular = vec4(0.0, 0.0, 0.0, 1.0);
	}

	if (flagLightType) {
		return attenuation * (ambient + diffuse + specular);
	} else {
		vec4 point = attenuation * (ambient + diffuse + specular);

		vec3 spotL = -L;
		vec3 spotFocus = normalize(pDirection.xyz - pPosition.xyz);

		float spotAttenuation = pow(dot(spotL, spotFocus), pExponent);

		vec4 spot = spotAttenuation * point;

		if (dot(spotL, spotFocus) < pAngle) {
			spot = vec4(0, 0, 0, 1);
		}

		return point + spot;
	}
}

void floorTexture(void) {
	fTexture2d = vTexture;
}

void sphereTexture(void) {
	vec3 pos = (modelView * vPosition).xyz;

	if (!flagTextureType) {
		// stripe
		if (!flagTextureOrientation) {
			// vertical
			if (flagFrame) {
				// eye frame
				fTexture1d = pos.x * 2.5;
			} else {
				// object frame
				fTexture1d = vPosition.x * 2.5;
			}
		} else {
			// slanted
			if (flagFrame) {
				// eye frame
				fTexture1d = 1.5 * (pos.x + pos.y + pos.z);
			} else {
				// object frame
				fTexture1d = 1.5 * (vPosition.x + vPosition.y + vPosition.z);
			}
		}
	} else {
		// checker
		if (!flagTextureOrientation) {
			// vertical
			if (flagFrame) {
				// eye frame
				fTexture2d = vec2(0.75 * (pos.x + 1), 0.75 * (pos.y + 1));
			} else {
				// object frame
				fTexture2d = vec2(0.75 * (vPosition.x + 1), 0.75 * (vPosition.y + 1));
			}
		} else {
			// slanted
			if (flagFrame) {
				// eye frame
				fTexture2d = vec2(0.45 * (pos.x + pos.y + pos.z), 0.45 * (pos.x - pos.y + pos.z));
			} else {
				// object frame
				fTexture2d = vec2(0.45 * (vPosition.x + vPosition.y + vPosition.z), 0.45 * (vPosition.x - vPosition.y + vPosition.z));
			}
		}
	}

	if (flagLattice) {
		if (!flagLatticeOrientation) {
			// vertical
			fTexture2d = vec2(0.5 * (vPosition.x + 1), 0.5 * (vPosition.y + 1));
		} else {
			// tilted
			fTexture2d = vec2(0.3 * (vPosition.x + vPosition.y + vPosition.z), 0.3 * (vPosition.x - vPosition.y + vPosition.z));
		}
	}
}

void main(void) {
	fColor = vColor;

	gl_Position = projection * modelView * vPosition;

	if (flagFloorTexture) {
		floorTexture();
	}

	if (flagSphereTexture && !flagWire) {
		sphereTexture();
	}

	if (flagLight && !flagWire) {
		fColor = globalLight + directional() + positional();
	}
}
