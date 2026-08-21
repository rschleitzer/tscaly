// slice 39 — the five modifiers that make a parameter a property.
// ModifierFlagsParameterPropertyModifier is AccessibilityModifier | Readonly |
// Override, i.e. public, private, protected, readonly and override — any ONE of
// them is enough, and `public readonly` together is still one property.
class Base {
    d: number;
}
class A extends Base {
    constructor(public a: number, private b: number, protected c: number, override d: number, readonly e: number, public readonly f: number) {}
}
