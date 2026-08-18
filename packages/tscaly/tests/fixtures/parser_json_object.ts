// Slice 19 — the ordinary JSON document, and the baseline for the kind itself.
// Every node carries JavaScriptFile|JsonFile as CONTEXT flags, which is the only
// way a tree dump can see which grammar ran. The comment and the trailing comma
// are what make a .json file a TypeScript document rather than JSON proper: both
// are accepted here and neither is reported.
//
// This header is dropped by the reference's own splitter, which discards
// everything before the first @Filename directive.
// @Filename: ordinary.json
// a comment, which a strict JSON parser would refuse
{
    "compilerOptions": {
        "target": "es2020",
        "strict": true,
        "removeComments": false,
        "types": ["node", "mocha"],
        "maxNodeModuleJsDepth": 0,
        "baseUrl": null,
    },
    "include": ["src/**/*"]
}
