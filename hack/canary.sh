#!/bin/sh
set -eu

# The canary: the toolchain's own test suite is the consumer gate. Red here
# means the candidate index never publishes: the stage does not advance,
# nothing mints, and consumers never see the state.
#
# The POC gate is forge-factory's unit stage: fast, and it exercises the
# tool every consumer of this register runs. The full bar is every
# toolchain member's test-all; run that where minutes are cheap.

ROOT="${1:-..}"

cd "$ROOT/forge-factory"
forge test run unit
