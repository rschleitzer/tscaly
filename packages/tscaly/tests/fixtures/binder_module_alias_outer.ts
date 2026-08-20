interface v { a: number; }
namespace Outer {
    const v = 1;
    namespace Inner {
        export { v };
    }
}
