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

module orb.opengl.gl30.textmesh;

public import orb.render.mesh;
public import orb.opengl.attribute;
public import orb.opengl.vao;
public import gfm.math.vector;

import orb.utils.exception;
import derelict.opengl3.gl3;



class Gl30TextMesh : ITextMesh
{
public:
    this(in vec2f[] points, in vec2f[] texCoords, in uint[] indices,
         in AttributeLayout attrLayout)
    {
        mVboPoints    = new Vbo;
        mVboTexCoords = new Vbo;
        mVboIndices   = new Vbo;
        mVao          = new Vao;

        mVboPoints.set(BufType.ARRAY,
                       Access.STATIC,
                       Nature.DRAW,
                       points);
        mVboTexCoords.set(BufType.ARRAY,
                          Access.STATIC,
                          Nature.DRAW,
                          texCoords);
        mVboIndices.set(BufType.ELEMENT_ARRAY,
                        Access.STATIC,
                        Nature.DRAW,
                        indices);

        mVao.bind();
        attrLayout.enable("vertexPos2d");
        attrLayout.enable("vertexTexCoord2d");
        attrLayout.set("vertexPos2d",      mVboPoints);
        attrLayout.set("vertexTexCoord2d", mVboTexCoords);
        mVboIndices.bind();
        mVao.unbind();
        mVboIndices.unbind();
        mVboTexCoords.unbind();
        attrLayout.disable("vertexPos2d");
        attrLayout.disable("vertexTexCoord2d");
    }

    ~this()
    {
        destroy(mVao);
        destroy(mVboPoints);
        destroy(mVboTexCoords);
        destroy(mVboIndices);
    }

    @property auto vboPoints() const
    {
        return mVboPoints;
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
    Vbo mVboTexCoords;
    Vbo mVboIndices;
}
