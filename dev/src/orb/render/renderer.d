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

module orb.render.renderer;

public import orb.render.mesh;
public import orb.scene.camera;
public import orb.text.font;
public import gfm.math.matrix;
public import gfm.math.vector;


IRenderer[string] initialize(string RndrMod, Args...)(Args args)
{
    enum modulePath = "orb." ~ RndrMod;
    mixin("import " ~ modulePath ~ " : initialize;");
    initialize(args);

    import orb.utils.traits : moduleMembers;
    IRenderer[string] renderers;

    /*static */foreach (a; moduleMembers!("orb.render.renderer", isDerivedRenderer))
    {
        enum type = getRendererType!a;
        renderers[type] = mixin(a).getInstance!(RndrMod, type)();
    }
    return renderers;
}

interface IRenderer
{
    static IRenderer getInstance(string RndrMod, string Type)()
    {
        enum modulePath = "orb." ~ RndrMod;
        mixin("import " ~ modulePath ~ ";");
        enum className = rendererPrefix ~ Type ~ "Renderer";
        return cast(IRenderer)mixin("new " ~ className);
    }

    void render();
}

interface IModelRenderer : IRenderer
{
    IModelMesh createMesh(in vec3f[] points,
                          in vec3f[] normals,
                          in uint[]  indices);
    void setDirLight(vec4f dirLight, vec4f dirColor);
    void setCamera(Camera camera);
    void setMesh(in IModelMesh mesh);
    void setModelMatrix(mat4f modelMatrix);
}

interface IChunkRenderer : IRenderer
{
    IChunkMesh createMesh();
    void setDirLight(vec4f dirLight, vec4f dirColor);
    void setCamera(Camera camera);
    void setMesh(in IChunkMesh mesh, vec3f position);
}

interface ITextRenderer : IRenderer
{
    ITextMesh createMesh(in vec2f[] points,
                         in vec2f[] texCoords,
                         in uint[]  indices);
    void load(in Font font);
    void prepare();
    void enable(in Font font);
    void setMesh(ITextMesh mesh, vec2f position, vec4f color);
    void unprepare();
}


private template isDerivedRenderer(string name)
{
    static if (name == "IRenderer")
       enum bool isDerivedRenderer = false;
    else
       enum bool isDerivedRenderer = mixin("is("~name~" == interface)");
}

private enum string getRendererType(string RndrI) =
                                        RndrI[1 .. $ - "Renderer".length];
