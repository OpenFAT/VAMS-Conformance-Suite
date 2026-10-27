/* VAMS-2023 12.36, 9.21.1 and 9.3: a table capture made by a rejected step is
 * not the capture the instance keeps.
 *
 *   9.21.1  "The state of the data source is captured on the first call to the
 *           table model function. Any change after this point is ignored."
 *   9.3     "a call to a such system task or function in an analog block
 *           during an iteration that is rejected should cause no side-effects
 *           on the next iteration."
 *   12.36   "vpiRejectTransientStep -- cause the current analog simulation
 *           time point to be rejected. This operation shall pass one argument
 *           which is the current timestep (delta)."
 *
 * The design (reject_step_table_capture.va) first calls $table_model at the
 * first evaluation past t = 1, on data ys = {0, $abstime}, so a capture made
 * at time t reads V(out) = t/2 ever after.
 *
 * The plugin rejects the first acbConvergenceTest past t = 1, at t_rej: the
 * attempt whose evaluation made the first call. That attempt itself reads its
 * own capture, t_rej/2 (9.21.1: the first call captures and looks up). By 9.3
 * the capture goes with the rejection, so the next evaluation that calls the
 * table makes the first call again, on its own data.
 *
 * WHERE THE TOOL BACKS UP IS ITS OWN. vpiRejectTransientStep passes the delta,
 * not a retry time. Every conforming backup lands strictly before t_rej and
 * after the accepted t = 1, so every evaluation from the rejection on is past
 * t = 1 and calls the table. The plugin records the first ACCEPTED time after
 * the rejection, t_a (any further attempts the tool rejects on its own carry
 * no capture either, by the same 9.3), and asserts there
 *
 *     y == t_a / 2       the capture an accepted point made, and
 *     y != t_rej / 2     not the rejected attempt's (t_a < t_rej);
 *
 * and at every later accepted point y == t_a / 2 still: 9.21.1 ignores the
 * data's later values. A tool that kept the rejected capture reads t_rej/2
 * from t_a on; one that recaptured every call reads t/2.
 *
 *! design   reject_step_table_capture.va
 *! analysis tran 0 3
 */

//! lrm 9.21.1
//! lrm 9.3
//! lrm 12.36
//! design reject_step_table_capture.va
//! stdout table-capture: rejected=1 recaptured=1 held=1

#include "p03_vpi_analog.h"

#define TOL 1e-9

static vpiHandle vout;
static int rejected, awaiting_accept, held_checks;
static double rejected_t = -1.0, accepted_t = -1.0;

static double y(void)
{
  if (vout == NULL) vout = p03_quantity("reject_step_table_capture.probe", vpiPotential);
  return p03_real_of(vout, NULL);
}

static PLI_INT32 on_convergence(p_cb_data cb)
{
  double t = vpi_get_analog_time();
  (void)cb;
  if (!rejected && t > 1.0 + TOL) {
    P03_NEAR(y(), t / 2.0, 1e-9,
             "9.21.1: the attempt that makes the first call reads its own capture");
    P03_CHECK(vpi_sim_control(vpiRejectTransientStep, vpi_get_analog_delta()) == 1,
              "12.36: vpiRejectTransientStep failed on a solution awaiting acceptance");
    p03_no_error("vpiRejectTransientStep on an open step");
    rejected = 1;
    rejected_t = t;
    awaiting_accept = 1;
  }
  return 0;
}

static PLI_INT32 on_accepted(p_cb_data cb)
{
  double t = vpi_get_analog_time();
  (void)cb;
  if (awaiting_accept) {
    P03_CHECK(t > 1.0 + TOL && t < rejected_t - TOL,
              "12.36/8.4.7: the first acceptance after rejecting t=%.17g is at "
              "t=%.17g, not inside (1, %.17g)", rejected_t, t, rejected_t);
    P03_NEAR(y(), t / 2.0, 1e-9,
             "9.3/9.21.1: the first accepted point after the rejection captured its own data");
    P03_CHECK(fabs(y() - rejected_t / 2.0) > 1e-6,
              "9.3: y=%.17g is still the rejected attempt's capture", y());
    accepted_t = t;
    awaiting_accept = 0;
  } else if (accepted_t > 0.0) {
    P03_NEAR(y(), accepted_t / 2.0, 1e-9,
             "9.21.1: a later point reads the capture the accepted point made");
    held_checks++;
  }
  return 0;
}

static PLI_INT32 on_final(p_cb_data cb)
{
  (void)cb;
  P03_CHECK(rejected == 1, "the plugin never saw an attempt past t=1 to reject");
  P03_CHECK(accepted_t > 0.0, "no point was accepted after the rejection");
  P03_CHECK(held_checks > 0, "no accepted point followed the recapture");
  printf("table-capture: rejected=%d recaptured=1 held=1\n", rejected);
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
