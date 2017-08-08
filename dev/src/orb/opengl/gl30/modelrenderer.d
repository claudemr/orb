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

module orb.opengl.gl30.modelrenderer;

public import orb.render.renderer;
public import orb.opengl.gl30.modelmesh;

import orb.opengl.shader;
import orb.utils.exception;
import derelict.opengl3.gl3;


class Gl30ModelRenderer : IModelRenderer
{
public:
    this()
    {
        import orb.opengl.gl30.programs : opengl30Programs;
        enforceOrb("chunk" in opengl30Programs, "No chunk shaders");
        mProgram = opengl30Programs["chunk"];
    }

    ~this()
    {
        destroy(mProgram);
    }

    IModelMesh createMesh(in vec3f[] points,
                          in vec3f[] normals,
                          in uint[]  indices)
    {
        return cast(IModelMesh)new Gl30ModelMesh(points, normals, indices,
                                                 mProgram.attributeLayout);
    }

    void setDirLight(vec4f dirLight, vec4f dirColor)
    {
        mProgram.use();
        mProgram.uniforms.lightRay.direction = dirLight;
        mProgram.uniforms.lightRay.color     = dirColor;
    }

    void setCamera(Camera camera)
    {
        mCamera = camera;
    }

    void setMesh(in IModelMesh mesh)
    {
        mMesh = cast(Gl30ModelMesh)mesh;
    }

    void setModelMatrix(mat4f modelMatrix)
    {
        mat4f matrixModelView     = mCamera.matrixView * modelMatrix;
        mat4f matrixModelViewProj = mCamera.matrixViewProj * modelMatrix;
        mProgram.uniforms.matrixModelView     = matrixModelView.transposed;
        mProgram.uniforms.matrixModelViewProj = matrixModelViewProj.transposed;
    }

    void render()
    {
        mMesh.vao.bind();

        glDrawElements(GL_TRIANGLES, cast(GLsizei)mMesh.vboIndices.length,
                       mMesh.vboIndices.glElementType, null);

        mMesh.vao.unbind();
    }

private:
    ShaderProgram   mProgram;
    Camera          mCamera;
    Gl30ModelMesh   mMesh;
}
