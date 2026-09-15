#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
#
# gendiagnostics.py — generate tscaly/DiagnosticCodes.scaly from the pinned
# reference's diagnostic message table.
#
# The yardstick compares a diagnostic's CODE and SPAN, never its text (see
# TESTPLAN.md — the message lives in a 2000-entry table this port has no reason
# to carry). So what the port needs from `internal/diagnostics` is one integer
# per message, and typing those by hand would be 60-odd magic numbers whose only
# check is a reader's eye.
#
# ★ WHICH messages: exactly the ones the reference's SCANNER and PARSER
# reference, deduped — a `diagnostics.NAME` scrape over scanner.go and
# parser.go. ★The scrape must refuse a match preceded by a dot: `diagnostics` is
# also the name of a FIELD (`c.diagnostics.Add`), and slice 50 paid for that when
# checker.go joined. That rule is mechanical and it is the reason this generator does not
# emit all ~2400 codes: a table nothing reads is a table nobody checks, and the
# two files named here are precisely the port's surface. A message that a later
# slice needs (the checker's) will be picked up by widening the SOURCES list,
# which is a one-line edit with a stated reason.
#
# ★ The emitted NAME is the reference's own Go identifier with a `Diag` prefix,
# unaltered — mixed case, underscores and all. It reads oddly in Scaly and that
# is the point: a site in our scanner spells the same name as the site in the
# reference's, so the two can be diffed by eye and by grep. Renaming them into
# house style would break the only check there is.
#
# Usage (from the repo root, submodule initialized):
#   packages/tscaly/tools/gendiagnostics.py
#
# The output is committed. With the submodule absent the committed file stays
# valid and this script simply cannot run — same arrangement as genkind.py.

