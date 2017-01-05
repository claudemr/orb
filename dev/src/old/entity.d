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

module orb.entity;
/+
import std.math;

import dlib.math.affine;
import dlib.math.quaternion;
import dlib.math.vector;

import orb.world;

enum Direction : uint
{
    f = 0x1,    /// Forward
    b = 0x2,    /// Backward
    l = 0x4,    /// Left
    r = 0x8,    /// Right
    fl = 0x5,   /// Forward-left
    fr = 0x9,   /// Forward-right
    bl = 0x6,   /// Back-left
    br = 0xa    /// Back-right
}


class Entity
{
private:
    //*** inherent data
    World mWorld;       // World to which the entity belongs
    float mMass;        // In kg, used for momentum, energy calculations
    float mArea;        // In m², used with momentum resistance, we assume the
                        // area is the same in any direction (which is not true,
                        // ie. parachute) to make computation quicker.
                        // todo: Use a 3D vector
    float mBouncyness;  // The harder (less bouncy) a material is, the less
                        // momentum it will return to another entity upon impact
    float mSoftness;    // The softer a material is, the more momentum it will
                        // absorb from another entity upon impact [0, 1]

    //*** time-frame related data

    // Moment = OP x F

    // Impulse is the difference of momentum of an entity between t1 and t2.
    // Impulse is the force applied to an object multiplied by the duration that
    // is applied to it.
    // I = sum(F) * t

    // Momentum is velocity multiplied with mass. M = v * m

    // The Drag D is the resistance by surrounding atmosphere around the moving
    // object:
    // D = Cd * 0.5 * AirDensity * Velocity^2 * Area
    // HalfCd is a drag coefficient divided by 2
    // https://www.grc.nasa.gov/www/k-12/airplane/falling.html
    // And we could use the volume of the object instead of the area (easier
    // calculation). So we would have
    // Resistance = Cd * 0.5 * AirDensity
    // Area = Volume^(2.0/3) (or calculated based on some more complex properties
    // to add realism.
    // Therefore:
    // D = Resistance * V^2 * getAreaFromVolume(Volume, OtherObjectParam)

    // Every time-frame, the momentum will be incremented with the sum of the
    // forces applied to the entity
    // The energy will be calculated from there E = m * v^2 / 2

    // For every time-frame, for every object:
    // * The sum of the applied forces is calculated, and the point of reduction
    //   were they are applied.
    // * Calculate the moment of the force. Get the Torsor {F, M}.
    // * Adjust this force with the resistance: F -= F * Resistance / F.length()
    // * Multiply the Torsor with the frame delay to get the Impulse.
    //   And add this impulse to the current momentum of the object (directional
    //   and rotational).
    // * Calculate Velocity (dir and rot) by dividing Momentum with mass.
    // * Calculate Energy by multiplying magnitude of Momentum with speed and
    //   divided by 2.
    // * Calculate new position of the object and its "trail" to check collision
    // * Calculate collision with any other object, transfer force to them.

    // For a 25cm-thick object, with a rendering rate of 60fps, in order to
    // make sure collision is detected (so that object does not "teleport" every
    // frame), the speed must be limited to 25cm/16ms so 15m/s or 54km/h.

    Vector3f        mPos, mFront, mRight, mUp;
    Vector3f        mDirVelocity;
    Quaternionf     mRotVelocity;
    Vector3f        mDirMomentum;
    Quaternionf     mRotMomentum;
    Vector3f        mDirForce;
    Quaternionf     mRotForce;

    float           mEnergy;
    bool            mMoving;
    bool            mBalanced;      // Uses a certain force to balance
                                    // itself up according to gravity force

    Vector3f[12]    mVertices;
    Vector3f[12]    mNormals;

