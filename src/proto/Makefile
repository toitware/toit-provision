# Copyright (C) 2023 Toitware ApS.
# Use of this source code is governed by a Zero-Clause BSD license that can
# be found in the EXAMPLES_LICENSE file.

PROTOC_GEN_TOIT_PATH := `go env GOPATH`/bin/protoc-gen-toit

PROTO_FLAGS ?=
PROTO_SOURCE_DIR := .
PROTO_OUT_DIR := .
TOIT_LIBRARY_REDIRECTION_FLAGS ?=
ifneq ($(TOIT_LIBRARY_REDIRECTIONS),)
TOIT_LIBRARY_REDIRECTION_FLAGS := import_library=$(TOIT_LIBRARY_REDIRECTIONS)
endif
TOIT_OPT_FLAGS := "constructor_initializers=1;$(TOIT_LIBRARY_REDIRECTION_FLAGS)"

PROTO_SOURCES := $(shell find $(PROTO_SOURCE_DIR) -name '*.proto')
PROTO_TARGETS := $(PROTO_SOURCES:$(PROTO_SOURCE_DIR)/%.proto=$(PROTO_OUT_DIR)/%_pb.toit)

all: protobuf

protobuf: $(PROTO_TARGETS)

$(PROTO_OUT_DIR)/%_pb.toit: $(PROTO_SOURCE_DIR)/%.proto $(PROTO_OUT_DIR)
	protoc --plugin=protoc-gen-toit=$(PROTOC_GEN_TOIT_PATH) $< --toit_out=$(PROTO_OUT_DIR) --toit_opt=$(TOIT_OPT_FLAGS) $(PROTO_FLAGS)

$(PROTO_OUT_DIR):
	mkdir -p $(PROTO_OUT_DIR)

clean:
	rm -f $(PROTO_OUT_DIR)/*_pb.toit

.PHONY: all protobuf clean
