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

module controller;

public import orb.capture;
import orb.engine;
import std.math : PI;


class Controller : System,
                   IStateEvent, IKeyEvent, IMouseMotionEvent, IMouseButtonEvent,
                   IReceiver!StatEvent
{
public:
    enum float transVelMin = 0.25;  // if fps=60fps, speed=54kvoxels/h
    enum float transVelMax = 0.25;
    enum float transAcc    = 0.0;
    enum float rotVelMin   = PI / 60;
    enum float rotVelMax   = PI / 60;
    enum float rotAcc      = 0.0;

    this(InputSystem inSys)
    {
        mInputSys    = inSys;

        inSys.bind(cast(IStateEvent)this, KeyCode.ESCAPE);
        inSys.bind(cast(IStateEvent)this, KeyCode.F11);     // playback
        inSys.bind(cast(IStateEvent)this, KeyCode.F12);     // capture

        bindMovement();

        mTransVel = [0.0f, 0.0f, 0.0f];
        mRotVel   = [0.0f, 0.0f, 0.0f];

        mCapture.captureFile  = "capture.bin";
        mCapture.playbackFile = "capture.bin";
    }

    void receive(KeyCode code, MouseButton button, bool state,
                 EventManager events, Duration dt)
    {
        import orb.utils.logger;
        switch (code)
        {
        case KeyCode.ESCAPE:    // catch mouse
            mInputSys.setRelativeMouseMode(state);
            break;

        case KeyCode.F11:       // playback input
            if (mCapture.state == State.idle && !state)
            {
                info("Playback start");
                unbindMovement();
                mCapture.startPlayback();
            }
            else if (mCapture.state == State.playback && state)
            {
                info("Playback stop");
                bindMovement();
                mCapture.stopPlayback();
            }
            break;

        case KeyCode.F12:       // capture input
            if (mCapture.state == State.idle && !state)
            {
                info("Capture start");
                mCapture.startCapture();
            }
            else if (mCapture.state == State.capture && state)
            {
                info("Capture stop");
                mCapture.stopCapture();
            }
            break;

        default:
            assert(false);
        }
    }

    void receive(KeyCode code,
                 bool pressed, bool repeat,
                 EventManager events, Duration dt)
    {
        void accelerate(string transform, bool forward)(ref float vel)
        {
            enum string signStr = forward ? "" : "-";
            enum float velMin = mixin(signStr ~ transform ~ "VelMin");
            enum float velMax = mixin(signStr ~ transform ~ "VelMax");
            enum float acc    = mixin(signStr ~ transform ~ "Acc");
            bool cmpVel0   = forward ? mixin("vel <= 0")
                                     : mixin("vel >= 0");
            bool cmpVelMax = forward ? mixin("vel > velMax")
                                     : mixin("vel < velMax");

            if (pressed)
            {
                if (cmpVel0)
                    vel = velMin;
                else
                {
                    vel += acc;
                    if (cmpVelMax)
                        vel = velMax;
                }
            }
            else
            {
                if (!cmpVel0)
                    vel = 0;
            }
        }

        switch (code)
        {
        case KeyCode.W: //forward
            accelerate!("trans", true)(mTransVel.x);
            mTransUpdated = true;
            break;

        case KeyCode.S: //backward
            accelerate!("trans", false)(mTransVel.x);
            mTransUpdated = true;
            break;

        case KeyCode.A: //left
            accelerate!("trans", false)(mTransVel.y);
            mTransUpdated = true;
            break;

        case KeyCode.D: //right
            accelerate!("trans", true)(mTransVel.y);
            mTransUpdated = true;
            break;

        case KeyCode.C: //downward
            accelerate!("trans", false)(mTransVel.z);
            mTransUpdated = true;
            break;

        case KeyCode.SPACE: //upward
            accelerate!("trans", true)(mTransVel.z);
            mTransUpdated = true;
            break;

        case KeyCode.Q: //tilt left
            accelerate!("rot", true)(mRotVel.z);
            mRotUpdated = true;
            break;

        case KeyCode.E: //tilt right
            accelerate!("rot", false)(mRotVel.z);
            mRotUpdated = true;
            break;

        default:
            assert(false);
        }
    }

    void receive(MouseButton button,
                 bool pressed, int nbClicks, vec2i pos,
                 EventManager events, Duration dt)
    {
        if (pressed)
            events.emit!LaunchEvent();
    }

    void receive(vec2i pos, vec2i motion,
                 BitFlags!MouseButton buttonFlags,
                 EventManager events, Duration dt)
    {
        if (mInputSys.get(cast(IStateEvent)this))
        {
            mRotVel.x = motion.x * PI / 120;
            mRotVel.y = -motion.y * PI / 120;
            mRotUpdated = true;
        }
    }

    override void prepare(EntityManager es, EventManager events, Duration dt)
    {
        switch (mCapture.state)
        {
        case State.idle:
            // nothing to do
            break;

        case State.capture:
            mCapture.save(mTransVel, mRotVel, mTransUpdated, mRotUpdated);
            break;

        case State.playback:
            auto data = mCapture.load();
            if (data is null)
                break;
            mTransVel     = data.transVel;
            mRotVel       = data.rotVel;
            mTransUpdated = data.transVelUpdated;
            mRotUpdated   = data.rotVelUpdated;
            break;

        default:
            assert(false);
        }

        events.emit!MovementEvent(mTransVel, mRotVel,
                                  mTransUpdated, mRotUpdated);
    }

    override void unprepare(EntityManager es, EventManager events, Duration dt)
    {
        mRotVel.x = mRotVel.y = 0;
        mTransUpdated = false;
        mRotUpdated   = false;
    }

    // Display stat
    void receive(StatEvent event)
    {
        import orb.utils.logger;
        auto systems = event.systemManager;
        infof("All: %dµs (%d|%d)",
              systems.statAll.average.total!"usecs",
              systems.statAll.min.total!"usecs",
              systems.statAll.max.total!"usecs");
        foreach (sys; systems[])
            infof("    - %s: %dµs (%d|%d)",
                  sys.name,
                  sys.stat.average.total!"usecs",
                  sys.stat.min.total!"usecs",
                  sys.stat.max.total!"usecs");
    }

private:
    void bindMovement()
    {
        mInputSys.bind(cast(IKeyEvent)this,   KeyCode.W);
        mInputSys.bind(cast(IKeyEvent)this,   KeyCode.A);
        mInputSys.bind(cast(IKeyEvent)this,   KeyCode.S);
        mInputSys.bind(cast(IKeyEvent)this,   KeyCode.D);
        mInputSys.bind(cast(IKeyEvent)this,   KeyCode.Q);
        mInputSys.bind(cast(IKeyEvent)this,   KeyCode.E);
        mInputSys.bind(cast(IKeyEvent)this,   KeyCode.SPACE);
        mInputSys.bind(cast(IKeyEvent)this,   KeyCode.C);

        mInputSys.bind(cast(IMouseMotionEvent)this);
        mInputSys.bind(cast(IMouseButtonEvent)this, MouseButton.left);
    }

    void unbindMovement()
    {
        mInputSys.unbind(cast(IKeyEvent)this,   KeyCode.W);
        mInputSys.unbind(cast(IKeyEvent)this,   KeyCode.A);
        mInputSys.unbind(cast(IKeyEvent)this,   KeyCode.S);
        mInputSys.unbind(cast(IKeyEvent)this,   KeyCode.D);
        mInputSys.unbind(cast(IKeyEvent)this,   KeyCode.Q);
        mInputSys.unbind(cast(IKeyEvent)this,   KeyCode.E);
        mInputSys.unbind(cast(IKeyEvent)this,   KeyCode.SPACE);
        mInputSys.unbind(cast(IKeyEvent)this,   KeyCode.C);

        mInputSys.unbind(cast(IMouseMotionEvent)this);
        mInputSys.unbind(cast(IMouseButtonEvent)this, MouseButton.left);
    }

    InputSystem mInputSys;
    vec3f       mTransVel;
    vec3f       mRotVel;
    bool        mRotUpdated;
    bool        mTransUpdated;
    Capture     mCapture;
}
