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

module orb.opengl.vbo;

import orb.opengl.utils;
import orb.utils.exception;
import gfm.math.vector;
import derelict.opengl3.gl3;
import std.stdio;
import std.string;
import std.traits;


template isValidVboType(T)
{
    alias U = Unqual!T;
    static if (is(U == vec4f))
        enum bool isValidVboType = true;
    else static if (is(U == vec3f))
        enum bool isValidVboType = true;
    else static if (is(U == vec2f))
        enum bool isValidVboType = true;
    else
        enum bool isValidVboType = isValidGlType!U;
}

enum BufType
{
    ARRAY = 0,
    ATOMIC_COUNTER,
    COPY_READ,
    COPY_WRITE,
    DISPATCH_INDIRECT,
    DRAW_INDIRECT,
    ELEMENT_ARRAY,
    PIXEL_PACK,
    PIXEL_UNPACK,
    QUERY,
    SHADER_STORAGE,
    TEXTURE,
    TRANSFORM_FEEDBACK,
    UNIFORM
}

enum Access
{
    STREAM = 0,
    STATIC,
    DYNAMIC
}

enum Nature
{
    DRAW = 0,
    READ,
    COPY
}

class Vbo
{
private:
    GLuint mId;
    GLenum mBufType;
    GLenum mElementType;
    size_t mElementLength;
    GLenum mValueType;
    size_t mLength;

    static immutable GLenum[BufType.max+1] glToBufTypes =
            [ BufType.ARRAY              : GL_ARRAY_BUFFER,
              BufType.ATOMIC_COUNTER     : GL_ATOMIC_COUNTER_BUFFER,
              BufType.COPY_READ          : GL_COPY_READ_BUFFER,
              BufType.COPY_WRITE         : GL_COPY_WRITE_BUFFER,
              BufType.DISPATCH_INDIRECT  : GL_DISPATCH_INDIRECT_BUFFER,
              BufType.DRAW_INDIRECT      : GL_DRAW_INDIRECT_BUFFER,
              BufType.ELEMENT_ARRAY      : GL_ELEMENT_ARRAY_BUFFER,
              BufType.PIXEL_PACK         : GL_PIXEL_PACK_BUFFER,
              BufType.PIXEL_UNPACK       : GL_PIXEL_UNPACK_BUFFER,
              BufType.SHADER_STORAGE     : GL_SHADER_STORAGE_BUFFER,
              BufType.TEXTURE            : GL_TEXTURE_BUFFER,
              BufType.TRANSFORM_FEEDBACK : GL_TRANSFORM_FEEDBACK_BUFFER,
              BufType.UNIFORM            : GL_UNIFORM_BUFFER ];

    static immutable GLenum[Access.max+1][Nature.max+1] glToUses =
            [ Nature.DRAW : [ Access.STREAM  : GL_STREAM_DRAW,
                              Access.STATIC  : GL_STATIC_DRAW,
                              Access.DYNAMIC : GL_DYNAMIC_DRAW ],
              Nature.READ : [ Access.STREAM  : GL_STREAM_READ,
                              Access.STATIC  : GL_STATIC_READ,
                              Access.DYNAMIC : GL_DYNAMIC_READ ],
              Nature.COPY : [ Access.STREAM  : GL_STREAM_COPY,
                              Access.STATIC  : GL_STATIC_COPY,
                              Access.DYNAMIC : GL_DYNAMIC_COPY ] ];

public:

    this()
    {
        glGenBuffers(1, &mId);  //(todo?) handle only 1 buffer at a time now
    }

    ~this()
    {
        if (mId != 0)
            glDeleteBuffers(1, &mId);
    }

    void set(U : T[n][], T, size_t n)(BufType type,
                                      Access access, Nature nature,
                                      in U data)
        if (isValidGlType!T || isValidGlType!(Unqual!T))
    {
        mBufType       = glToBufTypes[type];
        mLength        = data.length;
        mElementLength = n;
        mElementType   = getGlType!(Unqual!T);
        glBindBuffer(mBufType, mId);
        glBufferData(mBufType,
                     mLength * n * T.sizeof,
                     cast(const(void*))data.ptr,
                     glToUses[access][nature]);
        glBindBuffer(mBufType, 0);

    }

    void set(A : T[], T)(BufType type,
                         Access access, Nature nature,
                         in A data)
        if (isValidVboType!T)
    {
        alias U = Unqual!T;

        static if (is(U == vec4f))
        {
            mElementType   = GL_FLOAT_VEC4;
            mElementLength = 4;
            mValueType     = GL_FLOAT;
        }
        else static if (is(U == vec3f))
        {
            mElementType   = GL_FLOAT_VEC3;
            mElementLength = 3;
            mValueType     = GL_FLOAT;
        }
        else static if (is(U == vec2f))
        {
            mElementType   = GL_FLOAT_VEC2;
            mElementLength = 2;
            mValueType     = GL_FLOAT;
        }
        else
        {
            mElementType   = getGlType!U;
            mElementLength = 1;
            mValueType     = mElementType;
        }

        mBufType       = glToBufTypes[type];
        mLength        = data.length;
        bind();
        glBufferData(mBufType,
                     mLength * T.sizeof,
                     cast(const(void*))data.ptr,
                     glToUses[access][nature]);
        unbind();
    }

    void bind() const
    {
        glBindBuffer(mBufType, mId);
    }

    void unbind() const
    {
        glBindBuffer(mBufType, 0);
    }


    @property GLuint glId() const
    {
        return mId;
    }

    @property GLenum glBufType() const
    {
        return mBufType;
    }

    @property GLenum glElementType() const
    {
        return mElementType;
    }

    @property GLenum glValueType() const
    {
        return mValueType;
    }

    @property size_t elementLength() const
    {
        return mElementLength;
    }

    @property size_t length() const
    {
        return mLength;
    }
}
