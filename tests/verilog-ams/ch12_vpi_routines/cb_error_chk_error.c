/* VAMS-2023 12.31.4, the cbError action callback and vpi_chk_error().
 *
 * 12.31.4: "The following action-related callbacks shall be defined: ...
 * cbError  Simulation run-time error occurred", "actions shall occur in all
 * VPI-compliant products", and "On a cbError callback, the routine
 * vpi_chk_error() can be called to retrieve error information." 11.2.3:
 * "Callbacks can be set up for when an error occurs as well. The
 * vpi_chk_error() routine can provide detailed information about the error."
 * So inside the cbError routine vpi_chk_error() reports the error: a nonzero
 * return (12.2's "error severity level") and a filled s_vpi_error_info.
 *
 * THE ERROR. cb_error_readmem.v calls $readmemh at t=1 with
 * cb_error_readmem.hex, whose @8 lies outside the task's range 0..3: IEEE
 * 1364-2005 17.2.9, "an error message is issued, and the load operation is
 * terminated". That is a simulation run-time error, so cbError fires.
 *
 * DERIVATION. The cbError routine only records (a CHECK there would exit
 * mid-callback): how often it ran, and what vpi_chk_error() returned. At
 * cbEndOfSimulation: it ran at least once (1 check), vpi_chk_error() returned
 * nonzero in it (1 check), and the info's level is one of 12.2's error levels
 * (vpiNotice .. vpiInternal, 1 check). With the two registrations, 5 checks.
 */

//! lrm 12.31.4
//! lrm 12.31.4:1002
//! inherited IEEE 1364-2005 17.2.9
//! design cb_error_readmem.v
//! stdout p02: cb_error_chk_error checks=5

#include "../ch11_vpi/p02_check.h"

static int n_error = 0;
static PLI_INT32 chk = 0;
static PLI_INT32 level = 0;

static PLI_INT32 on_error(p_cb_data d)
{
  s_vpi_error_info info;
  (void)d;
  n_error++;
  memset(&info, 0, sizeof info);
  chk = vpi_chk_error(&info);
  level = info.level;
  return 0;
}

static PLI_INT32 on_end(p_cb_data d)
{
  (void)d;
  CHECK(n_error >= 1, "12.31.4: cbError did not fire for the $readmemh error");
  CHECK(chk != 0, "12.31.4: vpi_chk_error() in the cbError routine reported no error");
  CHECK(level >= vpiNotice && level <= vpiInternal, "12.2: error level %d is not a vpiNotice..vpiInternal level", (int)level);
  p02_done("cb_error_chk_error");
  return 0;
}

static void setup(void)
{
  static s_cb_data e, f;
  e.reason = cbError;
  e.cb_rtn = on_error;
  CHECK(vpi_register_cb(&e) != NULL, "cbError registration failed");
  f.reason = cbEndOfSimulation;
  f.cb_rtn = on_end;
  CHECK(vpi_register_cb(&f) != NULL, "cbEndOfSimulation registration failed");
}

void (*vlog_startup_routines[])(void) = { setup, 0 };
