// slice 37 — JSDeclarationKindObjectDefinePropertyExports, the one assignment
// kind that is a CALL rather than an assignment. IsBindableObjectDefinePropertyCall
// wants exactly three arguments, `Object.defineProperty` as the callee and an
// entity name as the first argument; the NAME of the declaration is the SECOND
// argument, which is why get_name_of_declaration's arm reads Arguments()[1]
// rather than a name slot.
//
// The value form — a first argument that is neither `exports` nor
// `module.exports` — is JSDeclarationKindObjectDefinePropertyValue and belongs to
// the deferred expando pass, so it is not here.
// @Filename: define.js
Object.defineProperty(exports, "a", { value: 1 });
Object.defineProperty(module.exports, "b", { get: function () { return 2; } });
