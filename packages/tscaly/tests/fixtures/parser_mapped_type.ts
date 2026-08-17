type A<T> = { [K in keyof T]: T[K] };
type B<T> = { readonly [K in keyof T]: T[K] };
type C<T> = { [K in keyof T]?: T[K] };
type D<T> = { +readonly [K in keyof T]+?: T[K] };
type E<T> = { -readonly [K in keyof T]-?: T[K] };
type F<T> = { [K in keyof T as string]: T[K] };
type G<T> = { [K in keyof T] };
