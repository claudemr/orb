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

module orb.opengl.gl30;

public import orb.opengl.gl30.chunkmesh;
public import orb.opengl.gl30.chunkrenderer;
public import orb.opengl.gl30.modelmesh;
public import orb.opengl.gl30.modelrenderer;
public import orb.opengl.gl30.textmesh;
public import orb.opengl.gl30.textrenderer;


enum string rendererPrefix = "Gl30";

void initialize(string shadersPath)
{
    import orb.opengl.gl30.programs : opengl30Programs;
    import orb.opengl.shader : lookupShaders;
    opengl30Programs = lookupShaders(shadersPath);
}