import os
import re
import sys

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
SUB = os.path.join(REPO, "packages/tscaly/_submodules/typescript-go")
TABLE = os.path.join(SUB, "internal/diagnostics/diagnostics_generated.go")
SOURCES = [
    os.path.join(SUB, "internal/scanner/scanner.go"),
    # Slice 140. regexp.go joins under the same per-FILE rule, and it is the
    # clearest case of it: the REGULAR EXPRESSION grammar reports, and 34 of its
    # 37 messages appear in NO other source of this list — the whole TS1499-TS1534
    # block plus TS1005's neighbours. Without this line the port would have to
    # spell an entire grammar's diagnostics as bare numbers.
    os.path.join(SUB, "internal/scanner/regexp.go"),
    os.path.join(SUB, "internal/parser/parser.go"),
    # Slice 21. jsdoc.go is the parser's second grammar and sits in the same
    # package; six of its messages appear nowhere else, so the port would have
    # had to spell them as bare numbers.
    os.path.join(SUB, "internal/parser/jsdoc.go"),
    # Slice 27. The BINDER reports too, into a list of its own that neither
    # Diagnostics() nor JSDiagnostics() includes — 5 207 diagnostics over 21 codes
    # across the stage-2 corpus, TS2300 (Duplicate identifier) alone 3 425 — and
    # the symbols yardstick compares them. Widening this list is exactly the
    # arrangement the header describes for the phase after the parser.
    os.path.join(SUB, "internal/binder/binder.go"),
    # Slice 48. The CHECKER's grammar checks are its own file, and the first two
    # of them are ported here — checkGrammarSourceFile's declare-modifier walk and
    # checkGrammarStatementInAmbientContext. Widening the list by this file rather
    # than by the three messages those two report is the arrangement the header
    # describes: the rule is mechanical and per-FILE, so that the next grammar arm
    # is a port and not a second edit here. It costs 181 entries with no reader
    # yet, which is the same bargain internal/binder/binder.go was: 21 of its codes
    # are what the corpus actually reports.
    #
    os.path.join(SUB, "internal/checker/grammarchecks.go"),
    # Slice 50. checker.go joins, on the condition the note that stood here set:
    # *it joins when an arm of checker.go reports*. The import/export/module family
    # is that arm — every one of its five arms names its illegal-context message
    # in checker.go, and so do `Only ambient modules can use quoted names`, the
    # module-keyword advice and the two namespace-export reports. So the table
    # grows 337 -> 947 codes, and the selectivity argument that kept this file out
    # is spent rather than overruled: it said a table nothing reads is a table
    # nobody checks, and the reader has arrived.
    #
    # ★★ AND WIDENING IT FOUND A DEFECT IN THE SCRAPE THAT ONLY THIS FILE COULD
    # SHOW: the old regex was `\bdiagnostics\.NAME`, and `\b` matches after a DOT,
    # so a FIELD named `diagnostics` reads as the PACKAGE. checker.go has one —
    # `c.diagnostics.Add`, `.Lookup`, `.GetGlobalDiagnostics` — and those three
    # arrived as message names that are not in the table. They were REPORTED rather
    # than skipped, which is the arrangement the note below the `Message` discard
    # describes and the reason the defect cost nothing. The lookbehind is proven
    # neutral on the five older sources: the same 337 names, as a set.
    os.path.join(SUB, "internal/checker/checker.go"),
    # Slice 91. nameresolver.go joins under the same per-FILE rule, and for the
    # same reason checker.go did: an arm of it reports. `Resolve`'s four
    # message-gated steps are ported with this slice — the enum member reached
    # from another file, the class type parameter in a static member, the base
    # class expression and the computed property name — and three of those four
    # messages appear in NO other source, so the port would otherwise have to
    # spell them as bare numbers. It costs 4 new entries: the scrape is by NAME
    # and this file's other uses are already in the table.
    os.path.join(SUB, "internal/binder/nameresolver.go"),
    # Slice 101. relater.go joins under the same per-FILE rule, and it is the file
    # the rule was written for: the ASSIGNABILITY RELATION reports, and its own
    # message — `Type_0_is_not_assignable_to_type_1`, TS2322 — appears in NO other
    # source of this list, so without this line the port would have to spell the
    # most common error the TypeScript checker emits as a bare number. The scrape is
    # by NAME and most of relater.go's other messages are already in the table
    # through checker.go, so the cost is small and stated with the diff.
    os.path.join(SUB, "internal/checker/relater.go"),
    # Slice 264: the module resolver's resolution diagnostics (util.go's
    # GetResolutionDiagnostic, which resolveExternalModule reports) and the
    # program's option and file diagnostics (program.go, the case yardstick's TS5xxx)
    os.path.join(SUB, "internal/module/util.go"),
    os.path.join(SUB, "internal/compiler/program.go"),
    # Slice 268. The program's file loader reports its explaining diagnostics
    # (File_0_not_found, the allowJs hint, the reference to itself) from these.
    os.path.join(SUB, "internal/compiler/fileloader.go"),
    # Slice 273. The resolver's own diagnostics (the ambiguous project root).
    os.path.join(SUB, "internal/module/resolver.go"),
    # Slice 273. The tsconfig conversion reports (the unknown option, the invalid
    # enum value, the wrong value type) from these two.
    os.path.join(SUB, "internal/tsoptions/tsconfigparsing.go"),
    os.path.join(SUB, "internal/tsoptions/errors.go"),
    os.path.join(SUB, "internal/compiler/filesparser.go"),
    os.path.join(SUB, "internal/compiler/processingDiagnostic.go"),
    # Slice 119. jsx.go joins under the same per-FILE rule: the JSX element chapter
    # reports, and four of its messages appear in NO other source of this list —
    # TS17004 (the --jsx flag), TS7026 (no interface JSX.IntrinsicElements),
    # TS2604/TS2607 and the three `Its_..._is_not_a_valid_JSX_element` heads. The
    # scrape is by NAME and most of jsx.go's other messages are already in the
    # table through checker.go and grammarchecks.go, so the cost is small and
    # stated with the diff.
    os.path.join(SUB, "internal/checker/jsx.go"),
    # Slice 182. checker/jsdoc.go joins under the same per-FILE rule:
    # checkUnmatchedJSDocParameters reports, and its two messages appear in NO
    # other source of this list — TS8029 (the `arguments` advice) and TS8032 (the
    # qualified name without a leading @param object). Its third, TS8024, does
    # not either. The scrape is by NAME, so the cost is those three entries.
    os.path.join(SUB, "internal/checker/jsdoc.go"),
    # Slice 202. flow.go joins under the same per-FILE rule: reportFlowControlError
    # reports, and its one message — TS2563, the body too large for control flow
    # analysis — appears in NO other source of this list. The cost is that entry.
    os.path.join(SUB, "internal/checker/flow.go"),
    # Slice 250. The DECLARATION EMITTER's three files join under the same
    # per-FILE rule: the transformer and its symbol tracker report (the TS4xxx
    # "has or is using private name" family, the isolatedDeclarations family,
    # the CommonJS `module.exports` serialization errors), and diagnostics.go is
    # nothing but the selector tables that pick among them. None of those codes
    # appears in any other source of this list. What the port does with a
    # declaration diagnostic today is COUNT it: the reference skips the .d.ts
    # of a file that reports one, so the presence is observable on the case
    # yardstick even though no yardstick compares the codes yet.
    os.path.join(SUB, "internal/transformers/declarations/transform.go"),
    os.path.join(SUB, "internal/transformers/declarations/tracker.go"),
    os.path.join(SUB, "internal/transformers/declarations/diagnostics.go"),
    # Phase (b)2, the driver: the command line (its parser, the did-you-mean tables,
    # the option declarations' help texts), internal/execute's compilation and build
    # paths, and the diagnostic writer's summary.
    os.path.join(SUB, "internal/tsoptions/commandlineparser.go"),
    os.path.join(SUB, "internal/tsoptions/diagnostics.go"),
    os.path.join(SUB, "internal/tsoptions/parsedcommandline.go"),
    os.path.join(SUB, "internal/execute/tsc.go"),
    os.path.join(SUB, "internal/execute/tsc/help.go"),
    os.path.join(SUB, "internal/execute/tsc/init.go"),
    os.path.join(SUB, "internal/execute/tsc/emit.go"),
    os.path.join(SUB, "internal/execute/tsc/statistics.go"),
    os.path.join(SUB, "internal/execute/watcher.go"),
    os.path.join(SUB, "internal/execute/build/orchestrator.go"),
    os.path.join(SUB, "internal/execute/build/buildtask.go"),
    os.path.join(SUB, "internal/execute/incremental/program.go"),
    os.path.join(SUB, "internal/diagnosticwriter/diagnosticwriter.go"),
]
DST = os.path.join(REPO, "packages/tscaly/0.1.0/tscaly/DiagnosticCodes.scaly")

