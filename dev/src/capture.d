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

module orb.capture;

public import gfm.math.vector;
import std.file;


enum State
{
    idle,
    capture,
    playback
}

struct Datum
{
    vec3f transVel;
    vec3f rotVel;
    bool  transVelUpdated;
    bool  rotVelUpdated;
}


struct Capture
{
public:
    void captureFile(string filename) @property
    {
        mCaptureFilename = filename.idup;
    }

    void playbackFile(string filename) @property
    {
        mPlaybackFilename = filename.idup;
    }

    State state() @property
    {
        return mState;
    }

    void startCapture()
    {
        assert(mState == State.idle);
        mState = State.capture;
    }

    void stopCapture()
    {
        assert(mState == State.capture);
        assert(mCaptureFilename !is null);
        write(mCaptureFilename, mData);
        mData.length = 0;
        mState = State.idle;
    }

    void save(vec3f transVel,
              vec3f rotVel,
              bool transVelUpdated,
              bool rotVelUpdated)
    {
        mData ~= Datum(transVel, rotVel, transVelUpdated, rotVelUpdated);
    }

    void startPlayback()
    {
        assert(mState == State.idle);
        assert(mPlaybackFilename !is null);
        mData  = cast(Datum[])read(mPlaybackFilename);
        mState = State.playback;
        mPlaybackIdx = 0;
    }

    void stopPlayback()
    {
        assert(mState == State.playback);
        mData.length = 0;
        mState = State.idle;
    }

    const(Datum)* load()
    {
        if (mData.length <= mPlaybackIdx)
            return null;
        mPlaybackIdx++;
        return &mData[mPlaybackIdx - 1];
    }

private:
    State  mState;
    string mCaptureFilename, mPlaybackFilename;
    Datum[] mData;
    size_t mPlaybackIdx;
}
