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

module orb.utils.pool;

import orb.utils.ring;
import std.traits;


struct Pool(T)
{
public:
    static if (is(T == class))
        alias RefT = T;
    else
        alias RefT = T*;

    RefT alloc(Args...)(Args args)
    {
        if (mFreeList.length == 0)
        {
            mData.length++;
            mFreeList.reserve(mData.length);
            mData[$ - 1] = new T(args);
            return mData[$ - 1];
        }
        else
        {
            T t = mFreeList.front;
            mFreeList.removeFront();
            static if (is(typeof(t.__ctor(args))))
            {
                t.__ctor(args);
            }
            else
            {
                static assert(args.length == 0 && !is(typeof(&T.__ctor)),
                              "Don't know how to initialize an object of type "
                              ~ T.stringof ~ " with arguments "
                              ~ Args.stringof);
            }
            return t;
        }
    }

    void free(RefT t)
    {
        static if (is(typeof(t.__dtor())))
        {
            t.__dtor();
        }

        mFreeList.insertBack(t);
    }

private:
    T[]       mData; //todo use Appender?
    Ring!RefT mFreeList;
}


version(unittest)
{
    class Test
    {
        this(byte bb)
        {
            b = bb;
            next = prev = this;
        }

        ~this()
        {
            b = 0x7F;
            next = prev = null;
        }

        byte b;
        Test next;
        Test prev;
        short s;
        string str;

        int result()
        {
            return cast(int)b;
        }
    }
}

unittest
{
    Pool!Test pool;

    auto a = pool.alloc(cast(byte)0xf);
    assert(a.b == 0xf && a.prev == a && a.next == a);
    pool.free(a);
    assert(a.b == 0x7f && a.prev is null && a.next is null);

    auto b = pool.alloc(cast(byte)5);
    assert(b.b == 5 && b.prev == b && a.next == b);

    auto c = pool.alloc(cast(byte)2);
    c.next = pool.alloc(cast(byte)3);
    c.prev = pool.alloc(cast(byte)4);
    pool.free(c.next);
    auto d = pool.alloc(cast(byte)5);
    assert(c.prev.result == 4);
    assert(c.result == 2);
    assert(d.result == 5);
    assert(b.next.prev.result == 5);
}