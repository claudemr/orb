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

module boundingbox;

import dlib.math.vector;

enum Shape
{
    SPHERE,
    CYLINDER,
    CUBOID
};

struct Sphere
{
    Shape       shape;
    Vector3f    center;
    float       radius;
};

struct Cylinder
{
    Shape       shape;
    Vector3f    center;
    float       radius;
    Vector3f    axis;       // Normalized
    float       halfHeight;
};

struct Cuboid
{
    Shape       shape;
    Vector3f    center;
    Vector3f    front;      // Normalized
    Vector3f    rside;      // Normalized
    Vector3f    down;       // Normalized
    float       frontAltitude;
    float       rsideAltitude;
    float       downAltitude;
};

union BoundingBox
{
    Shape       shape;
    Sphere      sphere;
    Cylinder    cylinder;
    Cuboid      cuboid;
}

/+
/**
 * Return
 */
Vector3f getContactPoint(BoundingBox bb0, BoundingBox bb1,
                         Vector3f[] vertices, Vector3f[] normals,
                         int[3][] triangleIds)
{

}
+/

/*
Functions:

Detect collision between:
* a moving bounding-box and a static mesh (world, set of static triangles)
* a moving bounding-box and a static bounding-box
* 2 moving bounding-boxes
*/

/*
For a moving bounding-box, we could use an approximation of the path it takes
using a sphere containing the box (if it's a cuboid or a cylinder) at the start
point and the destination and a cylinder along the path.
If it detects a collision between those, it calculates the intermediate state of
the bounding box (translation and rotation using an interpolation value from the
fastest moving object). If it was a cuboid or a cylinder it
checks it is still colliding (if not, then we assume the collision did not
occur).
Then, it calculates the new momentum/velocities/energy etc and position of the
colliding objects.

*/





/* AABB box against point
{
    if (aabb.center.x - aabb.radius > point.x ||
        aabb.center.x + aabb.radius < point.x ||
        aabb.center.y - aabb.radius > point.y ||
        aabb.center.y + aabb.radius < point.y ||
        aabb.center.z - aabb.radius > point.z ||
        aabb.center.z + aabb.radius < point.z)
        return false;

    return true;
}*/

/* sphere vs point P
{
    vectorCenter2Point = point - sph.center;

    float distance = vectorCenter2Point.length2();

    // outside cylinder ?
    if (distance > sph.radius * sph.radius)
        return false;

    return true;
}*/

/* cylinder vs point P
{
    vectorCenter2Point = point - cyl.center;

    float distance = vectorProduct(vectorCenter2Point, cyl.axis).length2();

    // outside cylinder ?
    if (distance > cyl.radius * cyl.radius)
        return false;

    // maybe inside, but check the height
    distance = abs(dotProduct(vectorCenter2Point, cyl.axis));
    if (distance > cyl.halfHeight)
        return false;

    return true;
}*/

/* cuboid vs point P
{
    vectorCenter2Point = point - cub.center;

    for each axis(n)
    {
        float distance = abs(dotProduct(vectorCenter2Point, cub.axis[n]));

        // outside cylinder ?
        if (distance > cub.altitude[n])
            return false;
    }
    return true;
}*/