# var X_0_expected = &Message{code: 1005, category: CategoryError, key: "...", text: "..."}
ENTRY = re.compile(r'^var (\w+) = &Message\{code: (\d+), category: Category(\w+),')
USE = re.compile(r"(?<![.\w])diagnostics\.([A-Za-z_][A-Za-z_0-9]*)\b")


def main():
    if not os.path.exists(TABLE):
        sys.exit(
            "the reference submodule is not initialized — nothing to generate from:\n"
            "  git submodule update --init packages/tscaly/_submodules/typescript-go"
        )

    codes = {}
    categories = {}
    with open(TABLE, encoding="utf-8") as f:
        for line in f:
            m = ENTRY.match(line)
            if m:
                codes[m.group(1)] = int(m.group(2))
                categories[m.group(1)] = m.group(3)

    used = set()
    for src in SOURCES:
        with open(src, encoding="utf-8") as f:
            used |= set(USE.findall(f.read()))

    # `diagnostics.Message` is the TYPE, not a message; it appears in every
    # signature. Anything else that does not resolve is a real problem with this
    # scrape and is reported rather than skipped — the trap the root CLAUDE.md
    # records for the ABI audit, where 82 wrong result types hid behind one
    # silently unparsable type name.
    used.discard("Message")
    # ★ And `diagnostics.Category*` are the CATEGORY constants, not messages.
    # binder.go names one directly (CategorySuggestion, for the unused-label
    # suggestion it reports), which is the same class as `Message` above: a name in
    # this package that is not a message. The set is narrow and named rather than a
    # pattern that could swallow a real miss.
    # the driver's help and writer name the TYPE `diagnostics.Category` as well
    used.discard("Category")
    for category in ("CategoryError", "CategoryWarning", "CategorySuggestion",
                     "CategoryMessage"):
        used.discard(category)
    # ★ Slice 273: tsconfigparsing.go names two messages inside COMMENTED-OUT
    # DefaultValueDescription fields, and the table no longer carries them. The
    # set is narrow and named, as above.
    for commented in ("Node_modules_bower_components_jspm_packages_plus_the_value_of_outDir_if_one_is_specified",
                      "if_files_is_specified_otherwise_Asterisk_Asterisk_Slash_Asterisk"):
        used.discard(commented)
    missing = sorted(n for n in used if n not in codes)
    if missing:
        sys.exit(
            "these names are referenced by the scanner or parser but are not in the\n"
            "message table — the scrape is wrong, not the reference:\n  "
            + "\n  ".join(missing)
        )

    names = sorted(used, key=lambda n: (codes[n], n))
    # Align to a readable column rather than to the LONGEST name: one reference
    # message identifier is 154 characters, and padding every line out to it
    # turns the file into whitespace. A name past the column simply gets one
    # space, which the formatter corpus check accepts either way.
    width = min(max(len("Diag" + n) for n in names) + 1, 76)

    out = []
    out.append("; SPDX-License-Identifier: Apache-2.0")
    out.append(";")
    out.append("; DiagnosticCodes — the TS error numbers, ported from the reference's")
    out.append("; internal/diagnostics/diagnostics_generated.go.")
    out.append(";")
    out.append("; GENERATED by packages/tscaly/tools/gendiagnostics.py. Do not edit; edit the")
    out.append("; generator. Regenerate after a submodule pin bump.")
    out.append(";")
    out.append("; ONE INTEGER PER MESSAGE, and no text. The yardstick compares a diagnostic's")
    out.append("; code and span; the message string lives in a table this port has no reason to")
    out.append("; carry, and TESTPLAN.md says so where it lists what the dump format does not")
    out.append("; show — a wrong message with a right code passes here.")
    out.append(";")
    out.append("; The set is exactly the messages the reference's scanner.go, parser.go,")
    out.append("; jsdoc.go, binder.go, grammarchecks.go and checker.go reference, deduped —")
    out.append("; refusing a match preceded by a dot, because `diagnostics` is also a FIELD")
    out.append("; name. The NAMES are the reference's own")
    out.append("; Go identifiers with a")
    out.append("; `Diag` prefix and nothing else changed, so a site in our scanner spells the")
    out.append("; same name as the site in theirs and the two can be diffed by grep.")
    out.append(";")
    out.append("; Sorted by CODE rather than by name, because that is the order a failing")
    out.append("; diff prints them in.")
    out.append("")
    for n in names:
        # ★ A name past the alignment column still needs its separating space —
        # ljust does nothing there, and `…inclusive:int 1198` is a different token
        # sequence from `…inclusive: int 1198`. Caught by a grep for the code that
        # found 124 of the 125 and reported the 125th as absent.
        label = ("Diag" + n + ":").ljust(width)
        if not label.endswith(" "):
            label += " "
        out.append(
            "define {}int {}{}".format(
                label,
                codes[n],
                "" if categories[n] == "Error" else "   ; " + categories[n],
            )
        )
    out.append("")

    with open(DST, "w", encoding="utf-8") as f:
        f.write("\n".join(out))

    print(
        "wrote {} ({} codes, from {} messages in the table)".format(
            os.path.relpath(DST, REPO), len(names), len(codes)
        )
    )


if __name__ == "__main__":
    main()
