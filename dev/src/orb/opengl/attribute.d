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
module orb.opengl.attribute;

public import orb.opengl.vbo;

import orb.utils.exception;
import derelict.opengl3.gl3;


struct Attribute
{
    GLint  glLocation;
    GLenum glType;
}

struct AttributeLayout
{
    Attribute[string] attributes;

    void enable(in string name) const
    {
        auto attr = name in attributes;
        enforceOrb(attr !is null, "Attribute does not exist " ~ name);
        glEnableVertexAttribArray(attr.glLocation);
    }

    void disable(in string name) const
    {
        auto attr = name in attributes;
        enforceOrb(attr !is null, "Attribute does not exist");
        glDisableVertexAttribArray(attr.glLocation);
    }

    void set(string name, in Vbo vbo) const
    {
        auto attr = name in attributes;
        enforceOrb(attr !is null, "Attribute does not exist");
        glBindBuffer(vbo.glBufType, vbo.glId);
        glVertexAttribPointer(attr.glLocation,
                              cast(GLuint)vbo.elementLength,
                              vbo.glValueType,
                              GL_FALSE, // not normalized
                              0,        // stride
                              null);    // buf offset
    }
}