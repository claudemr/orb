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

module orb.scene.camera;

public import dlib.math.matrix;
public import dlib.math.vector;

import dlib.math.affine;
import dlib.math.quaternion;

//todo: Remove matrices from the class, it should be built everytime its is
//      requested and be saved by the user.

private Quaternionf quaternionFromAxis(Vector3f f, Vector3f r, Vector3f u)
pure @safe
{
    import std.math : sqrt;
    Quaternionf q;

    float  trace = r.x + u.y - f.z + 1.0;

    if (trace > 0.0001)
    {
        float s = 0.5 / sqrt(trace);
        q.w = 0.25 / s;
        q.x = (-f.y - u.z) * s;
        q.y = (r.z + f.x) * s;
        q.z = (u.x - r.y) * s;
    }
    else
    {
        if ((r.x > u.y) && (r.x > -f.z))
        {
            float s = 0.5 / sqrt(1.0 + r.x - u.y + f.z);
            q.x = 0.25 / s;
            q.y = (r.y + u.x) * s;
            q.z = (r.z - f.x) * s;
            q.w = (u.z + f.y) * s;
        }
        else if (u.y > -f.z)
        {
            float s = 0.5 / sqrt(1.0 + u.y - r.x + f.z);
            q.x = (r.y + u.x) * s;
            q.y = 0.25 / s;
            q.z = (u.z - f.y) * s;
            q.w = (r.z + f.x) * s;
        }
        else
        {
            float s = 0.5 / sqrt(1.0 - f.z - r.x - u.y);
            q.x = (r.z - f.x) * s;
            q.y = (u.z - f.y) * s;
            q.z = 0.25 / s;
            q.w = (r.y - u.x) * s;
        }
    }

    return q;
}

class Camera
{
public:
pure @safe:
    //*** Constructors

    this()
    {
        mPos   = [0.0f, 0.0f, 0.0f];
        mFront = [0.0f, 0.0f, -1.0f];
        mRight = [1.0f, 0.0f, 0.0f];
        mUp    = [0.0f, 1.0f, 0.0f];
        mFov   = 45.0;
        mRatio = 4.0 / 3.0;
        mNear  = 0.1;
        mFar   = 100.0;
        mQOrientation   = Quaternionf.identity();
        mMatrixViewDone = mMatrixProjDone = mMatrixViewProjDone = false;
    }

    /**
     * Orientate from current orientation (relative).
     *
     * yaw   Look left/right
     * pitch Look up/down
     * roll  Roll left/right
     */
    void orientate(float yaw, float pitch, float roll)
    {
        mQOrientation = mQOrientation * rotationQuaternion(mUp, yaw) *
                        rotationQuaternion(mRight, pitch) *
                        rotationQuaternion(mFront, roll);

        mQOrientation.normalize();

        // Transform quaternion to matrix and get orientation vectors
        mMatrixView = mQOrientation.toMatrix4x4();

        // Get right, up and front vector of the transposed matrix
        mRight = vectorf(mMatrixView.a11, mMatrixView.a12, mMatrixView.a13);
        mUp    = vectorf(mMatrixView.a21, mMatrixView.a22, mMatrixView.a23);
        mFront = -vectorf(mMatrixView.a31, mMatrixView.a32, mMatrixView.a33);

        mMatrixView[0,3] = -dot(mRight, mPos);
        mMatrixView[1,3] = -dot(mUp,    mPos);
        mMatrixView[2,3] =  dot(mFront, mPos);

        mMatrixViewDone     = true;
        mMatrixViewProjDone = false;
    }

    /**
     * rotX Look up/down
     * rotY Look left/right
     * rotZ Roll left/right
     */
    void move(float forward, float rstrafe, float up)
    {
        if (forward != 0.0f)
        {
            mPos.x += forward * mFront.x;
            mPos.y += forward * mFront.y;
            mPos.z += forward * mFront.z;
        }
        if (rstrafe != 0.0f)
        {
            mPos.x += rstrafe * mRight.x;
            mPos.y += rstrafe * mRight.y;
            mPos.z += rstrafe * mRight.z;
        }
        if (up != 0.0f)
        {
            mPos.x += up * mUp.x;
            mPos.y += up * mUp.y;
            mPos.z += up * mUp.z;
        }

        Vector3f x, y;

        x = -mRight;
        y = -mUp;

        mMatrixView.a14 = dot(mPos, x);
        mMatrixView.a24 = dot(mPos, y);
        mMatrixView.a34 = dot(mPos, mFront);

        mMatrixViewDone     = true;
        mMatrixViewProjDone = false;
    }

