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

module orb.utils.traits;

public import std.traits;

private template updateAttr(F, uint NA)
{
    static if (NA & FunctionAttribute.safe)
        enum updateAttr = (functionAttributes!F | NA) &
                          ~(FunctionAttribute.trusted |
                            FunctionAttribute.system);
    else static if (NA & FunctionAttribute.trusted)
        enum updateAttr = (functionAttributes!F | NA) &
                          ~(FunctionAttribute.safe |
                            FunctionAttribute.system);
    else static if (NA & FunctionAttribute.system)
        enum updateAttr = (functionAttributes!F | NA) &
                          ~(FunctionAttribute.safe |
                            FunctionAttribute.trusted);
    else
        enum updateAttr = functionAttributes!F | NA;
}

auto assumeAttr(uint A, T)(T t) pure @trusted
    if (isFunctionPointer!T || isDelegate!T)
{
    enum newAttrs = updateAttr!(T, A);
    return cast(SetFunctionAttributes!(T, functionLinkage!T, newAttrs)) t;
}

/**
 * Need a compile-time iota to enable "static foreach()"
 *
 * ie. foreach (i; Iota!(0, N)) { ... }
 */
template Iota(int i, int n)
{
    import std.meta : AliasSeq;

    static if (n == 0)
        alias Iota = AliasSeq!();
    else
        alias Iota = AliasSeq!(i, Iota!(i + 1, n - 1));
}


/**
 * Used to list the members of a module.
 */
template moduleMembers(string moduleName, alias Pred)
{
    import std.format : format;
    import std.meta : Filter;
    mixin(q{
        alias moduleMembers = Filter!(Pred, __traits(allMembers, %s));
    }.format(moduleName));
}
