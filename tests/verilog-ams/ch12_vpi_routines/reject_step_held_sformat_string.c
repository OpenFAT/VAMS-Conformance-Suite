/* VAMS-2023 12.36 and 9.3: a string a rejected step formatted is not the
 * string the next attempt holds.
 *
 *   9.3     "The goal of the defined behavior of a system task or function in
 *           the analog context is that a call to a such system task or
 *           function in an analog block during an iteration that is rejected
 *           should cause no side-effects on the next iteration."
 *   5.10    and 3.3: a variable assigned in an event body holds its value
 *           between events; 9.5.3 makes a $sformat result an ordinary string
 *           value, so it holds the same way.
 *   12.36   "vpiRejectTransientStep -- cause the current analog simulation
 *           time point to be rejected. This operation shall pass one argument
 *           which is the current timestep (delta)."
 *
 * The design (reject_step_held_sformat_string.va) holds `s`, formatted by
 * @(timer(1, 1)) at t = 1, 2, 3 as "10", "20", "30", and drives V(out) with
 * the code of the text each evaluation reads BEFORE its own timer statement.
 * The plugin accepts everything except the first acbConvergenceTest at
 * t >= 2: the attempt at the timer's t = 2, which formatted "20". It rejects
 * that one with vpiRejectTransientStep.
 *
 * WHERE THE TOOL BACKS UP IS ITS OWN. vpiRejectTransientStep passes the delta,
 * not a retry time, so nothing below depends on the retry time beyond what
 * every conforming backup satisfies: the retry is strictly earlier than the
 * rejected time (12.36's sim_control_reject_step.c pins that) and later than
 * the accepted t = 1 (8.4.7: an accepted solution stays accepted). So it lies
 * in (1, 2), where no timer fires, and it must read what the last ACCEPTED
 * firing formatted, "10": V(out) == 10. A tool whose rejected attempt left its
 * "20" behind reads 20.
 *
 * Every accepted point is checked the same way, away from the timer instants
 * (where which Newton iterate the read precedes is the tool's): "none" on
 * (0, 1), "10" on (1, 2), "20" on (2, 3), "30" after 3.
 *
 *! design   reject_step_held_sformat_string.va
 *! analysis tran 0 3.5
 */

//! lrm 9.3
//! lrm 12.36
//! lrm 3.3
//! lrm 5.10
//! lrm 9.5.3
//! design reject_step_held_sformat_string.va
//! stdout held-sformat: rejected=1 retry_read=10 accepted_ok=1

#include "p03_vpi_analog.h"

#define TOL 1e-9

static vpiHandle vout;
static int rejected, awaiting_retry, checked;
static double rejected_t = -1.0, retry_t = -1.0;

static double code(void)
{
  if (vout == NULL) vout = p03_quantity("reject_step_held_sformat_string.probe", vpiPotential);
  return p03_real_of(vout, NULL);
}

/* The text an accepted point at `t` holds, as its code; -2 at a timer instant. */
static double want_at(double t)
{
  double k = floor(t + 0.5);
  if (fabs(t - k) < TOL) return -2.0;
  if (t < 1.0) return 0.0;
  if (t < 2.0) return 10.0;
  if (t < 3.0) return 20.0;
  return 30.0;
}

static PLI_INT32 on_convergence(p_cb_data cb)
{
  double t = vpi_get_analog_time();
  (void)cb;
  if (awaiting_retry) {
    P03_CHECK(t > 1.0 + TOL && t < rejected_t - TOL,
              "12.36/8.4.7: the retry after rejecting t=%.17g is at t=%.17g, "
              "not inside (1, %.17g)", rejected_t, t, rejected_t);
    P03_NEAR(code(), 10.0, 1e-9,
             "9.3: the retry reads the string the last accepted firing formatted");
    retry_t = t;
    awaiting_retry = 0;
  }
  if (!rejected && t >= 2.0 - TOL) {
    P03_NEAR(t, 2.0, TOL, "5.10.3.3: the first attempt past t=1 stops at the timer's t=2");
    P03_CHECK(vpi_sim_control(vpiRejectTransientStep, vpi_get_analog_delta()) == 1,
              "12.36: vpiRejectTransientStep failed on a solution awaiting acceptance");
    p03_no_error("vpiRejectTransientStep on an open step");
    rejected = 1;
    rejected_t = t;
    awaiting_retry = 1;
  }
  return 0;
}

static PLI_INT32 on_accepted(p_cb_data cb)
{
  double t = vpi_get_analog_time();
  double want = want_at(t);
  (void)cb;
  if (want < -1.5) return 0;
  P03_NEAR(code(), want, 1e-9, "the held string at an accepted point");
  checked++;
  return 0;
}

static PLI_INT32 on_final(p_cb_data cb)
{
  (void)cb;
  P03_CHECK(rejected == 1, "the plugin never reached t=2 to reject it");
  P03_CHECK(retry_t > 0.0, "12.36: the engine never attempted a point after the rejection");
  P03_CHECK(checked > 0, "no accepted point was checked");
  printf("held-sformat: rejected=%d retry_read=10 accepted_ok=1\n", rejected);
  fflush(stdout);
  return 0;
}

static void after_compile(void)
{
  static s_cb_data cvg_cb, acc_cb, fin_cb;
  cvg_cb.reason = acbConvergenceTest; cvg_cb.cb_rtn = on_convergence;
  acc_cb.reason = acbAcceptedPoint;   acc_cb.cb_rtn = on_accepted;
  fin_cb.reason = acbFinalStep;       fin_cb.cb_rtn = on_final;
  P03_CHECK(vpi_register_cb(&cvg_cb) != NULL, "acbConvergenceTest registration failed");
  P03_CHECK(vpi_register_cb(&acc_cb) != NULL, "acbAcceptedPoint registration failed");
  P03_CHECK(vpi_register_cb(&fin_cb) != NULL, "acbFinalStep registration failed");
}

/* IEEE 1364-2005 26.2.4: a startup routine only registers. */
static void startup(void)
{
  p03_defer(after_compile);
}

void (*vlog_startup_routines[])(void) = { startup, 0 };