    Vector3f directionVector(Direction direction)
    {
        Vector3f v;
        switch (direction) with (Direction)
        {
        case f:
            v = mFront;
            break;
        case fl:
            v = mFront - mRight;
            break;
        case fr:
            v = mFront + mRight;
            break;
        case b:
            v = -mFront;
            break;
        case bl:
            v = -mFront - mRight;
            break;
        case br:
            v = -mFront + mRight;
            break;
        default:
            assert(false, "Wrong direction");
        }

        v.normalize();
        return v;
    }

public:
    this(World world)
    {
        mWorld = world;

        string vtxCoord(int a)
        {
            switch (a)
            {
            case 0:
                return "vectorf(0.0, 0.5, 0.5)";
            case 1:
                return "vectorf(-0.5, -0.5, 0.5)";
            case 2:
                return "vectorf(0.0, -0.5, -0.5)";
            case 3:
                return "vectorf(0.5, -0.5, 0.5)";
            default:
                return "";
            }
        }

        string nrmCoord(int a)
        {
            switch (a)
            {
            case 0: // 0 1 3
                return "vectorf(0.0, -1.0, 0.0)";
            case 1: // 1 2 3
                return "vectorf(0.0, 0.0, 1.0)";
            case 2: // 0 3 2
                return "vectorf(sqrt(6.0)/6, sqrt(6.0)/3, -sqrt(6.0)/6)";
            case 3: // 0 2 1
                return "vectorf(-sqrt(6.0)/6, sqrt(6.0)/3, -sqrt(6.0)/6)";
            default:
                return "";
            }
        }

        //todo temp
        mVertices = [
                        mixin (vtxCoord(0)),
                        mixin (vtxCoord(1)),
                        mixin (vtxCoord(3)),

                        mixin (vtxCoord(1)),
                        mixin (vtxCoord(2)),
                        mixin (vtxCoord(3)),

                        mixin (vtxCoord(0)),
                        mixin (vtxCoord(3)),
                        mixin (vtxCoord(2)),

                        mixin (vtxCoord(0)),
                        mixin (vtxCoord(2)),
                        mixin (vtxCoord(1))
                    ];

        mNormals = [
                        mixin (nrmCoord(0)),
                        mixin (nrmCoord(0)),
                        mixin (nrmCoord(0)),

                        mixin (nrmCoord(1)),
                        mixin (nrmCoord(1)),
                        mixin (nrmCoord(1)),

                        mixin (nrmCoord(2)),
                        mixin (nrmCoord(2)),
                        mixin (nrmCoord(2)),

                        mixin (nrmCoord(3)),
                        mixin (nrmCoord(3)),
                        mixin (nrmCoord(3))
                    ];

    }

    /**
     * Move an entity with a direct position/orientation input.
     */
    void move(Vector3f position,
              Vector3f front,
              Vector3f right,
              Vector3f up)
    {
        mPos   = position;
        mFront = front;
        mRight = right;
        mUp    = up;
        mDirVelocity = vectorf(0, 0, 0);
        mRotVelocity = Quaternionf.identity();
        mDirMomentum = vectorf(0, 0, 0);
        mRotMomentum = Quaternionf.identity();
        mEnergy = 0;
        mMoving = false;
    }

    /**
     * Make an entity walk in a certain direction amongst 8: forward, backward,
     * left, right and intermediate (i.e. back-left).
     */
    void walk(Direction direction)
    {
        enum float walkStrength = 1;
        auto walkStrengthDir = directionVector(direction);
        walkStrengthDir *= walkStrength;
        mMoving = true;
    }

    /**
     * Make an entity run in a certain direction amongst 8: forward, backward,
     * left, right and intermediate (i.e. back-left).
     */
    void run(Direction direction)
    {
        // use a run speed
    }

    /**
     * Make an entity jump.
     */
    void jump()
    {
        // use a jump force
    }

    @property
    auto vertices()
    {
        return mVertices.ptr;
    }

    @property
    auto normals()
    {
        return mNormals.ptr;
    }

    @property
    auto modelMatrix()
    {
        return translationMatrix(mPos) * orthoNormalMatrix(mRight, mUp, mFront);
    }

    /*
    Move an entity upon impact
    void move(in ref Vector3f force, in ref Vector3f impactPoint)
    {
        auto period = Engine.singleton.physicsPeriod;
        Vector3f impulse;

        impulse = force;
        impulse.mul(period);

        mDirMomentum += impulse;
    }*/
}
+/