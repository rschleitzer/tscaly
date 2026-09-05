#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
#
# genunicodeprops.py — generate tscaly/UnicodeProps.scaly from the pinned
# reference's internal/scanner/unicodeproperties.go.
#
# ★ WHY GENERATED. The four tables are 620 names between them (Table 66-68 of
# ECMA-262 plus the Unicode 15.1 script values), and every one of them is a
# LITERAL the reference lists by hand. Transcribing them would be 620 chances to
# mistype a name nobody would ever notice: a wrong entry answers *unknown
# property* for a regex that is correct, or accepts one that is not, and the
# corpus reaches only a handful of them. A generator makes the table a
# consequence of the reference rather than of a reader's eye, and
# tools/gencheck.sh re-runs it.
#
# ★ THE SHAPE IS Keywords.scaly's, and for the same reason: dispatch on LENGTH,
# then compare bytes. No String is constructed and no map exists, so a `\p{...}`
# lookup allocates nothing. The comparison helper is Keywords.kw_eq — one
# spelling of "these bytes are that word" in the package rather than two.
#
# ★ THE CANONICAL PROPERTY NAME IS AN INT HERE, not a string. The reference's
# nonBinaryUnicodeProperties maps an alias to a canonical NAME and then uses that
# name as the key of valuesOfNonBinaryUnicodeProperties — so the string is an
# identity, never a text. Three ids replace it (0 = not a property, the value the
# reference spells as ""), which also removes the `values != nil` test: every
# canonical name has a value set, so the id decides the set outright.
#
# Usage (from the repo root, submodule initialized):
#   packages/tscaly/tools/genunicodeprops.py
#
# The output is committed. With the submodule absent the committed file stays
# valid and this script simply cannot run — same arrangement as genkind.py.

import io
import os
import re
import sys

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
SUB = os.path.join(REPO, "packages/tscaly/_submodules/typescript-go")
SRC = os.path.join(SUB, "internal/scanner/unicodeproperties.go")
DST = os.path.join(REPO, "packages/tscaly/0.1.0/tscaly/UnicodeProps.scaly")

STRING = re.compile(r'"([^"]*)"')


def block(text, header):
    """The literal that follows `header`, up to its own closing bracket. The
    bracket is the header's last character, so a `map[...]{` block and a
    `NewSetFromItems(` block are read by the same walk."""
    i = text.index(header)
    open_ch = header[-1]
    close_ch = ')' if open_ch == '(' else '}'
    depth = 0
    j = i + len(header) - 1
    start = j
    while True:
        if text[j] == open_ch:
            depth += 1
        elif text[j] == close_ch:
            depth -= 1
            if depth == 0:
                break
        j += 1
    return text[start:j]


def strip_comments(s):
    return re.sub(r'//[^\n]*', '', s)


def names(text, header):
    return STRING.findall(strip_comments(block(text, header)))


def dispatch(out, fn, doc, words, result):
    """A length-dispatched membership test over `words`."""
    by_len = {}
    for w in sorted(set(words)):
        by_len.setdefault(len(w), []).append(w)
    out.append('')
    out.extend(doc)
    out.append('function %s(s: Slice[char]) returns %s' % (fn, 'int' if result else 'bool'))
    out.append('{')
    for n in sorted(by_len):
        out.append('    if s.length = %d' % n)
        out.append('    {')
        for w in by_len[n]:
            # ★★★THE LITERAL GOES STRAIGHT INTO THE SLICE PARAMETER, since the
            # compiler materialises it there (2026-09-05).  Before, the
            # hand-counted length stood here; same emission, because the compiler
            # builds the same tuple.  The length it takes is the DECODED byte
            # count -- for these property names that is n, and the assertion
            # holds that down in case one ever carries an escape.
            assert len(w) == n and w.isascii() and "\\" not in w, w
            # ★kw_eq takes the VIEW since 2026-09-05, so `s` goes in whole.
            # `s.data` was a Slice taken apart at the call site purely to fit a
            # pointer parameter -- the shape tools/lenfix/scan.py chases.
            out.append('        if kw_eq(s, "%s")' % w)
            out.append('            return %s' % (result[w] if result else 'true'))
        out.append('    }')
    out.append('    %s' % ('0' if result else 'false'))
    out.append('}')


