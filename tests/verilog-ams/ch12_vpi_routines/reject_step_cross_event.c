/* VAMS-2023 8.4.7 and 12.36: an A2D cross() event goes with the rejected
 * solution that produced it, while the digital engine has not consumed it.
 *
 *   8.4.7   "Certain analog events (above, cross, initial_step, and
 *           final_step) cause an analog solution of the time where they
 *           occur. Such events are associated with the solution that produced
 *           them until they are consumed by the digital engine. Until then,
 *           they can be rejected along with the solution, if it is rejected."
 *   12.36   "vpiRejectTransientStep -- cause the current analog simulation
 *           time point to be rejected."
 *   12.31.3 acbConvergenceTest: "Prior acceptance of the analog solution for
 *           the given time".
 *
 * The design's one rising crossing is at 2.5 ms, and the digital process
 * counts its events in `n`. The plugin rejects the first acbConvergenceTest
 * at t >= 2.5 ms (minus the cross()'s 1 ps time_tol): the solution the
 * crossing produced, or one past it, before it is accepted. At that moment it
 * reads `n` through vpi_get_value():
 *
 *   - n == 0: the digital engine has not consumed the event, so by 8.4.7 it
 *     is rejected with the solution. The re-solve finds the same crossing and
 *     produces it again, so the run ends with n == 1 exactly. A tool that
 *     kept the rejected solution's event AND delivered the re-solve's counts
 *     the one crossing twice.
 *   - n == 1: the tool handed the event over before acceptance. The sentence
 *     covers only unconsumed events, so the plugin asserts nothing more than
 *     that the crossing reached the digital process.
 *
 * Where the tool backs up is its own (vpiRejectTransientStep passes the delta,
 * not a retry time); every backup re-crosses 2.5 V once, which is all the
 * count depends on. The count is read at cbEndOfSimulation, after the digital
 * engine has run out its queue.
 *
 *! design   reject_step_cross_event.va
 *! analysis tran 0 5m
 */

//! lrm 8.4.7
//! lrm 8.4.7:1003
//! lrm 12.36
//! design reject_step_cross_event.va
//! stdout cross-reject: rejected=1 crossing_delivered=1

#include "p03_vpi_analog.h"

#define T_CROSS 2.5e-3

static int rejected, n_at_reject = -1;

static int read_n(void)
{
  s_vpi_value v;
  vpiHandle h = vpi_handle_by_name((PLI_BYTE8 *)"reject_step_cross_event.n", NULL);
  P03_CHECK(h != NULL, "no variable reject_step_cross_event.n");
  v.format = vpiIntVal;
  vpi_get_value(h, &v);
  p03_no_error("vpi_get_value(n, vpiIntVal)");
  return (int)v.value.integer;
}

static PLI_INT32 on_convergence(p_cb_data cb)
{
  double t = vpi_get_analog_time();
  (void)cb;
  if (!rejected && t >= T_CROSS - 1e-12) {
    n_at_reject = read_n();
    P03_CHECK(n_at_reject == 0 || n_at_reject == 1,
              "one crossing, but n=%d before its solution was accepted", n_at_reject);
    P03_CHECK(vpi_sim_control(vpiRejectTransientStep, vpi_get_analog_delta()) == 1,
              "12.36: vpiRejectTransientStep failed on a solution awaiting acceptance");
    p03_no_error("vpiRejectTransientStep on an open step");
    rejected = 1;
  }
  return 0;
}

static PLI_INT32 on_end(p_cb_data cb)
{
  int n = read_n();
  (void)cb;
  P03_CHECK(rejected == 1, "the run never reached the crossing to reject it");
  if (n_at_reject == 0)
    P03_CHECK(n == 1, "8.4.7: the crossing's unconsumed event was rejected with its "
              "solution and found again once, but the digital process counted %d", n);
  else
    P03_CHECK(n >= 1, "the crossing never reached the digital process (n=%d)", n);
  printf("cross-reject: rejected=%d crossing_delivered=1\n", rejected);
  fflush(stdout);
  return 0;
}

static void after_compile(void)
{
  static s_cb_data cvg_cb;
  cvg_cb.reason = acbConvergenceTest; cvg_cb.cb_rtn = on_convergence;
  P03_CHECK(vpi_register_cb(&cvg_cb) != NULL, "acbConvergenceTest registration failed");
}

/* IEEE 1364-2005 26.2.4: a startup routine may register cbEndOfSimulation
 * itself; the analog callback waits for cbEndOfCompile. */
static void startup(void)
{
  static s_cb_data end_cb;
  end_cb.reason = cbEndOfSimulation; end_cb.cb_rtn = on_end;
  P03_CHECK(vpi_register_cb(&end_cb) != NULL, "cbEndOfSimulation registration failed");
  p03_defer(after_compile);
}

void (*vlog_startup_routines[])(void) = { startup, 0 };
