# (c) Copyright 2003 -- Frank Kirschner <kirschner@trustsec.de>
#
# The install-dir of the binary
BIN_DIR=/usr/local/sbin
# The group, that make_home_dir should be started with
GROUP=home
# The parent-directory of all home-directories
HOME_PARENT=/home




SRC=make_home_dir.c
FILE=make_home_dir
DEST=$(BIN_DIR)/$(FILE)

all:	$(FILE)

install: $(FILE)
	cp $(FILE) $(DEST)
	strip $(DEST)
	chgrp $(GROUP) $(DEST)
	chmod g+s $(DEST)

setup:
	groupadd $(GROUP)
	chgrp $(GROUP) $(HOME_PARENT)
	chmod g+w $(HOME_PARENT)

clean:
	rm -f $(FILE)


$(FILE):	$(SRC)
	gcc -Wall -o $@ $<


