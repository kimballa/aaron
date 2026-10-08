// (c) Copyright 2026 Aaron Kimball
//
// Trivial smoke test validating the test harness/Makefile wiring,
// independent of the mock environment (see docs/test-suite.md).

#include "doctest.h"

TEST_CASE("sanity") { CHECK(1 + 1 == 2); }
