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

module orb.opengl.gl30.chunkmesh;

public import orb.render.mesh;
public import orb.opengl.attribute;
public import orb.opengl.vao;
public import gfm.math.vector;

import orb.utils.geometry;
import std.container.slist;
import derelict.opengl3.gl3;


class Gl30ChunkMesh : IChunkMesh
{
public:
    this(in AttributeLayout attrLayout)
    {
        mVboPoints  = new Vbo;
        mVboNormals = new Vbo;
        mVboIndices = new Vbo;
        mVao        = new Vao;
        mVertices   = SList!Vertex();
        mFaces      = SList!Face();
        mAttrLayout = attrLayout;
    }

    Vertex* insertVertex(vec3f p)
    {
        Vertex vtx;
        vtx.point  = p;
        vtx.faces  = [];
        vtx.isNormalCalculated = false;
        mVertices.insertFront(vtx);

        return &mVertices.front();
    }

    void insertFace(Vertex* v0, Vertex* v1, Vertex* v2)
    {
        // compute the area of the face, and drop it if
        // the area is too small
        auto faceArea2 = area2(v0.point, v1.point, v2.point);
        if (faceArea2 < 1e-7)
            return;

        auto face = Face(v0, v1, v2);
        mFaces.insertFront(face);
        v0.faces ~= &mFaces.front();
        v1.faces ~= &mFaces.front();
        v2.faces ~= &mFaces.front();
    }

    void commit()
    {
        vec3f[] points = [];
        vec3f[] normals = [];
        foreach (face; mFaces)
            face.getTriVertices(points, normals);

        import std.range : iota;
        import std.array : array;
        uint[] indices = iota!uint(0, cast(uint)points.length).array;

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

        mVao.bind();
        mAttrLayout.enable("vertexPosition");
        mAttrLayout.enable("vertexNormal");
        mAttrLayout.set("vertexPosition", mVboPoints);
        mAttrLayout.set("vertexNormal",   mVboNormals);
        mVboIndices.bind();
        mVao.unbind();
        mVboIndices.unbind();
        mVboNormals.unbind();
        mAttrLayout.disable("vertexPosition");
        mAttrLayout.disable("vertexNormal");
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
    SList!Vertex    mVertices;
    SList!Face      mFaces;
    const(AttributeLayout) mAttrLayout;
}
