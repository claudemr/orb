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

module orb.render.mesh;
public import gfm.math.vector;

// /!\ that's all dirty, we've got to move that around
struct Vertex
{
    vec3f   point;
    vec3f   normal;
    bool    isNormalCalculated;
    Face*[] faces;
}

struct Face
{
    this(Vertex* v0, Vertex* v1, Vertex* v2)
    {
        vertices  = [v0, v1, v2];
        normal = cross(v0.point - v1.point, v1.point - v2.point).normalized;
    }

    void getTriVertices(ref vec3f[] pts, ref vec3f[] nms)
    {
        foreach (i; 0 .. 3)
        {
            pts ~= vertices[i].point;

            if (!vertices[i].isNormalCalculated)
            {
                auto n = vec3f(0, 0, 0);
                foreach (face; vertices[i].faces)
                    n += face.normal;
                vertices[i].normal = n.normalized;
                vertices[i].isNormalCalculated = true;
            }
            nms ~= vertices[i].normal;
        }
    }

    Vertex*[3]  vertices;
    vec3f       normal;
}

interface IChunkMesh
{
    Vertex* insertVertex(vec3f p);
    void insertFace(Vertex* v0, Vertex* v1, Vertex* v2);
    void commit();
}

interface IModelMesh
{
    //empty at the moment. Just for the purpose of being a handle.
}

interface ITextMesh
{
    //empty at the moment. Just for the purpose of being a handle.
}
