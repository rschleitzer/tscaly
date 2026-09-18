# Role analyzer: for every mention of a type-list binding inside its own function,
# decide the ROLE of that occurrence (method call on it, index read, argument of a
# named callee, or a bare use) instead of matching the whole LINE.
import re, sys, collections

READONLY={'get_union_type','get_union_type_ex','get_intersection_type','get_intersection_type_ex',
          'filtered_union_origin','get_union_or_intersection_type','check_cross_product_union'}
INPLACE={'insert_type_at','insert_type_sorted','append_type_if_unique','binary_search_type',
         'contains_type','type_list_contains'}
METHODS={'add','put','get_length','get','get_iterator','get_capacity'}

def enclosing_callee(line, pos):
    """the callee of the innermost call containing `pos`, or None for a bare use"""
    depth=0
    i=pos-1
    while i >= 0:
        c=line[i]
        if c==')': depth+=1
        elif c=='(':
            if depth==0:
                j=i-1
                while j>=0 and (line[j].isalnum() or line[j]=='_'): j-=1
                name=line[j+1:i]
                if name: return name
                return '('        # a grouping paren: keep looking outward
            depth-=1
        i-=1
    return None

def classify(line, name):
    """verdicts for every occurrence of `name` in `line`"""
    out=[]
    for m in re.finditer(r'(?<![A-Za-z0-9_.])%s(?![A-Za-z0-9_])' % re.escape(name), line):
        s,e=m.start(), m.end()
        before=line[:s].rstrip()
        after=line[e:]
        if before.endswith('&'):
            out.append(('address-taken', line.strip())); continue
        mm=re.match(r'\.(\w+)\(', after)
        if mm:
            out.append(('ok-method' if mm.group(1) in METHODS else 'method:'+mm.group(1), None)); continue
        if after.startswith('['):
            out.append(('ok-index', None)); continue
        if after.startswith('.'):
            out.append(('field:'+after[1:12], line.strip())); continue
        callee=enclosing_callee(line, s)
        if callee in READONLY or callee in INPLACE:
            out.append(('ok-arg:'+callee, None)); continue
        if callee is None or callee=='(':
            out.append(('bare', line.strip())); continue
        out.append(('arg:'+callee, line.strip()))
    return out

def func_range(src, i):
    a=i
    while a>0 and not re.match(r'    (function|procedure|operator) ', src[a]): a-=1
    b=i+1
    while b<len(src) and not re.match(r'    (function|procedure|operator) ', src[b]): b+=1
    return a,b

def run(path, apply=False):
    src=open(path).read().split('\n')
    conv=0; reasons=collections.Counter(); why=collections.Counter()
    for i,l in enumerate(src):
        m=re.search(r'^(\s*)(let|var) (\w+) this\.new_type_list(?:\(null\)|_of\(\d+\))$', l)
        if not m: continue
        ind,kw,name=m.group(1),m.group(2),m.group(3)
        a,b=func_range(src,i)
        ok=True
        for k in range(a,b):
            if k==i: continue
            for verdict, ctx in classify(src[k], name):
                if verdict.startswith('ok-'):
                    if verdict.startswith('ok-arg:'): why[verdict[7:]]+=1
                    continue
                ok=False; reasons[verdict]+=1
        if not ok: continue
        conv+=1
        if apply: src[i]="%s%s %s &Array[ref[Type]?]()" % (ind,kw,name)
    if apply: open(path,'w').write('\n'.join(src))
    print(("APPLIED " if apply else "DRY RUN ")+"convertible sites:", conv)
    print("consumers seen:", dict(why.most_common(8)))
    print("rejection roles (top 14):")
    for k,v in reasons.most_common(14): print("  %4d  %s" % (v,k))

run('checker.scaly', apply=(len(sys.argv)>1 and sys.argv[1]=='--apply'))
