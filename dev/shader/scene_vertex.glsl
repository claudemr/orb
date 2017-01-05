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

/*struct LightPoint
{
    vec4 position;
    vec4 color;
    float coefA;
    float coefB;
};*/

in  vec3 vertexPosition;
in  vec3 vertexNormal;

out vec3 vertexNormalAtView;
out vec3 vectorVertex2CamAtView;    // vector from vertex to camera


uniform mat4 matrixModelView;
uniform mat4 matrixModelViewProj;

void main()
{
    gl_Position = matrixModelViewProj * vec4(vertexPosition, 1);

    // Vector that goes from the vertex to the camera, in camera space.
    // In camera space, the camera is at the origin (0,0,0).
    vec3 vertexPositionAtView = (matrixModelView * vec4(vertexPosition, 1)).xyz;
    vectorVertex2CamAtView = vec3(0,0,0) - vertexPositionAtView;

    vertexNormalAtView = (matrixModelView * vec4(vertexNormal, 0)).xyz;
}
