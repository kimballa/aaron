##### Host unit testing #####
# Compiles the host-clean subset of src/ (SUT_SRCS) against the mock Arduino environment in
# test/arduino-mock-env/ and runs the doctest suite. Add every host-testable .cpp to SUT_SRCS.
HOST_CXX    := g++
TEST_DIR    := test
MOCK_DIR    := $(TEST_DIR)/arduino-mock-env
TEST_BUILD  := build/test

# -isystem makes the mock headers shadow any real Arduino.h AND silences warnings originating in
# mock/framework headers while keeping full warnings on firmware. Deliberately NOT
# -fno-exceptions/-fno-rtti: the firmware uses neither, but doctest wants them.
# Match -std to the firmware's CXX_STD.
TEST_CXXFLAGS := -std={{CPP_STD}} -g -O0 \
  -isystem $(MOCK_DIR) -Isrc -I$(TEST_DIR) \
  -Wall -Wextra -Wshadow -Wconversion -Wno-unused-parameter -DUNIT_TEST

# Host-clean source files (no hardware registers / ISRs / inline asm; or gated behind #ifdef
# for the target MCU with a host stub in the #else branch).
SUT_SRCS :=

# Host-only stand-ins for globals defined in non-host-clean files (e.g. test/pins-stub.cpp).
SUT_STUB_SRCS := $(wildcard $(TEST_DIR)/*-stub.cpp)

MOCK_SRCS := $(wildcard $(MOCK_DIR)/*.cpp)
TEST_SRCS := $(wildcard $(TEST_DIR)/*_test.cpp) $(TEST_DIR)/test_main.cpp

compile-test:
	$(HOST_CXX) $(TEST_CXXFLAGS) -fsyntax-only $(MOCK_SRCS) $(SUT_SRCS) $(SUT_STUB_SRCS) $(TEST_SRCS)

$(TEST_BUILD)/runner: $(MOCK_SRCS) $(SUT_SRCS) $(SUT_STUB_SRCS) $(TEST_SRCS) | $(TEST_BUILD)
	$(HOST_CXX) $(TEST_CXXFLAGS) -o $@ $^

$(TEST_BUILD):
	mkdir -p $@

test: $(TEST_BUILD)/runner
	$<

.PHONY: compile-test test

