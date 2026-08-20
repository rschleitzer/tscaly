// slice 37 — the OTHER direction of the indicator split. Three of the binder's
// strict-mode checks pick between two or three MESSAGES, and the question they
// ask is `file.ExternalModuleIndicator != nil` — the EXTERNAL half alone. A file
// that is a module only because it is CommonJS must therefore get the PLAIN
// message, and widening any of the three to IsExternalOrCommonJSModule is a
// well-formed wrong answer that no shape check and no crash can see.
//
//   implements   getStrictModeIdentifierMessage — TS1214 plain, not the
//                "Modules are automatically in strict mode" spelling
//   eval = 2     getStrictModeEvalOrArgumentsMessage — TS2333 plain
//   await        checkStrictModeIdentifier's await arm, which reports
//                "reserved word at the top level of a module" ONLY for an
//                external module, so here it reports nothing at all
// @Filename: strictmsg.js
exports.a = 1;
var implements = 1;
eval = 2;
var await = 3;
