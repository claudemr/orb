/* ORB - 3D/physics/IA engine
   Copyright (C) 2015 ClaudeMr

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program. If not, see <http://www.gnu.org/licenses/>. */

#version 130

// Interpolated values from the vertex shaders
in vec3 vertexNormalAtView;
in vec3 vectorVertex2CamAtView;    // vector from vertex to camera
out vec3 color;

// Directional-light already in camera-space and negated (from vertex outward)
struct LightRay
{
    vec4 direction;
    vec4 color;
};

uniform LightRay lightRay;

void main()
{
    vec3 lightDir = normalize(lightRay.direction.xyz);
    vec3 lightColor = lightRay.color.rgb;

    vec3 materialDiffuseColor  = vec3(0.1, 0.5, 0.9);
    vec3 materialAmbientColor  = vec3(0.1, 0.1, 0.1) * materialDiffuseColor;
    vec3 materialSpecularColor = vec3(0.3, 0.3, 0.3);

    vec3 normal = normalize(vertexNormalAtView);
    float cosTheta = clamp(dot(normal, lightDir), 0, 1);

    // Eye vector (towards the camera)
    vec3 eyeVec = normalize(vectorVertex2CamAtView);
    vec3 lightReflect = reflect(-lightDir, normal);
    float cosAlpha = clamp(dot(eyeVec, lightReflect), 0, 1);

    color = materialAmbientColor +
            materialDiffuseColor * lightColor * cosTheta +
            materialSpecularColor * lightColor * pow(cosAlpha, 15);
}
