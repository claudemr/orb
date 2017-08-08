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

module orb.physics.collisionsystem;

public import orb.scene.scene;
import gfm.math.vector;
import orb.component;


final class CollisionSystem : System
{
public:
    void scene(Scene s) @property
    {
        mScene = s;
    }

protected:
    override void run(EntityManager es, EventManager events, Duration dt)
    {
        auto radius = mScene.terrain.radius;
        auto center = mScene.terrain.center;

        foreach (ett, p, v, c; es.entitiesWith!(Position, Velocity, Collidable))
        {
            // if the entity has not moved, next...
            if (!v.moving)
                goto savePosition;

            // Degenerate case
            if (p.pos == center)
                goto savePosition; //todo print error log

            // If we detect a collision
            auto l1 = (p.pos - center).length;
            if (l1 < radius)
            {
                import std.math : sqrt;
                auto n = (p.pos - c.prevPos).normalized;
                auto t = dot(n, center - c.prevPos);
                // closest point to center on line of movement between positions
                auto e = t * n + c.prevPos;
                auto dt = sqrt(radius ^^ 2 - (e - center).squaredLength);
                // point on the sphere, nearest to prevPos
                p.pos = (t - dt) * n + c.prevPos;
                // second point on shere would be "(t + dt) * n + c.prevPos"
            }

        savePosition:
            c.prevPos = p.pos;
        }
    }

private:
    Scene mScene;
}
