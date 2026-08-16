function a() { }
function b(x) { }
function c(x, y, z) { }
function d(x: string, y: number) { }
function e(x?: string) { }
function f(...rest: string[]) { }
function g(x = 1) { }
function h(x: string = "s", y?: number) { }
function i(): void { }
function j(x: string): number { return 1; }
function k<T>(x: T): T { return x; }
function l<T, U extends T>(x: T, y: U) { }
function m(this: string, x: number) { }
function n(x,) { }
function o() { return; }
function* p() { }
function* q(yield) { }
function r(await) { }
async function s(x: string) { }
export function t(u: number) { }
export function ta(u: number): u is string;
export default function () { }
declare function v(x: string): void;
function w(x: string): x is string;
function w(x) { return x; }
function x(readonly, public, private) { }
function y(a: string, b: (c: number) => void) { }
function z() { function inner(q: number) { return q; } return null; }
