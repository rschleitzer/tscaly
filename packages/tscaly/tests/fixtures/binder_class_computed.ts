declare const sym: unique symbol;
declare const other: symbol;
class A {
    [sym]() {}
    [other]: number;
    get [sym + ""]() { return 1; }
}
interface B {
    [sym]: string;
}
