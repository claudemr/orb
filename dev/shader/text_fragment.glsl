/* ORB - 3D/physics/AI engine
   Copyright (C) 2015-2017 Claude

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

in  vec2 fragTexCoord2d;
out vec4 fragColor;

uniform sampler2D texId;
uniform vec3      color;

//todo use uniform to change them
const float thickness = 0.5;  // thickness of the character
const float smoothing  = 0.1; // smoothing value to avoid aliasing

void main()
{
    float dist  = 1.0 - texture(texId, fragTexCoord2d).a;
    float alpha = 1.0 - smoothstep(thickness, thickness + smoothing, dist);

    fragColor = vec4(color, alpha);
}