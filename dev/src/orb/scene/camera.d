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

module orb.scene.camera;

public import gfm.math.matrix;
public import gfm.math.vector;

import gfm.math.quaternion;


private quatf quaternionFromAxis(vec3f f, vec3f r, vec3f u)
pure @safe
{
    import std.math : sqrt;
    quatf q;

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
        mPosition = [0.0f, 0.0f, 0.0f];
        mFront = [0.0f, 0.0f, -1.0f];
        mRight = [1.0f, 0.0f, 0.0f];
        mUp    = [0.0f, 1.0f, 0.0f];
        mFov   = 45.0;
        mRatio = 4.0 / 3.0;
        mNear  = 0.1;
        mFar   = 100.0;
        mQOrientation   = quatf.identity();
        mMatrixViewDone = mMatrixProjDone = mMatrixViewProjDone = false;
    }

    Camera dup() @property
    {
        import std.traits : FieldNameTuple;
        auto cam = new Camera;
        /*static*/ foreach (name; FieldNameTuple!Camera)
            mixin("cam."~name~" = "~name~";");
        return cam;
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
        mQOrientation = mQOrientation *
                        quatf.fromAxis(mUp, yaw) *
                        quatf.fromAxis(mRight, pitch) *
                        quatf.fromAxis(mFront, roll);

        mQOrientation.normalize();

        // Transform quaternion to matrix and get orientation vectors
        mMatrixView = cast(mat4f)mQOrientation;

        // Get right, up and front vector of the transposed matrix
/*        mRight =  vec3f(mMatrixView.a11, mMatrixView.a12, mMatrixView.a13);
        mUp    =  vec3f(mMatrixView.a21, mMatrixView.a22, mMatrixView.a23);
        mFront = -vec3f(mMatrixView.a31, mMatrixView.a32, mMatrixView.a33);*/

        mRight =  vec3f(mMatrixView.rows[0].v[0..3]);
        mUp    =  vec3f(mMatrixView.rows[1].v[0..3]);
        mFront = -vec3f(mMatrixView.rows[2].v[0..3]);

        mMatrixView.c[0][3] = -dot(mRight, mPosition);
        mMatrixView.c[1][3] = -dot(mUp,    mPosition);
        mMatrixView.c[2][3] =  dot(mFront, mPosition);

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
            mPosition.x += forward * mFront.x;
            mPosition.y += forward * mFront.y;
            mPosition.z += forward * mFront.z;
        }
        if (rstrafe != 0.0f)
        {
            mPosition.x += rstrafe * mRight.x;
            mPosition.y += rstrafe * mRight.y;
            mPosition.z += rstrafe * mRight.z;
        }
        if (up != 0.0f)
        {
            mPosition.x += up * mUp.x;
            mPosition.y += up * mUp.y;
            mPosition.z += up * mUp.z;
        }

        vec3f x, y;

        x = -mRight;
        y = -mUp;

        mMatrixView.c[0][3] = dot(mPosition, x);
        mMatrixView.c[1][3] = dot(mPosition, y);
        mMatrixView.c[2][3] = dot(mPosition, mFront);

        mMatrixViewDone     = true;
        mMatrixViewProjDone = false;
    }

    /**
     * From current position, orientate the camera towards a certain target
     * position
     */
    void lookAt(vec3f targetPoint)
    {
        import orb.utils.geometry : isAlmostZero;
        mMatrixView = mat4f.identity;

        if (isAlmostZero(mUp) && isAlmostZero(mRight))
            mUp = vec3f(0.0f, 1.0f, 0.0f);

        vec3f f, u, s;
        f = (targetPoint - mPosition).normalized;

        if (isAlmostZero(mRight))
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

    /**
     * Tells whether a point is within the camera view cone.
     */
    bool isVisible(vec3f p)
    {
        import std.math : cos, sin;
        vec3f posView = p - mPosition;
        // Is it behind/beyond the camera? (near/far check)
        float d = dot(posView, mFront);
        if (d < mNear || d > mFar)
            return false;

        vec3f f = -mFront * sin(mFov);
        vec3f s = mRight * cos(mFov) * mRatio / 2;
        vec3f u = mUp    * cos(mFov) / mRatio / 2;

        if (dot(posView, f + s) > 0)
            return false;
        if (dot(posView, f - s) > 0)
            return false;
        if (dot(posView, f + u) > 0)
            return false;
        if (dot(posView, f - u) > 0)
            return false;

        return true;
    }

    //*** Getter methods

    mat4f matrixView() @property
    {
        if (!mMatrixViewDone)
        {
            buildMatrixView();
            mMatrixViewDone = true;
        }
        return mMatrixView;
    }

    mat4f matrixProj() @property
    {
        if (!mMatrixProjDone)
        {
            import std.math : PI;
            mMatrixProj = mat4f.perspective(mFov * PI / 180, mRatio,
                                            mNear, mFar);
            mMatrixProjDone = true;
        }
        return mMatrixProj;
    }

    mat4f matrixViewProj() @property
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

    //*** Setter/getter methods
    void opDispatch(string name, T)(auto ref T param)
    {
        import std.ascii : toUpper;
        enum string fieldName = "m" ~ name[0].toUpper ~ name[1..$];
        mixin(fieldName) = param;
        import std.algorithm.searching : canFind;
        static if (canFind(["fov", "ratio", "near", "far"], name))
            mMatrixProjDone = false;
        else
            mMatrixViewDone = false;
        mMatrixViewProjDone = false;
    }

    auto opDispatch(string name)()
    {
        import std.ascii : toUpper;
        enum string fieldName = "m" ~ name[0].toUpper ~ name[1..$];
        return mixin(fieldName);
    }

private:
    void buildMatrixView() pure @safe
    {
        mMatrixView.c[0][0] =  mRight.x;
        mMatrixView.c[0][1] =  mRight.y;
        mMatrixView.c[0][2] =  mRight.z;
        mMatrixView.c[1][0] =  mUp.x;
        mMatrixView.c[1][1] =  mUp.y;
        mMatrixView.c[1][2] =  mUp.z;
        mMatrixView.c[2][0] = -mFront.x;
        mMatrixView.c[2][1] = -mFront.y;
        mMatrixView.c[2][2] = -mFront.z;
        mMatrixView.c[0][3] = -dot(mRight, mPosition);
        mMatrixView.c[1][3] = -dot(mUp,    mPosition);
        mMatrixView.c[2][3] =  dot(mFront, mPosition);

        mMatrixViewDone     = true;
        mMatrixViewProjDone = false;
    }

    vec3f mPosition, mFront, mRight, mUp;
    float mFov, mRatio, mNear, mFar;
    mat4f mMatrixViewProj, mMatrixView, mMatrixProj;
    quatf mQOrientation;
    bool  mMatrixViewDone, mMatrixProjDone, mMatrixViewProjDone;
}
