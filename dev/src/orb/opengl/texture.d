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

module orb.opengl.texture;

import orb.utils.exception;
import derelict.opengl3.gl3;
import std.string;

/*enum Target
{
    single1d,
    single2d,
    single3d,
    array1d,
    array2d,
    rectangle,
    cubeMap,
    cubeMapArray,
    buffer,
    multisample2d,
    multisampleArray2d
}

immutable GLenum[Target.max+1] glToTargets =
        [ Target.single1d           : GL_TEXTURE_1D,
          Target.single2d           : GL_TEXTURE_2D,
          Target.single3d           : GL_TEXTURE_3D,
          Target.array1d            : GL_TEXTURE_1D_ARRAY,
          Target.array2d            : GL_TEXTURE_2D_ARRAY,
          Target.rectangle          : GL_TEXTURE_RECTANGLE,
          Target.cubeMap            : GL_TEXTURE_CUBE_MAP,
          Target.cubeMapArray       : GL_TEXTURE_CUBE_MAP_ARRAY,
          Target.buffer             : GL_TEXTURE_BUFFER,
          Target.multisample2d      : GL_TEXTURE_2D_MULTISAMPLE,
          Target.multisampleArray2d : GL_TEXTURE_2D_MULTISAMPLE_ARRAY ];

GL_TEXTURE_2D, GL_PROXY_TEXTURE_2D,
GL_TEXTURE_1D_ARRAY, GL_PROXY_TEXTURE_1D_ARRAY,
GL_TEXTURE_RECTANGLE, GL_PROXY_TEXTURE_RECTANGLE,
GL_TEXTURE_CUBE_MAP_POSITIVE_X,
GL_TEXTURE_CUBE_MAP_NEGATIVE_X,
GL_TEXTURE_CUBE_MAP_POSITIVE_Y,
GL_TEXTURE_CUBE_MAP_NEGATIVE_Y,
GL_TEXTURE_CUBE_MAP_POSITIVE_Z,
GL_TEXTURE_CUBE_MAP_NEGATIVE_Z, or
GL_PROXY_TEXTURE_CUBE_MAP

enum Type
{

}
GL_UNSIGNED_BYTE,
GL_BYTE,
GL_UNSIGNED_SHORT,
GL_SHORT,
GL_UNSIGNED_INT,
GL_INT,
GL_FLOAT,
GL_UNSIGNED_BYTE_3_3_2,
GL_UNSIGNED_BYTE_2_3_3_REV,
GL_UNSIGNED_SHORT_5_6_5,
GL_UNSIGNED_SHORT_5_6_5_REV,
GL_UNSIGNED_SHORT_4_4_4_4,
GL_UNSIGNED_SHORT_4_4_4_4_REV,
GL_UNSIGNED_SHORT_5_5_5_1,
GL_UNSIGNED_SHORT_1_5_5_5_REV,
GL_UNSIGNED_INT_8_8_8_8,
GL_UNSIGNED_INT_8_8_8_8_REV,
GL_UNSIGNED_INT_10_10_10_2, and
GL_UNSIGNED_INT_2_10_10_10_REV*/

//todo at the moment, we only use 2D RGBA uncompressed textures.
//     generalization (using templates?) may be done later

class Texture
{
private:
    GLuint mId;
    //GLenum target;

public:

    this()
    {
        // generate 1 buffer
        glGenTextures(1, &mId);
    }

    ~this()
    {
        // generate 1 buffer
        if (mId >= 0)
            glDeleteTextures(1, &mId);
    }

    void set2dRgbaUncomp(const void *data, uint width, uint height)
    {
        glBindTexture(GL_TEXTURE_2D, mId);
        glTexImage2D(GL_TEXTURE_2D,
                     0,             // level 0, no mipmapping
                     GL_RGBA,
                     width, height,
                     0,             // border, must be 0
                     GL_RGBA,
                     GL_UNSIGNED_BYTE,
                     data);

        // linear interpolation sampling with mip-mapping
        glGenerateMipmap(GL_TEXTURE_2D);
        // Level of detail of mip-mapping to default
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_LOD_BIAS, 0.0f);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER,
                        GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
                        GL_LINEAR_MIPMAP_LINEAR);
        /* exact sampling
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);*/
        /* linear interpolation sampling
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);*/

        glBindTexture(GL_TEXTURE_2D, 0);
        enforceGl();
    }
    @property const GLuint glId()
    {
        return mId;
    }
}
