// parseSemicolonAfterPropertyName's second arm: a call where a type annotation
// was expected. It reports and CONSUMES the `(`, which the `@` arm above it
// deliberately does not.
class C { p: number() }
