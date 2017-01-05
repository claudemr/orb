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

module orb.opengl.uniform;

public import dlib.math.matrix;
public import dlib.math.vector;
import derelict.opengl3.gl3;


struct Uniform
{
    GLint  glLocation;
    GLenum glType;

    void set(float v)
    {
        glUniform1f(glLocation, v);
    }
    void set(float v0, float v1)
    {
        glUniform2f(glLocation, v0, v1);
    }
    void set(float v0, float v1, float v2)
    {
        glUniform3f(glLocation, v0, v1, v2);
    }
    void set(float v0, float v1, float v2, float v3)
    {
        glUniform4f(glLocation, v0, v1, v2, v3);
    }
    void set(int v)
    {
        glUniform1i(glLocation, v);
    }
    void set(int v0, int v1)
    {
        glUniform2i(glLocation, v0, v1);
    }
    void set(int v0, int v1, int v2)
    {
        glUniform3i(glLocation, v0, v1, v2);
    }
    void set(int v0, int v1, int v2, int v3)
    {
        glUniform4i(glLocation, v0, v1, v2, v3);
    }
    void set(T)(in Vector!(T, 2) v)
    {
        set(v.x, v.y);
    }
    void set(T)(in Vector!(T, 3) v)
    {
        set(v.x, v.y, v.z);
    }
    void set(T)(in Vector!(T, 4) v)
    {
        set(v.x, v.y, v.z, v.w);
    }
    void set(in float[2] av)
    {
        glUniform2f(glLocation, av[0], av[1]);
    }
    void set(in float[3] av)
    {
        glUniform3f(glLocation, av[0], av[1], av[2]);
    }
    void set(in float[4] av)
    {
        glUniform4f(glLocation, av[0], av[1], av[2], av[3]);
    }
    void set(in int[2] av)
    {
        glUniform2i(glLocation, av[0], av[1]);
    }
    void set(in int[3] av)
    {
        glUniform3i(glLocation, av[0], av[1], av[2]);
    }
    void set(in int[4] av)
    {
        glUniform4i(glLocation, av[0], av[1], av[2], av[3]);
    }
    void set(in float[] av)
    {
        glUniform1fv(glLocation,
                     cast(GLsizei)av.length,
                     cast(const(GLfloat*))av.ptr);
    }
    void set(in float[2][] av)
    {
        glUniform2fv(glLocation,
                     cast(GLsizei)av.length,
                     cast(const(GLfloat*))av.ptr);
    }
    void set(in float[3][] av)
    {
        glUniform3fv(glLocation,
                     cast(GLsizei)av.length,
                     cast(const(GLfloat*))av.ptr);
    }
    void set(in float[4][] av)
    {
        glUniform4fv(glLocation,
                     cast(GLsizei)av.length,
                     cast(const(GLfloat*))av.ptr);
    }
    void set(in int[] av)
    {
        glUniform1iv(glLocation,
                     cast(GLsizei)av.length,
                     cast(const(GLint*))av.ptr);
    }
    void set(in int[2][] av)
    {
        glUniform2iv(glLocation,
                     cast(GLsizei)av.length,
                     cast(const(GLint*))av.ptr);
    }
    void set(in int[3][] av)
    {
        glUniform3iv(glLocation,
                     cast(GLsizei)av.length,
                     cast(const(GLint*))av.ptr);
    }
    void set(in int[4][] av)
    {
        glUniform4iv(glLocation,
                     cast(GLsizei)av.length,
                     cast(const(GLint*))av.ptr);
    }
    void set(in float[2][2][] av)
    {
        glUniformMatrix2fv(glLocation,
                           cast(GLsizei)av.length,
                           GL_FALSE,
                           cast(const(GLfloat*))av.ptr);
    }
    void set(in float[3][3][] av)
    {
        glUniformMatrix3fv(glLocation,
                           cast(GLsizei)av.length,
                           GL_FALSE,
                           cast(const(GLfloat*))av.ptr);
    }
    void set(in float[4][4][] av)
    {
        glUniformMatrix4fv(glLocation,
                           cast(GLsizei)av.length,
                           GL_FALSE,
                           cast(const(GLfloat*))av.ptr);
    }
    void set(in ref Matrix4f m)
    {
        glUniformMatrix4fv(glLocation,
                           1,
                           GL_FALSE,
                           cast(const(GLfloat*))m.arrayof.ptr);
    }
    void set(in Matrix4f[] am)
    {
        auto tmp = cast(float[4][4][])am;
        set(tmp);
    }
}