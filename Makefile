
MIRROR=tmp/CPAN-mirror
WWW_FOLDER=tmp/dbedia
LOCATIONS=--mirror-location=${MIRROR} --dbedia-location=${WWW_FOLDER}

# ALL
.PHONY: all
all: update ${WWW_FOLDER}/packagesDetails.json ${WWW_FOLDER}/provides.json compress

.PHONY: update
update:
	touch ${MIRROR}/update-heartbeat
	if [ ${MIRROR}/update-heartbeat -nt ${MIRROR}/update-next ]; then \
		rsync -avm --del --include="*.meta" --include "CHECKSUMS" --include "01mailrc.txt.gz" --include "02packages.details.txt.gz" --include='*/' --exclude='*' gd.tuwien.ac.at::CPAN/ ${MIRROR}/; \
		script/dbedia-cpan-meta2json ${LOCATIONS}; \
		script/dbedia-cpan-checksums2json ${LOCATIONS}; \
		touch --date "12h" ${MIRROR}/update-next; \
	fi

${WWW_FOLDER}/packagesDetails.json: ${MIRROR}/modules/02packages.details.txt.gz
	script/dbedia-cpan-packages2json ${LOCATIONS}

${WWW_FOLDER}/provides.json: ${WWW_FOLDER}/packagesDetails.json
	script/dbedia-cpan-provides ${LOCATIONS}

.PHONY: compress
compress:
	find ${WWW_FOLDER}/ -name '*.json' -exec gzip -f -9 {} \; ; \

# install
.PHONY: install
install: all
	mkdir -p ${DESTDIR}/var/www/dbedia-CPAN
	cp -r ${WWW_FOLDER}/* ${DESTDIR}/var/www/dbedia-CPAN/
	perl -MJSON::XS -le 'print JSON::XS->new->encode({ build_time => time() });' > ${DESTDIR}/var/www/dbedia-CPAN/build.json
	mkdir -p ${DESTDIR}/etc/dbedia/sites-available
	cp etc/dbedia-CPAN.conf ${DESTDIR}/etc/dbedia/sites-available/

# create debian package
.PHONY: deb
deb: all
	debuild -b -us -uc --lintian-opts --no-lintian

# CLEAN
.PHONY: clean distclean
clean:
	touch ${MIRROR}/update-next
	fakeroot debian/rules clean
	rm -rf ${WWW_FOLDER}

distclean:
	rm -rf ${WWW_FOLDER}
	rm -rf ${MIRROR}
	fakeroot debian/rules clean
