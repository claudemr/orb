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

module orb.component;

public import entitysysd;
public import gfm.math.vector;

@component struct Position
{
    vec3f pos;
}

@component struct Velocity
{
    bool  moving;
    vec3f velocity; // unit: m/s
}

@component struct Mass
{
    float mass;     // Mass of the entity (unit: kg), subject to gravity
}

@component struct Collidable
{
    vec3f prevPos;
}
