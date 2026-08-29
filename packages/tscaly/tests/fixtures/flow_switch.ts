// A switch clause's flow: an empty clause falls into the next one and the group
// shares a label, a non-empty clause that does not break hands its flow to its
// successor through FallthroughFlowNode, and a switch with no `default` gets an
// extra 0..0 clause node so that "none matched" is an edge past the statement.
function withDefault(x: number) {
    switch (x) {
        case 1:
        case 2:
            x = 10;
        case 3:
            x = 20;
            break;
        default:
            x = 30;
    }
    return x;
}

function noDefault(x: string) {
    switch (x) {
        case "a":
            return 1;
        case "b":
            break;
    }
    return 0;
}
