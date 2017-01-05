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

module orb.render.renderer;

public import orb.render.mesh;
public import orb.scene.camera;
public import orb.text.font;
public import dlib.image.color;
public import dlib.math.matrix;
public import dlib.math.vector;


interface IMeshRenderer
{
    IMesh createMesh(in Vector3f[] points,
                     in Vector3f[] normals,
                     in uint[] indices);
    void setDirLight(Vector4f dirLight, Color4f dirColor);
    void setCamera(Camera camera);
    void setMesh(in IMesh mesh);
    void setModelPlacement(Matrix4f model);
    void render();
}


interface ITextRenderer
{
    ITextMesh createMesh(in Vector2f[] points,
                         in Vector2f[] texCoords,
                         in uint[] indices);
    void load(in Font font);
    void prepare();
    void enable(in Font font);
    void render(ITextMesh tm, Vector2f position, Color4f color);
    void unprepare();
}
