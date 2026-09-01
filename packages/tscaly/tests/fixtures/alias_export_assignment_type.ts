// Slice 114: getTypeOfVariableOrParameterOrPropertyWorker's ExportAssignment arm.
// `export = expr` gives the file's export symbol a type, and until getTypeOfAlias
// existed nothing asked that symbol for one.
const value = 1;
export = value;
