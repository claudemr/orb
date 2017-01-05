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

module orb.world;
/+
import dlib.math.quaternion;
import dlib.math.vector;

import orb.densitymap;
import orb.noise;
import orb.ui;


class World
{
public:
    this(UserInterface ui)
    {
        mUi = ui;

        //*** Physics init ***
        mGravityAccel  = 9.8;
        mAirResistance = 0.5;

        //*** Generate density map ***
        /+enum int SIZE = 4;
        auto densityMap = new DensityMap!(SIZE, SIZE, SIZE);
        densityMap.map =
                /*[[[0.0,0.0,0.0,0.0], [0.0,0.0,0.5,0.0], [0.0,0.5,0.0,0.0], [0.0,0.0,0.0,0.0]],
                 [[0.0,0.5,0.5,0.0], [0.0,1.0,1.0,0.0], [0.0,1.0,1.0,0.0], [0.0,0.0,0.5,0.0]],
                 [[0.0,0.5,0.5,0.0], [0.0,1.0,1.0,0.0], [0.0,1.0,0.5,0.0], [0.0,0.0,0.0,0.0]],
                 [[0.0,0.0,0.0,0.0], [0.0,0.5,0.0,0.0], [0.0,0.0,0.0,0.0], [0.0,0.0,0.0,0.0]]];*/
                [[[-1.0f,-1.0f,-1.0f,-1.0f], [-1.0f,-1.0f,-1.0f,-1.0f], [-1.0f,-1.0f,-1.0f,-1.0f], [-1.0f,-1.0f,-1.0f,-1.0f]],
                 [[-1.0f,-1.0f,-1.0f,-1.0f], [-1.0f, 1.0f, 1.0f,-1.0f], [-1.0f, 1.0f, 1.0f,-1.0f], [-1.0f,-1.0f,-1.0f,-1.0f]],
                 [[-1.0f,-1.0f,-1.0f,-1.0f], [-1.0f, 1.0f, 1.0f,-1.0f], [-1.0f, 1.0f, 1.0f,-1.0f], [-1.0f,-1.0f,-1.0f,-1.0f]],
                 [[-1.0f,-1.0f,-1.0f,-1.0f], [-1.0f,-1.0f,-1.0f,-1.0f], [-1.0f,-1.0f,-1.0f,-1.0f], [-1.0f,-1.0f,-1.0f,-1.0f]]];+/

        enum SIZE = 18;
        auto densityMap = new DensityMap!(SIZE, SIZE, SIZE);
        Vector3f v, center;
        center  = vectorf(9.0f, 9.0f, 9.0f);
        mSize   = SIZE;
        mRadius = 6;

        for (int x = 0; x < SIZE; x++)
            for (int y = 0; y < SIZE; y++)
                for (int z = 0; z < SIZE; z++)
                {
                    v = vectorf(cast(float)x, cast(float)y, cast(float)z);
                    v -= center;
                    densityMap.map[x][y][z] = mRadius + 0.5f - v.length();
                    densityMap.map[x][y][z] += noise(v.x*0.15, v.y*0.15, v.z*0.15) * 1.0;
                    /*
                    // Try to find a formulae that creates a cloud
                    auto ns = noise(v.x*0.15, v.y*0.15, v.z*0.15);
                    ns = sqrt((3.0 - ns) * (1 + ns)) - 1.0;
                    densityMap.map[x][y][z] += ns * 1.0;*/
                }

        //*** Tesselation ***
        densityMap.tesselate(NormalGeneration.VERTEX_NORMALS);
        mPoints   = densityMap.points;
        mNormals  = densityMap.normals.dup;
        mVertices = densityMap.vertexIds;

        foreach (ref normal; mNormals)
            normal.normalize();
    }

    @property
    Vector3f[] points()
    {
        return mPoints;
    }
    @property
    Vector3f[] normals()
    {
        return mNormals;
    }
    @property
    VertexId[] vertexIds()
    {
        return mVertices;
    }
    @property
    uint size()
    {
        return mSize;
    }
    @property
    float radius()
    {
        return mRadius;
    }

private:

    //*** Physics ***
    // Gravity acceleration (on earth 9.8m/sec2)
    float mGravityAccel;
    // Like the resistance of the air of the world
    // Air density: 1.225 kg/m³
    // Water density: 1 g/cm³ = 1000 kg/m³
    // Resistance = Cd * 0.5 * AirDensity (see Entity doc)
    float mAirResistance;
    // Size of the cube embedding the world
    uint  mSize;
    // Radius of the planet (in meters)
    float mRadius;

    //*** Mesh data ***
    Vector3f[] mPoints, mNormals;
    VertexId[] mVertices;

    //*** User Interface for rendering
    UserInterface mUi;
}+/
/+

private:

/*
 * Setup a quaternion to represent rotation
 * between two unit-length vectors within an angle range
 */
Quaternion!(T) rotationBetween(T, CosMin)(Vector!(T,3) a, Vector!(T,3) b, T max)
{
    Quaternion!(T) q;

    float d = dot(a, b);
    float angle = acos(d);

    if (angle > max)
        angle = max;

    Vector!(T,3) axis;
    if (d < -0.9999)
    {
        Vector!(T,3) c;
        if (a.y != 0.0 || a.z != 0.0)
            c = Vector!(T,3)(1, 0, 0);
        else
            c = Vector!(T,3)(0, 1, 0);
        axis = cross(a, c);
        axis.normalize();
        q = rotation(axis, angle);
    }
    else if (d > CosMin)
    {
        q = Quaternion!(T).identity;
    }
    else
    {
        axis = cross(a, b);
        axis.normalize();
        q = rotation(axis, angle);
    }

    return q;
}

+/
/*
Metal densities:
http://www.coolmagnetman.com/magconda.htm
water    1.00 g/cm³
aluminum 2.70 g/cm³
zinc     7.13 g/cm³
tin      7.36 g/cm³
iron     7.87 g/cm³
copper   8.96 g/cm³
silver   10.49 g/cm³
lead     11.36 g/cm³
mercury  13.55 g/cm³
gold     19.32 g/cm³

Woods densities:
~= 0.5 g/cm³ (floats on water)
Ebony ~= 1.2 g/cm³ (sinks in water)
http://www.engineeringtoolbox.com/wood-density-d_40.html

Various densities:
http://www.psyclops.com/tools/technotes/materials/density.html

*/