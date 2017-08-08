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
public import gfm.math.matrix;
public import gfm.math.vector;


interface IMeshRenderer
{
    IMesh createMesh();
    void setDirLight(vec4f dirLight, vec4f dirColor);
    void setCamera(Camera camera);
    void setMesh(in IMesh mesh);
    void setModelPlacement(mat4f model);
    void render();
}


interface ITextRenderer
{
    ITextMesh createMesh(in vec2f[] points,
                         in vec2f[] texCoords,
                         in uint[] indices);
    void load(in Font font);
    void prepare();
    void enable(in Font font);
    void render(ITextMesh tm, vec2f position, vec4f color);
    void unprepare();
}
