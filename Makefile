.PHONY: image install

install:
	cp arpanet /usr/local/bin

image:
	docker build -t binocarlos/arpanet .