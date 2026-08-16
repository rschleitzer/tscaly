declare const v: any;
const a = v as string;
const b = v as string as number;
const c = v satisfies string;
const d = 1 + v as string;
const e = v as string | number;
const f = (v as string).length;
const g = v as const;
const h = v! as string;
const i = [v as string];
const j = v
as (string);
