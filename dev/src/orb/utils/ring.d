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

module orb.utils.ring;

import std.traits;


private struct RangeT(A)
{
public:
    alias E = typeof(mRing.mData[0]);

    RangeT!A save() @property
    {
        return this;
    }

    bool empty() @property @safe pure nothrow const
    {
        return mNb == 0;
    }

    size_t length() @property @safe pure nothrow const
    {
        return mNb;
    }

    alias opDollar = length;

    ref E front() @property
    in
    {
        assert (mNb != 0);
    }
    body
    {
        return this[0];
    }

    ref E back() @property
    in
    {
        assert (mNb != 0);
    }
    body
    {
        return this[mNb - 1];
    }

    void popFront() @safe pure nothrow
    in
    {
        assert (mNb != 0);
    }
    body
    {
        mBeg++;
        if (mBeg == mRing.mData.length)
            mBeg = 0;
        mNb--;
    }

    void popBack() @safe pure nothrow
    in
    {
        assert (mNb != 0);
    }
    body
    {
        if (mEnd == 0)
            mEnd = cast(uint)mRing.mData.length - 1;
        else
            mEnd--;
        mNb--;
    }

    ref E opIndex(size_t i)
    in
    {
        assert(mNb != 0 && i < mNb);
    }
    body
    {
        uint j = cast(uint)i + mBeg;
        if (j >= mRing.mData.length)
            j -= mRing.mData.length;
        return mRing.mData[j];
    }

    RangeT!A opSlice()
    {
        return RangeT!A(*mRing, 0, mNb);
    }

    RangeT!A opSlice(size_t i, size_t j)
    in
    {
        assert (i < j && j <= mNb);
    }
    body
    {
        return RangeT!A(*mRing, cast(uint)i, cast(uint)j);
    }

private:
    this(ref A ring, uint i, uint j)
    {
        mRing = &ring;
        mBeg = ring.mBeg + i;
        if (mBeg >= ring.mData.length)
            mBeg -= ring.mData.length;
        mEnd = mBeg + j - 1;
        if (mEnd >= ring.mData.length)
            mEnd -= ring.mData.length;
        mNb = j - i;
    }

    A* mRing;
    uint mBeg;
    uint mEnd;
    uint mNb;
}

/**
 * Ring Buffer. It implements the random-access range and output range
 * concepts.
 *
 * The memory layout does not guaranty to have contiguous data access, but
 * unlike linked-list, it uses an array as the base container, so data is stored
 * in a cache oblivious manner.
 *
 * It guaranties to keep the order of the elements in the array.
 */
struct Ring(T)
{
public:

    this(U)(U[] values...)
        if (isImplicitlyConvertible!(U, T))
    {
        mData.reserve(values.length);
        insert(values);
    }

    bool empty() @property const
    {
        return mNb == 0;
    }

    size_t length() @property const
    {
        return mNb;
    }

    size_t capacity() @property const
    {
        return mData.length == 0 ? 0 : mData.length - 1;
    }

    void reserve(size_t n)
    {
        if (n == 0)
            return;
        else if (mData.length == 0)
            mBeg = 1;
        else if (n <= mData.length - 1)
            return;

        mData.reserve(n + 1);          // +1 so end and beg do not overlap
        mData.length = mData.capacity;

        accomodate();
    }

    void clear()
    {
        mEnd = mNb = 0;
        mBeg = 1;
    }

    Ring!T dup() @property
    {
        Ring!T r;
        r.mData = mData.dup;
        r.mNb = mNb;
        r.mBeg = r.mBeg;
        r.mEnd = r.mEnd;
        return r;
    }

    ref T front() @property
    in
    {
        assert (mNb != 0);
    }
    body
    {
        return mData[mBeg];
    }

    void removeFront()
    in
    {
        assert (mNb != 0);
    }
    body
    {
        mBeg++;
        if (mBeg == mData.length)
            mBeg = 0;
        mNb--;
    }

    void removeFront(size_t n)
    in
    {
        assert (mNb >= n);
    }
    body
    {
        mBeg += cast(uint)n;
        if (mBeg >= mData.length)
            mBeg -= cast(uint)mData.length;
        mNb -= n;
    }

    ref T back() @property
    in
    {
        assert (mNb != 0);
    }
    body
    {
        return mData[mEnd];
    }

    void removeBack()
    in
    {
        assert (mNb != 0);
    }
    body
    {
        if (mEnd == 0)
            mEnd = cast(uint)mData.length - 1;
        else
            mEnd--;
        mNb--;
    }

    void removeBack(size_t n)
    in
    {
        assert (mNb >= n);
    }
    body
    {
        if (mEnd < n)
            mEnd += cast(uint)(mData.length - n);
        else
            mEnd -= cast(uint)n;
        mNb -= n;
    }

    ref T opIndex(size_t i)
    in
    {
        assert(i < mNb);
    }
    body
    {
        uint j = cast(uint)i + mBeg;
        if (j >= mData.length)
            j -= mData.length;
        return mData[j];
    }

    bool opEquals(const Ring!T rhs) const
    {
        return opEquals(rhs);
    }

    bool opEquals(ref const Ring!T rhs) const
    {
        if (empty)
            return rhs.empty;
        if (rhs.empty)
            return false;
        return mData == rhs.mData;
    }

    alias opDollar = length;
    alias Range = RangeT!(Ring!T);

    Range opSlice()
    {
        return Range(this, 0, mNb);
    }

