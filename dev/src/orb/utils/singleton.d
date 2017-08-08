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

module orb.utils.singleton;

/**
 * Mixin template for singleton. NOT thread-safe.
 *
 * Example:
 *     class MySingleton
 *     {
 *         mixin Singleton;
 *     }
 */

mixin template Singleton()
{
private:
    this()
    in
    {
        assert(mSingletonInstance is null);
    }
    body
    {
        // Put your initialisation stuff in initSingleton.
        static if (is(typeof(this.initSingleton)))
            this.initSingleton();
    }

    ~this()
    in
    {
        assert(mSingletonInstance !is null);
    }
    body
    {
        // Put your initialisation stuff in initSingleton.
        static if (is(typeof(this.shutdownSingleton)))
            this.shutdownSingleton();
    }

    __gshared typeof(this)  mSingletonInstance;

public:
    static typeof(this) singleton() @property
    {
        if (mSingletonInstance is null)
            mSingletonInstance = new typeof(this);

        return mSingletonInstance;
    }
}
