// A missing `{` is a BRANCH, not an expectation — §3.5bi. When parseExpected
// fails, the reference hands the node the MISSING-list sentinel and does NOT
// enter the member list, so the declaration ENDS at the header and the text
// after it re-parses as statements. Entering the list anyway consumes the
// offending token as a member, which moves the parent's `end`, adds a member
// node the reference does not have and emits one diagnostic too many.
//
// Four sites, one per line — enum, class, object type members, module block.
// The class arm is `var class;`, whose `;` becomes a SemicolonClassElement;
// the interface arm must leave the declaration at `Foo` and read `.I1` as an
// expression statement.
enum void {}
var class;
function f1(enum) {}
interface Foo.I1 { }
namespace N x
