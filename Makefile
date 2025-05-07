######################################################################
#
# DESCRIPTION: Make Verilator model and run coverage
#
# This calls the object directory makefile.  That allows the objects to
# be placed in the "current directory" which simplifies the Makefile.
#
# This file is placed under the Creative Commons Public Domain, for
# any use, without warranty, 2020 by Wilson Snyder.
# SPDX-License-Identifier: CC0-1.0
#
######################################################################

ifneq ($(words $(CURDIR)),1)
 $(error Unsupported: GNU Make cannot build in directories containing spaces, build elsewhere: '$(CURDIR)')
endif

# This example started with the Verilator example files.
# Please see those examples for commented sources, here:
# https://github.com/verilator/verilator/tree/master/examples

######################################################################
# Set up variables

GENHTML = genhtml
TOP_NAME ?= softmax
SRC_DIR = ./src
SIM_DIR = ./sim
# SRC_FILE := $(shell find $(SRC_DIR) -name '*.vh') $(shell find $(SRC_DIR) -name '*.svh') $(shell find $(SRC_DIR) -name '*.v') $(shell find $(SRC_DIR) -name '*.sv')
SRC_FILE := $(shell find $(SRC_DIR) -name '*.v')

# If $VERILATOR_ROOT isn't in the environment, we assume it is part of a
# package install, and verilator is in your path. Otherwise find the
# binary relative to $VERILATOR_ROOT (such as when inside the git sources).
ifeq ($(VERILATOR_ROOT),)
VERILATOR = verilator
else
export VERILATOR_ROOT
VERILATOR = $(VERILATOR_ROOT)/bin/verilator
endif

VERILATOR_FLAGS =
# Generate C++ in executable form
VERILATOR_FLAGS += --cc --exe
# Generate makefile dependencies (not shown as complicates the Makefile)
#VERILATOR_FLAGS += -MMD
# Optimize
# VERILATOR_FLAGS += --x-assign 0
# Warn abount lint issues; may not want this on less solid designs
VERILATOR_FLAGS += -Wall

VERILATOR_FLAGS += -Wno-CASEINCOMPLETE -Wno-UNUSED -Wno-WIDTH -Wno-STMTDLY -Wno-REDEFMACRO
# Make waveforms
VERILATOR_FLAGS += --trace --trace-structs
# Check SystemVerilog assertions
VERILATOR_FLAGS += --assert
# Generate coverage analysis
# VERILATOR_FLAGS += --coverage
# Run make to compile model, with as many CPUs as are free
VERILATOR_FLAGS += --build 
# Run Verilator in debug mode
#VERILATOR_FLAGS += --debug
# Add this trace to get a backtrace in gdb
#VERILATOR_FLAGS += --gdbbt
VERILATOR_FLAGS += -j `nproc`


VERILATOR_FLAGS += -I$(SRC_DIR)
VERILATOR_FLAGS += --top $(TOP_NAME)

TB_FILE = $(SIM_DIR)/main_$(TOP_NAME).cpp

######################################################################
# Build the model

obj_dir/V$(TOP_NAME): src/* $(SRC_FILE)
	@echo "-- VERILATE ${TOP_NAME} ----------------"
	$(VERILATOR) --version
	$(VERILATOR) $(VERILATOR_FLAGS) $(SRC_FILE) ${TB_FILE}

######################################################################
# Run verilator

default: run

run: obj_dir/V$(TOP_NAME)
	@echo
	@echo "-- RUN ---------------------"
	@rm -rf logs
	@mkdir -p logs
	obj_dir/V$(TOP_NAME)
	@echo
	@echo "-- DONE --------------------"


######################################################################
# Other targets

show-config:
	$(VERILATOR) -V

genhtml:
	@echo "-- GENHTML --------------------"
	@echo "-- Note not installed by default, so not in default rule"
	$(GENHTML) logs/coverage.info --output-directory logs/html

maintainer-copy::
clean mostlyclean distclean maintainer-clean::
	-rm -rf obj_dir logs *.log *.dmp *.vpd core