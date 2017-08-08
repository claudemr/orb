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

module player;

public import orb.scene.camera;
import orb.engine;


class Player : System, IReceiver!MovementEvent, IReceiver!LaunchEvent
{
public:
    this(Camera camera, EventManager events)
    {
        mCamera = camera;
        mEvents = events;
    }

    void receive(MovementEvent event)
    {
        auto cam    = mCamera;
        auto oldCam = cam.dup;
        auto move   = event.movement;
        auto orient = event.orientation;
        cam.orientate(orient.x, orient.y, orient.z);
        cam.move(move.x, move.y, move.z);
        if (cam.position != oldCam.position)
            mEvents.emit!CameraUpdatedEvent(oldCam, cam);
    }

    void receive(LaunchEvent event)
    {
        mEvents.emit!SpawnEvent(mCamera.position, mCamera.front * 5.0);
    }

private:
    Camera       mCamera;
    EventManager mEvents;
}
