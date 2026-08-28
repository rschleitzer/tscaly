// SLICE 87. The one thing the base-less branch of getDefaultConstructSignatures
// takes from the class DECLARATION: `abstract` puts SignatureFlagsAbstract on the
// synthesized construct signature. Its member log differs from
// checker_statics_class_plain's in exactly one column — which is why the G line
// exists at all.
abstract class C {
    static a: string;
}
