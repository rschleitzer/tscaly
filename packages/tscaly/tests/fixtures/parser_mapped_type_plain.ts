type A<T> = { [K in T]: number };
type B<T> = { readonly [K in T]?: string };
