REBAR ?= ./rebar

IS_REBAR3:=$(shell expr `$(REBAR) --version | awk -F '[ .]' '/rebar / {print $$2}'` '>=' 3)

all: src

src:
	$(REBAR) get-deps
	$(REBAR) compile

clean:
	$(REBAR) clean

distclean: clean
	rm -rf _build
	rm -rf deps
	rm -rf ebin
	rm -rf dialyzer

test: all
	$(REBAR) eunit

xref: all
	$(REBAR) xref

ifeq "$(IS_REBAR3)" "1"
dialyzer:
	$(REBAR) dialyzer
else
deps := $(wildcard deps/*/ebin)

APPS=kernel stdlib erts public_key crypto asn1

dialyzer/erlang.plt:
	@mkdir -p dialyzer
	@dialyzer --build_plt --output_plt dialyzer/erlang.plt \
	-o dialyzer/erlang.log --apps $(APPS); \
	status=$$? ; if [ $$status -ne 2 ]; then exit $$status; else exit 0; fi

# dialyzer/deps.plt:
# 	@mkdir -p dialyzer
# 	@dialyzer --build_plt --output_plt dialyzer/deps.plt \
# 	-o dialyzer/deps.log $(deps); \
# 	status=$$? ; if [ $$status -ne 2 ]; then exit $$status; else exit 0; fi

dialyzer/pkix.plt:
	@mkdir -p dialyzer
	@dialyzer --build_plt --output_plt dialyzer/pkix.plt \
	-o dialyzer/pkix.log ebin; \
	status=$$? ; if [ $$status -ne 2 ]; then exit $$status; else exit 0; fi

erlang_plt: dialyzer/erlang.plt
	@dialyzer --plt dialyzer/erlang.plt --check_plt -o dialyzer/erlang.log; \
	status=$$? ; if [ $$status -ne 2 ]; then exit $$status; else exit 0; fi

# deps_plt: dialyzer/deps.plt
# 	@dialyzer --plt dialyzer/deps.plt --check_plt -o dialyzer/deps.log; \
# 	status=$$? ; if [ $$status -ne 2 ]; then exit $$status; else exit 0; fi

pkix_plt: dialyzer/pkix.plt
	@dialyzer --plt dialyzer/pkix.plt --check_plt -o dialyzer/pkix.log; \
	status=$$? ; if [ $$status -ne 2 ]; then exit $$status; else exit 0; fi

dialyzer: erlang_plt pkix_plt #deps_plt pkix_plt
	@dialyzer --plts dialyzer/*.plt --no_check_plt \
	--get_warnings -o dialyzer/error.log ebin; \
	status=$$? ; if [ $$status -ne 2 ]; then exit $$status; else exit 0; fi
endif

check-syntax:
	gcc -o nul -S ${CHK_SOURCES}

.PHONY: clean src test all dialyzer erlang_plt pkix_plt #deps_plt
