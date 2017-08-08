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

module orb.physics.physicssystem;

public import orb.scene.scene;
import gfm.math.vector;
import orb.component;


enum float zeroVelocity = 1e-2;


private float getVolume(Entity e)
{
    if (e.isRegistered!Mass)
        //todo we assume it has same density as wood: 700kg/m³
        return e.component!Mass.mass / 700;

    return 0;
}

private float getResistanceArea(Entity e)
{
    //todo: naive way of getting resistance area from volume, assuming the
    //      entity is a ball
    import std.math : PI, pow;
    float v = getVolume(e);
    float radius3 = v * 3 / (4 * PI);
    // calculate disk area
    return PI * pow(radius3, 2.0f / 3);
}

final class PhysicsSystem : System
{
public:
    void scene(Scene s) @property
    {
        mScene = s;
    }

protected:
    override void run(EntityManager es, EventManager events, Duration dt)
    {
        auto airResistance = mScene.terrain.airResistance;
        auto gravity       = mScene.terrain.gravity;
        auto center        = mScene.terrain.center;
        vec3f acc;

        foreach (ett, p, v, m; es.entitiesWith!(Position, Velocity, Mass))
        {
            // if the entity is not moving, next...
            if (!v.moving)
                continue;

            // Calculate weight
            vec3f weight;
            if (p.pos != center)
                weight = m.mass * gravity * (center - p.pos).normalized;
            else
                weight = vec3f(0, 0, 0);

            // Calculate drag
            float resistance = v.velocity.squaredLength *
                               airResistance * getResistanceArea(ett);
            vec3f drag = -v.velocity.normalized * resistance;

            // Calculate acceleration
            vec3f acc;
            if (m.mass != 0)
                acc = (weight + drag) / m.mass;
            else
                acc = vec3f(0, 0, 0);

            // Update velocity
            v.velocity += acc * dt.total!"usecs" / 1000000;
            if (isAlmostZero!zeroVelocity(v.velocity))
            {
                v.velocity = vec3f(0, 0, 0);
                v.moving = false;
                continue;
            }

            p.pos += v.velocity * dt.total!"usecs" / 1000000;
        }
    }

private:
    Scene mScene;
}

