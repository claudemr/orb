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

module orb.opengl.gl30.modelmesh;

public import orb.render.mesh;
public import orb.opengl.attribute;
public import orb.opengl.vao;
public import gfm.math.vector;

import orb.utils.geometry;
import derelict.opengl3.gl3;


class Gl30ModelMesh : IModelMesh
{
public:
    this(in vec3f[] points, in vec3f[] normals, in uint[] indices,
         in AttributeLayout attrLayout)
    {
        mVboPoints  = new Vbo;
        mVboNormals = new Vbo;
        mVboIndices = new Vbo;
        mVao        = new Vao;

        mVboPoints.set(BufType.ARRAY,
                       Access.STATIC,
                       Nature.DRAW,
                       points);
        mVboNormals.set(BufType.ARRAY,
                        Access.STATIC,
                        Nature.DRAW,
                        normals);
        mVboIndices.set(BufType.ELEMENT_ARRAY,
                        Access.STATIC,
                        Nature.DRAW,
                        indices);

        mVao = new Vao;
        mVao.bind();
        attrLayout.enable("vertexPosition");
        attrLayout.enable("vertexNormal");
        attrLayout.set("vertexPosition", mVboPoints);
        attrLayout.set("vertexNormal",   mVboNormals);
        mVboIndices.bind();
        mVao.unbind();
        mVboIndices.unbind();
        mVboNormals.unbind();
        attrLayout.disable("vertexPosition");
        attrLayout.disable("vertexNormal");

    }

    ~this()
    {
        destroy(mVao);
        destroy(mVboPoints);
        destroy(mVboNormals);
        destroy(mVboIndices);
    }

    @property auto vboPoints() const
    {
        return mVboPoints;
    }

    @property auto vboNormals() const
    {
        return mVboNormals;
    }

    @property auto vboIndices() const
    {
        return mVboIndices;
    }

    @property auto vao() const
    {
        return mVao;
    }

private:
    Vao mVao;
    Vbo mVboPoints;
    Vbo mVboNormals;
    Vbo mVboIndices;
}
