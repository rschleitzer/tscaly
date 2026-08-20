namespace OnlyTypes {
    interface I { a: number; }
    export { I };
}
namespace HasValue {
    const v = 1;
    export { v };
}
namespace ReExport {
    import q = OnlyTypes;
    export { q };
}
namespace Missing {
    export { nowhere };
}
