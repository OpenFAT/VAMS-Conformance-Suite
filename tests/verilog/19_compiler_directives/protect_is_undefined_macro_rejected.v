//! inherited IEEE 1364-2005 19.3.2 (VerA's choice, VD-126)
//! reject undefined macro: `protect
// `protect is not one of clause 19's directives, so it is a use of an
// undefined macro (pr478). §19.3.2 gives an undefined macro no value and makes
// no error of it; VerA refuses the use (docs/specification/Vague_Decisions.md VD-126),
// since expanding it to nothing hides a typo.
`protect
module triage_protect_is_undefined_macro_rejected;
endmodule
