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
private template Iota(size_t i, size_t n)
{
    static if (n == 0)
        alias Iota = AliasSeq!();
    else
        alias Iota = AliasSeq!(i, Iota!(i + 1, n - 1));
}