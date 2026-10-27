/* VAMS-2023 2.9: "If a value is not specifically assigned to the attribute,
 * then its value shall be 1." IEEE 1364-2005 3.8 has the same sentence.
 *
 * An attribute means nothing to the language, so its value is observable only
 * through VPI: IEEE 1364-2005 26.6.42 makes an attribute an object of its
 * owner (vpi_iterate(vpiAttribute, owner)), with "-> name str: vpiName" and
 * "-> value: vpi_get_value()". The attributes here are names no tool knows
 * (`conform_*`), so nothing but 2.9 decides their values.
 *
 * DERIVATION. attribute_default_value.v writes `(* conform_flag *) reg r;`,
 * so r's attribute conform_flag reads 1. `(* conform_level = 5 *) reg q;`
 * reads 5: the control that shows vpi_get_value reads the attribute's value
 * and not a constant 1. Each attr() call is 4 checks (iterator, found, type,
 * X
 */

//! lrm 2.9
//! lrm 2.9:3
//! inherited IEEE 1364-2005 3.8
//! inherited IEEE 1364-2005 26.6.42
//! design attribute_default_value.v
//! stdout p02: attribute_default_value checks=11

#include "../ch11_vpi/p02_check.h"

static void attr(vpiHandle owner, const char *name, int wanted)
{
  vpiHandle it = vpi_iterate(vpiAttribute, owner), h, found = NULL;
  s_vpi_value v;
  CHECK(it != NULL, "2.9: the reg carries attribute %s", name);
  while ((h = vpi_scan(it)) != NULL) {
    const char *n = vpi_get_str(vpiName, h);
    if (n && strcmp(n, name) == 0) found = h;
  }
  CHECK(found != NULL, "26.6.42: attribute %s is among the reg's attributes", name);
  CHECK(vpi_get(vpiType, found) == vpiAttribute, "26.6.42: %s is a vpiAttribute", name);
  v.format = vpiIntVal;
  vpi_get_value(found, &v);
  CHECK(v.value.integer == wanted, "2.9: %s reads %d, want %d", name, v.value.integer, wanted);
}

static PLI_INT32 eoc(p_cb_data d)
{
  vpiHandle r, q;
  (void)d;
  r = vpi_handle_by_name("attribute_default_value.r", NULL);
  CHECK(r != NULL, "the reg r is found");
  q = vpi_handle_by_name("attribute_default_value.q", NULL);
  CHECK(q != NULL, "the reg q is found");
  attr(r, "conform_flag", 1);
  attr(q, "conform_level", 5);
  p02_done("attribute_default_value");
  return 0;
}

static void setup(void)
{
  static s_cb_data cb;
  cb.reason = cbEndOfCompile;
  cb.cb_rtn = eoc;
  CHECK(vpi_register_cb(&cb) != NULL, "cbEndOfCompile registration failed");
}

void (*vlog_startup_routines[])(void) = { setup, 0 };
