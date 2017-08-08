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

in  vec2 vertexPos2d;
in  vec2 vertexTexCoord2d;
out vec2 fragTexCoord2d;

uniform vec2 position;

void main()
{
    gl_Position.x = (vertexPos2d.x + position.x) * 2 - 1;
    gl_Position.y = (vertexPos2d.y + position.y) * -2 + 1;
    gl_Position.z  = 0.0;
    gl_Position.w  = 1.0;
    fragTexCoord2d = vertexTexCoord2d;
}