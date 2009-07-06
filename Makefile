
MIRROR=tmp/CPAN-mirror
WWW_FOLDER=tmp/dbedia

# ALL
.PHONY: all
all: update ${WWW_FOLDER}/packagesDetails.json ${WWW_FOLDER}/provides.json

.PHONY: update
update:
	touch ${MIRROR}/update-heartbeat
	if [ ${MIRROR}/update-heartbeat -nt ${MIRROR}/update-next ]; then \
		rsync -avm --del --include="*.meta" --include "CHECKSUMS" --include "01mailrc.txt.gz" --include "02packages.details.txt.gz" --include='*/' --exclude='*' gd.tuwien.ac.at::CPAN/ ${MIRROR}/; \
		script/dbedia-cpan-meta2json; \
		script/dbedia-cpan-checksums2json; \
		touch --date "12h" ${MIRROR}/update-next; \
	fi

${WWW_FOLDER}/packagesDetails.json: ${MIRROR}/modules/02packages.details.txt.gz
	script/dbedia-cpan-packages2json

${WWW_FOLDER}/provides.json: ${WWW_FOLDER}/packagesDetails.json
	script/dbedia-cpan-provides


# create debian package
.PHONY: deb
deb: all
	debuild -b -us -uc --lintian-opts --no-lintian

# CLEAN
.PHONY: clean distclean
clean:
	rm -f ${MIRROR}/update

distclean:
	rm -rf mirror/*
