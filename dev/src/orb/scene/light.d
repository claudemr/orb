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

module orb.scene.light;

public import dlib.image.color;

import dlib.math.vector;

class DirLight
{
    this(Vector4f direction, Color4f   color)
    {
        this.direction = direction;
        this.color     = color;
    }

    Vector4f direction;
    Color4f  color;
}