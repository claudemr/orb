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

module orb.opengl.gl30.meshrenderer;

public import orb.render.renderer;
public import orb.opengl.gl30.mesh;

import orb.opengl.shader;
import orb.utils.exception;
import derelict.opengl3.gl3;


class Gl30MeshRenderer : IMeshRenderer
{
public:
    this(string vertexShaderCode, string fragmentShaderCode)
    {
        mProgram = loadShaders(fragmentShaderCode, vertexShaderCode);
    }

    ~this()
    {
        destroy(mProgram);
    }

    IMesh createMesh(in Vector3f[] points,
                     in Vector3f[] normals,
                     in uint[] indices)
    {
        return cast(IMesh)new Gl30Mesh(points, normals, indices,
                                       mProgram.attributeLayout);
    }

    void setDirLight(Vector4f dirLight, Color4f dirColor)
    {
        mProgram.use();
        mProgram.uniforms.lightRay.direction = dirLight;
        mProgram.uniforms.lightRay.color     = dirColor;
    }

    void setCamera(Camera camera)
    {
        mCamera = camera;
    }

    void setModelPlacement(Matrix4f model)
    {
        Matrix4f matrixModelView     = mCamera.matrixView * model;
        Matrix4f matrixModelViewProj = mCamera.matrixViewProj * model;
        mProgram.uniforms.matrixModelView     = matrixModelView;
        mProgram.uniforms.matrixModelViewProj = matrixModelViewProj;
    }

    void setMesh(in IMesh mesh)
    {
        mMesh = cast(Gl30Mesh)mesh;
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
    Gl30Mesh        mMesh;
}
