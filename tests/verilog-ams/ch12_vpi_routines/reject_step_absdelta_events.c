/* VAMS-2023 8.4.7 and 12.36: absdelta events of a rejected solution that the
 * digital engine has not consumed are rejected with it.
 *
 *   8.4.7   "absdelta analog to digital events can occur at times
 *           interpolated between two analog solution times (that of the last
 *           analog solution and the next analog solution ). These events are
 *           associated with the next analog solution. If the next analog
 *           solution is rejected, the absdelta events associated with that
 *           solution, that have not be consumed by the digital engine, are
 *           rejected (see 8.4.6)."
 *   5.10.3.4 an event "When the expr value changes in absolute value by more
 *           than delta, relative to the previous absdelta() event", placed
 *           between the interpolated changes of (delta - expr_tol) and
 *           (delta + expr_tol); and one "During initialization".
 *   12.36   "vpiRejectTransientStep -- cause the current analog simulation
 *           time point to be rejected."
 *
 * V(a) ramps 0 to 5 V over the run, so the events a conforming tool delivers
 * are the initialization event at 0 V and one each 0.25 V on, every one
 * 0.25 V +/- 1 mV (expr_tol) past the one before. The plugin rejects the first
 * acbConvergenceTest past each of several marks (0.4 ms, then 0.7 ms after
 * each rejection), so several solutions whose interval spans an absdelta
 * level are thrown away with their interpolated events. Where the tool backs
 * up is its own (vpiRejectTransientStep passes the delta, not a retry time);
 * the re-solve interpolates the level again from the previous event, so the
 * delivered sequence is the same whatever the backup.
 *
 * At cbEndOfSimulation, with the digital queue run out:
 *
 *   - bad == 0: no delivered event repeats a level (a rejected solution's
 *     unconsumed event kept AND re-generated reads a step near 0) or skips
 *     one (a rejected event the re-solve never placed again);
 *   - k in [20, 21]: the initialization event, the 19 levels 0.25 .. 4.75 V,
 *     and the 5 V level if the tool places it at or before tstop. A tool that
 *     dropped the re-generated events reads fewer.
 *
 *! design   reject_step_absdelta_events.va
 *! analysis tran 0 5m
 */

//! lrm 8.4.7
//! lrm 8.4.7:1004
//! lrm 8.4.6
//! lrm 12.36
//! design reject_step_absdelta_events.va
//! stdout absdelta-reject: levels_ok=1 count_ok=1

#include "p03_vpi_analog.h"

static int rejections;
static double mark = 0.4e-3;

static int read_int(const char *name)
{
  s_vpi_value v;
  vpiHandle h = vpi_handle_by_name((PLI_BYTE8 *)name, NULL);
  P03_CHECK(h != NULL, "no variable %s", name);
  v.format = vpiIntVal;
  vpi_get_value(h, &v);
  p03_no_error("vpi_get_value(vpiIntVal)");
  return (int)v.value.integer;
}

static PLI_INT32 on_convergence(p_cb_data cb)
{
  double t = vpi_get_analog_time();
  (void)cb;
  if (t >= mark && t < 4.5e-3) {
    P03_CHECK(vpi_sim_control(vpiRejectTransientStep, vpi_get_analog_delta()) == 1,
              "12.36: vpiRejectTransientStep failed on a solution awaiting acceptance");
    p03_no_error("vpiRejectTransientStep on an open step");
    rejections++;
    mark = t + 0.7e-3;
  }
  return 0;
}

static PLI_INT32 on_end(p_cb_data cb)
{
  int k = read_int("reject_step_absdelta_events.k");
  int bad = read_int("reject_step_absdelta_events.bad");
  (void)cb;
  P03_CHECK(rejections >= 3, "the plugin rejected only %d solutions", rejections);
  P03_CHECK(bad == 0, "8.4.7: %d delivered absdelta events are not one level past "
            "the event before", bad);
  P03_CHECK(k >= 20 && k <= 21, "5.10.3.4: %d absdelta events on a 0..5 V ramp, "
            "want 20 or 21", k);
  printf("absdelta-reject: levels_ok=1 count_ok=1\n");
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
