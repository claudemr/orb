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

module orb.event;

public import orb.scene.camera;
public import entitysysd;

//todo, a bit dodgy, remove that
@event struct InputRegistrationEvent
{
    bool enabled;
}

@event struct CameraUpdatedEvent
{
    Camera camera;
}

@event struct MovementEvent
{
    Vector3f movement;
    Vector3f orientation;
    bool     movementUpdated;
    bool     orientationUpdated;
}
