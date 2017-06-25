VE_PATH := $(PWD)/.ve/bin:$(PATH)

.PHONY: usage
.DEFAULT_GOAL: usage
usage:
	$(error You need to specify one of: clean | build)

.PHONY: clean
clean:
	rm -rf .ve

.PHONY: build
build: install-virtualenv build-virtualenv

.PHONY: install-virtualenv
install-virtualenv:
	sudo apt-get install -y \
		python-virtualenv \
		python-dev \
		libffi-dev \
		libssl-dev \
		apt-transport-https

.PHONY: build-virtualenv
build-virtualenv: .ve/requirements.txt

.ve/requirements.txt: requirements.txt
	virtualenv .ve --system-site-packages
	. .ve/bin/activate; \
	pip install --upgrade setuptools pip; \
	pip install --upgrade -r requirements.txt; \
	cp requirements.txt .ve/requirements.txt
