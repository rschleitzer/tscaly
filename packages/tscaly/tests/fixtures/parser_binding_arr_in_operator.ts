// The semantic half of the array pattern's DisallowIn clear: with it, `c in d`
// inside the initializer is an operator. Without it the expression stops at `c`,
// the element list finds neither a comma nor its `]`, and this port reports
// unported — so this file gates by the MATCHED COUNT, not by a red.
for (var [b = c in d] = y;;) ;