def main():
    if not os.path.exists(SRC):
        sys.exit(
            "the reference submodule is not initialized — nothing to generate from:\n"
            "  git submodule update --init packages/tscaly/_submodules/typescript-go")
    text = io.open(SRC, encoding='utf-8').read()

    # Table 66 is a MAP, alias -> canonical name; the pairs alternate in the
    # literal, so the even entries are the aliases and the odd ones the canonical
    # names they resolve to.
    flat = names(text, 'var nonBinaryUnicodeProperties = map[string]string{')
    canonical = ['General_Category', 'Script', 'Script_Extensions']
    nonbinary = {}
    for alias, canon in zip(flat[0::2], flat[1::2]):
        nonbinary[alias] = str(canonical.index(canon) + 1)

    binary = names(text, 'var binaryUnicodeProperties = collections.NewSetFromItems(')
    of_strings = names(text, 'var binaryUnicodePropertiesOfStrings = collections.NewSetFromItems(')
    scripts = names(text, 'var scriptValues = collections.NewSetFromItems(')
    # ★ The General_Category values are the INNER set of the value map's first
    # entry, not the map's own literal: read as the map, the three KEYS
    # ("General_Category", "Script", "Script_Extensions") would join the values
    # and `\p{Script}` would validate as a general category.
    values_map = block(text, 'var valuesOfNonBinaryUnicodeProperties = map[string]*collections.Set[string]{')
    general = names(values_map, '"General_Category": collections.NewSetFromItems(')

    out = []
    out.append('; SPDX-License-Identifier: Apache-2.0')
    out.append(';')
    out.append('; UnicodeProps — the four Unicode property tables the regular expression')
    out.append('; grammar validates `\\p{...}` against, ported from the reference\'s')
    out.append('; internal/scanner/unicodeproperties.go.')
    out.append(';')
    out.append('; GENERATED by packages/tscaly/tools/genunicodeprops.py. Do not edit; edit the')
    out.append('; generator. Regenerate after a submodule pin bump.')
    out.append(';')
    out.append('; ★ THE CANONICAL PROPERTY NAME IS AN INT. The reference maps an alias to a')
    out.append('; canonical NAME and then uses that name as the key of the value tables, so the')
    out.append('; string is an identity and never a text. 1 = General_Category, 2 = Script,')
    out.append('; 3 = Script_Extensions, 0 = not a non-binary property — which is the value the')
    out.append('; reference spells as the empty string, and the one `scanCharacterClassEscape`')
    out.append('; branches on.')
    out.append(';')
    out.append('; ★ Script_Extensions shares Script\'s value set, and the reference says why: a')
    out.append('; character\'s Script_Extensions is one or more Script values, and a property')
    out.append('; value expression admits exactly one — so the two sets are the same set.')
    out.append(';')
    out.append('; \u2605 NO `use` CLAUSE. A cross-module free function of this package resolves')
    out.append('; unqualified — Keywords.get_identifier_token is the precedent, and the scanner')
    out.append('; has called it without one since slice 3 — and an explicit `use` changes the')
    out.append('; MANGLED NAME at the call site while leaving the definition unqualified, which')
    out.append('; links as an undefined symbol rather than as a diagnostic (root CLAUDE.md: a')
    out.append('; `use` line feeds the call-mangling machinery, not only visibility).')
    out.append('')

    dispatch(out, 'non_binary_unicode_property',
             ['; Table 66: the non-binary property aliases and their canonical names.',
              '; https://tc39.es/ecma262/#table-nonbinary-unicode-properties'],
             list(nonbinary), nonbinary)
    dispatch(out, 'is_binary_unicode_property',
             ['; Table 67: the binary property aliases.',
              '; https://tc39.es/ecma262/#table-binary-unicode-properties'],
             binary, None)
    dispatch(out, 'is_binary_unicode_property_of_strings',
             ['; Table 68: the binary properties OF STRINGS — the ones a `\\p{...}` may match',
              '; more than one character with, which is why only Unicode Sets mode admits them.',
              '; https://tc39.es/ecma262/#table-binary-unicode-properties-of-strings'],
             of_strings, None)
    dispatch(out, 'is_general_category_value',
             ['; The General_Category values.'],
             general, None)
    dispatch(out, 'is_script_value',
             ['; The Script values, Unicode 15.1 — and Script_Extensions\' too.'],
             scripts, None)

    out.append('')
    out.append('; `valuesOfNonBinaryUnicodeProperties[propertyName].Has(value)`, where the name')
    out.append('; is this file\'s int. Every canonical name has a set, so the reference\'s')
    out.append('; `values != nil` test cannot fail and is not ported; id 0 never reaches here,')
    out.append('; because its one caller has already branched on it.')
    out.append('function values_of_non_binary_unicode_property_has(property: int, s: Slice[char]) returns bool')
    out.append('{')
    out.append('    if property = 1')
    out.append('        return is_general_category_value(s)')
    out.append('    is_script_value(s)')
    out.append('}')
    out.append('')

    io.open(DST, 'w', encoding='utf-8').write('\n'.join(out))
    print('wrote %s (%d non-binary aliases, %d binary, %d of-strings, %d general categories, %d scripts)'
          % (os.path.relpath(DST, REPO), len(nonbinary), len(set(binary)),
             len(set(of_strings)), len(set(general)), len(set(scripts))))


if __name__ == '__main__':
    main()
