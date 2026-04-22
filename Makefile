.PHONY: install uninstall lint doctor

install:
	./install.sh

uninstall:
	./uninstall.sh

lint:
	shellcheck -x install.sh uninstall.sh \
	  plugin/docker-k8s.2s.sh \
	  lib/common.sh lib/state.sh lib/toggle.sh \
	  bin/toggle bin/restart-docker bin/doctor.sh

doctor:
	./bin/doctor.sh
