/* VAMS-2023 9.5.9 and 12.36: a read made by a rejected step is read again.
 *
 *   9.5.9   "If a file is being read from during an iterative solve and if
 *           that iteration is rejected, then the file pointer is reset to the
 *           file position that it pointed to before the iterative solve
 *           started."
 *   9.3     "a call to a such system task or function in an analog block
 *           during an iteration that is rejected should cause no side-effects
 *           on the next iteration."
 *   12.36   "vpiRejectTransientStep -- cause the current analog simulation
 *           time point to be rejected. This operation shall pass one argument
 *           which is the current timestep (delta)."
 *
 * Before the analysis the plugin writes reject_step_file_read_position.dat,
 * ten distinct integers 10, 20, ..., 100, one per line. The design reads the
 * next one under @(timer(1, 1)) and holds it on V(out).
 *
 * The plugin rejects the first acbConvergenceTest at t >= 2, the timer's
 * t = 2 attempt, and records what that attempt read, v_rej. Whatever the
 * tool's backup point (vpiRejectTransientStep passes the delta, not a retry
 * time), the retry lies in (1, 2), where no timer fires and nothing is read,
 * and the run then solves t = 2 again. By 9.5.9 that solve starts from the
 * position the rejected solve started from, and the design is a pure source,
 * so it reads what the rejected attempt read: the accepted t = 2 reads v_rej,
 * and so does every accepted point up to the next read at t = 3. A tool that
 * left the pointer where the rejected attempt put it reads the NEXT integer,
 * at least v_rej + 10. (How many reads one solve makes is the tool's, so
 * v_rej is recorded, not written down as 20.)
 *
 *! design   reject_step_file_read_position.va
 *! analysis tran 0 2.5
 */

//! lrm 9.5.9
//! lrm 9.5.9:1001
//! lrm 9.3
//! lrm 12.36
//! design reject_step_file_read_position.va
//! stdout file-read: rejected=1 reread=1

#include "p03_vpi_analog.h"

#define TOL 1e-9

static vpiHandle vout;
static int rejected, reread;
static double rejected_t = -1.0, v_rej;

static double value(void)
{
  if (vout == NULL) vout = p03_quantity("reject_step_file_read_position.probe", vpiPotential);
  return p03_real_of(vout, NULL);
}

static PLI_INT32 on_convergence(p_cb_data cb)
{
  double t = vpi_get_analog_time();
  (void)cb;
  if (!rejected && t >= 2.0 - TOL) {
    P03_NEAR(t, 2.0, TOL, "5.10.3.3: the first attempt past t=1 stops at the timer's t=2");
    v_rej = value();
    P03_CHECK(vpi_sim_control(vpiRejectTransientStep, vpi_get_analog_delta()) == 1,
              "12.36: vpiRejectTransientStep failed on a solution awaiting acceptance");
    p03_no_error("vpiRejectTransientStep on an open step");
    rejected = 1;
    rejected_t = t;
  }
  return 0;
}

static PLI_INT32 on_accepted(p_cb_data cb)
{
  double t = vpi_get_analog_time();
  (void)cb;
  if (rejected && t >= 2.0 - TOL) {
    P03_NEAR(value(), v_rej, 1e-9,
             "9.5.9: after the rejection t=2 reads what the rejected attempt read");
    reread++;
  }
  return 0;
}

static PLI_INT32 on_final(p_cb_data cb)
{
  (void)cb;
  P03_CHECK(rejected == 1, "the plugin never reached t=2 to reject it");
  P03_CHECK(reread > 0, "no point at or past t=2 was accepted after the rejection");
  printf("file-read: rejected=%d reread=1\n", rejected);
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

/* IEEE 1364-2005 26.2.4: a startup routine only registers; the input file is
 * the plugin's own, written before the design opens it. */
static void startup(void)
{
  FILE *f = fopen("reject_step_file_read_position.dat", "w");
  int k;
  P03_CHECK(f != NULL, "cannot write reject_step_file_read_position.dat");
  for (k = 1; k <= 10; k++) fprintf(f, "%d\n", 10 * k);
  fclose(f);
  p03_defer(after_compile);
}

void (*vlog_startup_routines[])(void) = { startup, 0 };
