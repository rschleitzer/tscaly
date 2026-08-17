interface A {
    a: string;
    b?: number;
    readonly c: boolean;
    d(): void;
    e?(x: number): string;
    f<T>(x: T): T;
    (): number;
    <T>(x: T): T;
    new (): A;
    new <T>(x: T): A;
    [key: string]: any;
    get g(): number;
    set h(v: number);
    "quoted": number;
    0: number;
    new: number;
    i?<T>(x: T): T;
}
