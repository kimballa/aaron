
# Static analysis (bug-finding, beyond style) with clang-tidy; config: .clang-tidy.
# Runs on the host-clean subset only (SUT_SRCS): it reuses the host test flags and mock Arduino
# environment. Requires clang-tidy (e.g. `sudo apt install clang-tidy`).
CLANG_TIDY := clang-tidy

lint-tidy:
	$(CLANG_TIDY) --warnings-as-errors='*' $(SUT_SRCS) -- $(TEST_CXXFLAGS)

.PHONY: lint-tidy