    Range opSlice(size_t i, size_t j)
    in
    {
        assert(i < j && j <= mNb);
    }
    body
    {
        return Range(this, cast(uint)i, cast(uint)j);
    }


    /**
     * Put a new element at the end of the array.
     *
     * Complexity: $(BIGOH 1)
     */
    void insertBack(T elem)
    in
    {
        assert (mNb != capacity);
    }
    body
    {
        mEnd++;
        if (mEnd == mData.length)
            mEnd = 0;
        mData[mEnd] = elem;
        mNb++;
    }

    /**
     * Put a new element at the beginning of the array.
     *
     * Complexity: $(BIGOH 1)
     */
    void insertFront(T elem)
    in
    {
        assert (mNb != capacity);
    }
    body
    {
        if (mBeg == 0)
            mBeg = cast(uint)mData.length - 1;
        else
            mBeg--;
        mData[mBeg] = elem;
        mNb++;
    }

    alias put    = insertBack;
    alias insert = insertBack;

    string report() @property const
    {
        import std.format;
        return format("[%d..%d] (%d/%d)", mBeg, mEnd, mNb, cast(uint)mData.length);
    }

private:
    this(ref Ring!T a, uint beg, uint end)
    {
        mData = a.mData;
        mBeg = a.mBeg + beg;
        if (mBeg >= mData.length)
            mBeg -= mData.length;
        mEnd = mBeg + end - 1;
        if (mEnd >= mData.length)
            mEnd -= mData.length;
        mNb = end - beg;
    }

    void accomodate()
    {
        import std.algorithm.mutation : copy;

        if (mNb == 0 || mBeg <= mEnd)
            return;

        auto toMove = mNb - (mEnd + 1);
        auto newSpace = mData.length - (mBeg + toMove);
        if (newSpace >= toMove)
        {
            copy(mData[mBeg .. mBeg + toMove], mData[$ - toMove .. $]);
            mBeg = cast(uint)mData.length - toMove;
        }
        else
        {
            auto destEnd = cast(uint)mData.length;
            do
            {
                copy(mData[mBeg + toMove - newSpace .. mBeg + toMove],
                     mData[destEnd - newSpace .. destEnd]);
                toMove -= newSpace;
                destEnd -= newSpace;
            } while (toMove > newSpace);

            if (toMove != 0)
                copy(mData[mBeg .. mBeg + toMove],
                     mData[destEnd - toMove .. destEnd]);
            mBeg = destEnd - toMove;
        }
    }

    T[]  mData;
    uint mBeg;
    uint mEnd;
    uint mNb;
}


unittest
{
    //import std.stdio;
    alias TestR = Ring!int;
    TestR a;

    import std.range;
    static assert(isOutputRange!(TestR, int));

    assert(a.capacity == 0);

    a.reserve(40);

    // Check put, front, back, opSlice and length
    a.insertBack(5);
    assert(a.front == a.back && a.front == 5);
    a.insertBack(7);
    assert(a.back == 7 && a.front == 5);
    a.insertFront(2);
    assert(a.back == 7 && a.front == 2 && a.length == 3);
    assert(a[0 .. $] == a[]);

    a.removeFront();
    a.removeBack();
    assert(a.front == a.back && a.front == 5 && a.length == 1);

    a.put(6);
    a.put(2);
    a.insert(4);
    a.insert(2);
    // Can it be sorted?
    import std.algorithm.sorting : sort;
    static assert(   hasSwappableElements!(RangeT!TestR)
                  && hasAssignableElements!(RangeT!TestR)
                  && isRandomAccessRange!(RangeT!TestR)
                  && hasSlicing!(RangeT!TestR)
                  && hasLength!(RangeT!TestR));
    sort(a[]);
    assert(a[0] == 2 && a[1] == 2 && a[2] == 4 && a[3] == 5 && a[4] == 6);
    a[3] = 3;
    assert(a[3] == 3 && a.length == 5);

    // Check popFront and insert
    a.insert(13);
    a.insert(14);
    a.removeFront();
    a.insert(15);
    a.insert(16);
    a.insert(17);
    a.insert(18);
    assert(a[0] == 2 && a[1] == 4 && a[2] == 3 && a[3] == 6 && a[4] == 13 &&
           a[5] == 14 && a[6] == 15 && a[7] == 16 && a[8] == 17 && a[9] == 18);
    assert(a.length == 10);

    a.clear();
    assert(a.empty);

    import std.random;

    // check insertBack and removeFront
    a.reserve(100);
    int nbIter = 10_000;
    int inc = 0, outc = 0;
    while (--nbIter > 0)
    {
        foreach (i; 0 .. uniform(1, 10))
        {
            if (a.length == a.capacity)
                break;
            a.insertBack(++inc);
        }

        foreach (i; 0 .. uniform(1, 10))
        {
            if (a.empty)
                break;
            int check = a.front;
            a.removeFront();
            assert(check == outc + 1, a.report);
            outc = check;
        }
    }

    a.clear();

    // check insertFront and removeBack
    nbIter = 10_000;
    inc = 0;
    outc = 0;
    while (--nbIter > 0)
    {
        foreach (i; 0 .. uniform(1, 10))
        {
            if (a.length == a.capacity)
                a.reserve(a.capacity + 5);
            a.insertFront(++inc);
        }

        foreach (i; 0 .. uniform(1, 10))
        {
            if (a.empty)
                break;
            int check = a.back;
            a.removeBack();
            import std.format;
            assert(check == outc + 1, a.report);
            outc = check;
        }
    }
}
