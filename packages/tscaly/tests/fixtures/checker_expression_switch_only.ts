// The switch clause's comparability question ON ITS OWN, with no `if` in front of
// it to win the first-wins race — which is what makes it a PIN target. Both types
// are needed (the subject's and the clause's), so this unit is the smallest shape
// that reaches isTypeEqualityComparableTo.
switch (null) {
    case null:
        break;
}
