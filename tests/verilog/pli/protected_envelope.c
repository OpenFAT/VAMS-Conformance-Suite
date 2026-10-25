/* b 26.3.5 — vpiIsProtected TRUE for an object a decryption envelope declares.
 *
 * IEEE 1364-2005 §26.3.5, p. 381: "The vpiIsProtected property shall be TRUE
 * if the object_handle represents code that is protected; otherwise, it shall
 * be FALSE." Protected code is the cleartext of a §28 decryption envelope,
 * which VerA decrypts with the key provider's keys (VD-127; the design names
 * them with `//@ protect-keys`). VerA's vpi_user.h makes vpiIsProtected
 * Annex G's vpiProtected (VD-045).
 *
 * ------------------------------------------------------------------ DERIVATION
 *
 * protected_envelope.v declares clear_r outside the envelope and hidden_r
 * inside it; the module itself is declared outside. At cbEndOfCompile:
 *
 *   p_protected            the module, declared in clear text    -> 0
 *   p_protected.clear_r    a reg declared in clear text          -> 0
 *   p_protected.hidden_r   a reg declared in the cleartext of
 *                          the envelope                           -> 1
 *
 * Each with no error after it, so 0 is FALSE and not a failure value. The
 * 1 also shows the envelope was decrypted: an undecrypted one declares no
 * hidden_r, and vpi_handle_by_name fails first.
 */
//@ protect-keys ../28_protected_envelopes/known_keys.json

//! inherited IEEE 1364-2005 26.3.5
//! design protected_envelope.v
//! stdout p02: b_26_3_5_protected_envelope checks=13

#include "b_check.h"

static PLI_INT32 eoc(p_cb_data d)
{
  vpiHandle hidden;
  (void)d;
  CHECK(vpi_get(vpiIsProtected, p02_by_name("p_protected")) == 0, "26.3.5: a module declared in clear text is not protected");
  expect_no_error("the module");
  CHECK(vpi_get(vpiIsProtected, p02_by_name("p_protected.clear_r")) == 0, "26.3.5: a reg declared in clear text is not protected");
  expect_no_error("clear_r");
  hidden = p02_by_name("p_protected.hidden_r");
  CHECK(vpi_get(vpiIsProtected, hidden) == 1, "26.3.5: a reg the envelope declares is protected");
  expect_no_error("hidden_r");
  p02_done("b_26_3_5_protected_envelope");
  return 0;
}

static void startup(void)
{
  static s_cb_data c;
  c.reason = cbEndOfCompile;
  c.cb_rtn = eoc;
  CHECK(vpi_register_cb(&c) != NULL, "startup registers");
}

void (*vlog_startup_routines[])(void) = { startup, 0 };
