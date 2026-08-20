declare var eval: any;
declare var args: any;
eval = 1;
arguments = 2;
eval += 3;
class C {
    m() {
        eval = 4;
        arguments = 5;
    }
}
args = 6;
eval === 7;
arguments < 8;
