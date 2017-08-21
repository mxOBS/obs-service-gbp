DESTDIR ?=
PREFIX ?= /usr

all:

install:
	install -v -m755 -d $(DESTDIR)$(PREFIX)/lib/obs/service
	install -v -m755 gbp.sh $(DESTDIR)$(PREFIX)/lib/obs/service/gbp
	install -v -m644 gbp.service $(DESTDIR)$(PREFIX)/lib/obs/service
