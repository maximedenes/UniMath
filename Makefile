# -*- makefile-gmake -*-
UMAKEFILES += Makefile
ifeq ($(shell test -f build/Makefile-configuration && echo yes),yes)
UMAKEFILES += build/Makefile-configuration
include build/Makefile-configuration
endif
############################################
# The packages, listed in reverse order by dependency:
PACKAGES += Ktheory
PACKAGES += RezkCompletion
PACKAGES += Foundations
############################################
BUILD_COQ ?= yes
ifeq ($(BUILD_COQ),yes)
COQBIN=sub/coq/bin/
all: build-coq
endif
-include build/CoqMakefile.make
everything: TAGS all html install
OTHERFLAGS += -indices-matter
UniMath/Foundations/hlevel2/algebra1b.vo : OTHERFLAGS += -no-sharing
ifeq ($(VERBOSE),yes)
OTHERFLAGS += -verbose
endif
# later: see exactly which files need -no-sharing
NO_SHARING = yes
ifeq ($(NO_SHARING),yes)
OTHERFLAGS += -no-sharing
endif
# TIME = time
COQDOC := $(COQDOC) -utf8
COQC = $(TIME) $(COQBIN)coqc
COQDEFS := --language=none -r '/^[[:space:]]*\(Axiom\|Theorem\|Class\|Instance\|Let\|Ltac\|Definition\|Lemma\|Record\|Remark\|Structure\|Fixpoint\|Fact\|Corollary\|Let\|Inductive\|Coinductive\|Notation\|Proposition\|Module[[:space:]]+Import\|Module\)[[:space:]]+\([[:alnum:]'\''_]+\)/\2/'
TAGS : $(VFILES); etags $(COQDEFS) $^
install:all
lc:; wc -l $(VFILES)
lcp:; for i in $(PACKAGES) ; do echo ; echo ==== $$i ==== ; for f in $(VFILES) ; do echo "$$f" ; done | grep "UniMath/$$i" | xargs wc -l ; done
wc:; wc -w $(VFILES)
describe:; git describe --dirty --long --always --abbrev=40 --all
publish-dan:html; rsync -ai html/. u00:public_html/UniMath/.
.coq_makefile_input: $(patsubst %, UniMath/%/.package/files, $(PACKAGES)) $(UMAKEFILES)
	@ echo making $@ ; ( \
	echo '# -*- makefile-gmake -*-' ;\
	echo ;\
	echo '# DO NOT EDIT THIS FILE!' ;\
	echo '# It is made by automatically (by code in Makefile)' ;\
	echo ;\
	echo '-R UniMath UniMath' ;\
	echo ;\
	for i in $(PACKAGES) ;\
	do sed "s=^=UniMath/$$i/=" < UniMath/$$i/.package/files ;\
	done ;\
	echo ;\
	echo '# Local ''Variables:' ;\
	echo '# compile-command: "sub/coq/bin/coq_makefile -f .coq_makefile_input -o CoqMakefile.make.tmp && mv CoqMakefile.make.tmp build/CoqMakefile.make"' ;\
	echo '# End:' ;\
	) >$@
# the '' above prevents emacs from mistaking the lines above as providing local variables when visiting this file
build/CoqMakefile.make: .coq_makefile_input
	$(COQBIN)coq_makefile -f .coq_makefile_input -o .coq_makefile_output
	mv .coq_makefile_output $@

clean:clean2
distclean:cleanconfig distclean_coq
clean2:
	rm -f .coq_makefile_output build/CoqMakefile.make
	find UniMath \( -name .\*.aux \) -delete
distclean_coq:
	- $(MAKE) -C sub/coq distclean
cleanconfig:
	rm -f build/Makefile-configuration

# building coq:
ifeq ($(BUILD_COQ),yes)
export PATH:=$(shell pwd)/sub/coq/bin:$(PATH)
build-coq: sub/coq/configure sub/coq/config/coq_config.ml sub/coq/bin/coqc
sub/coq/configure:
	git submodule update --init sub/coq
sub/coq/config/coq_config.ml: sub/coq/configure.ml
	cd sub/coq && ./configure -coqide no -opt -no-native-compiler -with-doc no -annotate -debug -local
sub/coq/bin/coqc:
	make -C sub/coq KEEP_ML4_PREPROCESSED=true VERBOSE=true READABLE_ML4=yes coqlight
endif
