type A<T> = T;
type B<T, U> = T;
type C<T extends string> = T;
type D<T = string> = T;
type E<T extends string = "a"> = T;
type F<in T> = T;
type G<out T> = T;
type H<in out T> = T;
type I<const T> = T;
type J<T> = T extends string ? number : boolean;
type K<T> = T extends Array<infer U> ? U : never;
type L<T> = T extends infer U extends string ? U : never;
type M<T> = T extends string ? T extends "a" ? 1 : 2 : 3;
type N<T> = T extends (string) ? 1 : 2;
type O<T> = keyof T extends infer U ? U : never;
type P<T> = T |
  string;
