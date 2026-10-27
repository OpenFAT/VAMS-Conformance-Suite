// IEEE 1364-2005 §9.9.2, p. 144 (Syntax 9-16): "always_construct ::= always
// statement". A.6.4 (p. 498) keeps the null statement out of `statement`:
// "statement_or_null ::= statement | { attribute_instance } ;".
//
// `always ;` gives the construct a null statement, which only
// statement_or_null derives. Legal neighbour: initial_and_always.v,
// whose always constructs each carry a timed statement.
// The rejection pattern names the parse diagnostic: `always begin end` is
// grammatical, and only `always ;` is not.
//! inherited IEEE 1364-2005 9.9.2
//! reject E0209
//! reject statement
//! neighbour initial_and_always.v
module b_9_9_2_always_without_statement_rejected;
  always ;
endmodule
