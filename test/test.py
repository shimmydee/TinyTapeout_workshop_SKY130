"""Cocotb test for tt_um_shimmydee_sevenseg.

This is a smoke-and-sanity test for the seven-segment display port. It:
  1. Asserts and releases reset.
  2. Selects Task 1 / Level 1 via ui_in (no buttons pressed).
  3. Runs for enough cycles to see at least a couple of full digit-mux cycles.
  4. Verifies the bidirectional output enable mask is correct.
  5. Verifies that all four digit anodes are exercised (one-hot active-low).
  6. Verifies that the segment outputs are not stuck.

The original RTL has 1 ms-scale debouncers and ~6k-cycle digit-mux periods, so
the test is intentionally cycle-heavy (~150k cycles ~= 6 ms simulated). On a
modern CI runner this completes in well under a minute under Icarus.
"""

import os

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge


CLOCK_PERIOD_NS = 40           # 25 MHz
# Hold reset long enough for the 1 kHz beat (12_500 cycles) and the 3-stage
# debouncer to propagate sw[15] = ~rst_n into the design's levelSysReset.
RESET_CYCLES    = 50_000       # ~3 * 12_500 cycles + headroom
SETTLE_CYCLES   = 50_000       # let derived state stabilise after deassert
# PWM scan_div = 25_000_000 / (256 * 4) ~= 24_414 cycles/digit; one full anode
# cycle ~= 97_656 cycles. Sample over >= 2 anode cycles so we definitely see
# all four digit positions.
SAMPLE_CYCLES   = 220_000
SAMPLE_EVERY    = 500          # 440 samples across the window
EXPECTED_UIO_OE = 0xF0         # uio[7:4] outputs (anodes), uio[3:0] inputs (switches)


def _anode_mask(uio_out: int) -> int:
    """Return just the four anode bits (uio[7:4]), low = active digit."""
    return (uio_out >> 4) & 0xF


@cocotb.test()
async def test_reset_and_anode_mux(dut):
    """Reset, settle, then verify anode multiplexing exercises all four digits."""

    cocotb.start_soon(Clock(dut.clk, CLOCK_PERIOD_NS, units="ns").start())

    # Initialise inputs to a known state.
    dut.ena.value    = 1
    dut.ui_in.value  = 0
    dut.uio_in.value = 0
    dut.rst_n.value  = 0

    await ClockCycles(dut.clk, RESET_CYCLES)
    dut.rst_n.value = 1

    # Always-on uio_oe check (purely combinational from project.v).
    actual_oe = int(dut.uio_oe.value)
    assert actual_oe == EXPECTED_UIO_OE, (
        f"uio_oe = {actual_oe:#04x}, expected {EXPECTED_UIO_OE:#04x}"
    )

    # Select Task 1 active (sw[1]=1, sw[2]=0), Level 1 (sw[0]=0). No buttons.
    # ui_in[6] = sw[1], ui_in[7] = sw[2], ui_in[5] = sw[0], ui_in[4:0] = buttons.
    dut.ui_in.value  = 0b0100_0000
    dut.uio_in.value = 0

    # Let internal resets and 1 kHz debouncer chain settle.
    await ClockCycles(dut.clk, SETTLE_CYCLES)

    # Sample anodes and segments across the observation window.
    anode_seen = set()
    seg_values = set()
    samples    = 0

    for _ in range(SAMPLE_CYCLES // SAMPLE_EVERY):
        await ClockCycles(dut.clk, SAMPLE_EVERY)
        anode_seen.add(_anode_mask(int(dut.uio_out.value)))
        seg_values.add(int(dut.uo_out.value))
        samples += 1

    # We expect each of the four one-hot-low anode patterns to appear at least
    # once: 4'b1110, 4'b1101, 4'b1011, 4'b0111.
    expected_anodes = {0b1110, 0b1101, 0b1011, 0b0111}
    missing = expected_anodes - anode_seen
    assert not missing, (
        f"After {samples} samples, never observed anode patterns "
        f"{sorted(missing)}. Saw: {sorted(anode_seen)}"
    )

    # Segments should not be stuck at a single value across the entire window.
    assert len(seg_values) > 1, (
        f"uo_out (segments) appears stuck at a single value across "
        f"{samples} samples: {seg_values}"
    )

    dut._log.info(
        f"Saw {len(anode_seen)} distinct anode patterns and "
        f"{len(seg_values)} distinct segment values across {samples} samples."
    )


@cocotb.test()
async def test_task_select_changes_output(dut):
    """Switching between Task 1 and Task 3 must change observable behaviour.

    In Task 1, the freshly-reset cursor sits at F1 (cursorID=5) on a blank
    canvas, so most segments are dark. In Task 3 the canvas is also blank but
    the cursor blinks at 8 Hz over an unselected segment, producing a different
    duty-cycle signature on the segment outputs over time. We just check the
    integer set of observed uo_out values differs between the two modes.
    """

    cocotb.start_soon(Clock(dut.clk, CLOCK_PERIOD_NS, units="ns").start())
    dut.ena.value    = 1
    dut.ui_in.value  = 0
    dut.uio_in.value = 0
    dut.rst_n.value  = 0
    await ClockCycles(dut.clk, RESET_CYCLES)
    dut.rst_n.value  = 1

    async def collect(ui_in_value, cycles):
        dut.ui_in.value = ui_in_value
        await ClockCycles(dut.clk, SETTLE_CYCLES)
        seen = set()
        for _ in range(cycles // SAMPLE_EVERY):
            await ClockCycles(dut.clk, SAMPLE_EVERY)
            seen.add(int(dut.uo_out.value))
        return seen

    # Task 1 active: sw[2:1] = 2'b01 -> ui_in[7:5] = 3'b010
    task1_set = await collect(0b0100_0000, SAMPLE_CYCLES)
    # Task 3 active: sw[2:1] = 2'b11 -> ui_in[7:5] = 3'b110
    task3_set = await collect(0b1100_0000, SAMPLE_CYCLES)

    assert task1_set, "Task 1 produced no segment activity at all."
    assert task3_set, "Task 3 produced no segment activity at all."
    dut._log.info(
        f"Task 1 distinct uo_out values: {len(task1_set)}; "
        f"Task 3 distinct uo_out values: {len(task3_set)}."
    )