    /**
     * From current position, orientate the camera towards a certain target
     * position
     */
    void lookAt(Vector3f targetPoint)
    {
        //todo dlib.math.vector.isAlmostZero should be @safe pure
        import orb.utils.traits;
        enum attrs = FunctionAttribute.trusted |
                     FunctionAttribute.pure_;
        auto isAlmostZero_ = assumeAttr!attrs(&isAlmostZero);

        mMatrixView = Matrix4f.identity;

        if (isAlmostZero_(mUp) && isAlmostZero_(mRight))
            mUp = vectorf(0.0f, 1.0f, 0.0f);

        Vector3f f, u, s;
        f = (targetPoint - mPos).normalized;

        if (isAlmostZero_(mRight))
        {
            u = mUp.normalized;
            s = cross(f, u).normalized;
            u = cross(s, f);
        }
        else
        {
            s = mRight.normalized;
            u = cross(s, f).normalized;
            s = cross(f, u);
        }

        mFront = f;
        mUp    = u;
        mRight = s;

        mQOrientation = quaternionFromAxis(f, s, u);

        buildMatrixView();
    }

    //*** Getter methods

    Matrix4f matrixView() @property
    {
        if (!mMatrixViewDone)
        {
            buildMatrixView();
            mMatrixViewDone = true;
        }
        return mMatrixView;
    }

    Matrix4f matrixProj() @property
    {
        if (!mMatrixProjDone)
        {
            mMatrixProj = perspectiveMatrix(mFov, mRatio, mNear, mFar);
            mMatrixProjDone = true;
        }
        return mMatrixProj;
    }

    Matrix4f matrixViewProj() @property
    {
        if (!mMatrixViewProjDone)
        {
            matrixView();
            matrixProj();
            mMatrixViewProj = mMatrixProj * mMatrixView;
            mMatrixViewProjDone = true;
        }
        return mMatrixViewProj;
    }

    //*** Setter methods

    mixin template opAssign(alias field, alias boolDone)
    {
        void opAssign(T)(auto in ref T param) @property
        {
            field = param;
            boolDone = false;
            mMatrixViewProjDone = false;
        }

        //xxx do better, can we get rid of the "()"?
        auto opCall() @property
        {
            return field;
        }
    }

    mixin opAssign!(mPos,   mMatrixViewDone) position;
    mixin opAssign!(mFront, mMatrixViewDone) front;
    mixin opAssign!(mRight, mMatrixViewDone) right;
    mixin opAssign!(mUp,    mMatrixViewDone) up;
    mixin opAssign!(mFov,   mMatrixProjDone) fov;
    mixin opAssign!(mRatio, mMatrixProjDone) ratio;
    mixin opAssign!(mNear,  mMatrixProjDone) near;
    mixin opAssign!(mFar,   mMatrixProjDone) far;


private:
    void buildMatrixView() pure @safe
    {
        mMatrixView[0,0] =  mRight.x;
        mMatrixView[0,1] =  mRight.y;
        mMatrixView[0,2] =  mRight.z;
        mMatrixView[1,0] =  mUp.x;
        mMatrixView[1,1] =  mUp.y;
        mMatrixView[1,2] =  mUp.z;
        mMatrixView[2,0] = -mFront.x;
        mMatrixView[2,1] = -mFront.y;
        mMatrixView[2,2] = -mFront.z;
        mMatrixView[0,3] = -dot(mRight, mPos);
        mMatrixView[1,3] = -dot(mUp,    mPos);
        mMatrixView[2,3] =  dot(mFront, mPos);

        mMatrixViewDone     = true;
        mMatrixViewProjDone = false;
    }

    Vector3f mPos, mFront, mRight, mUp;
    float    mFov, mRatio, mNear, mFar;
    Matrix4f mMatrixViewProj, mMatrixView, mMatrixProj;
    Quaternionf mQOrientation;
    bool     mMatrixViewDone, mMatrixProjDone, mMatrixViewProjDone;
}
