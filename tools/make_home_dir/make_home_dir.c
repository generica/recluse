/*
 * (c) Copyright 2003 -- Frank Kirschner <kirschner@trustsec.de>
 * http://www.trustsec.de/soft/oss/
 *
 * This small program creates the home-directory of the calling user,
 * if it does not exists.
 *
 * make_home_dir needs to have a S-bit for the group, that has write
 * permission to the parent-directory of the home-directories.
 *
 * example setup:
 * All home-directorys are /home/<userid>
 * /home has to be group-writeable by the group, that make_home_dir has:
 *   $ groupadd home
 *   $ chmod g+w /home
 *   $ chgrp home /home
 *   $ gcc -Wall -o /usr/local/sbin/make_home_dir make_home_dir.c
 *   $ chgrp home /usr/local/sbin/make_home_dir
 *   $ chmod g+s /usr/local/sbin/make_home_dir
 *
 * Put the call in /etc/profile (or /etc/login for csh,tcsh)
 * A better place would be /etc/profile.d/makehomedir, if your
 * distribution supports /etc/profile.d/
 *
 * Example for bash, ksh, ash, sh:
 *     if [ ! -d $HOME ]
 *     then
 *         logger Creating new home-directory $HOME
 *         /usr/local/sbin/make_home_dir
 *         status=$?
 *         if [ $status -eq 0 ]
 *         then
 *             cd $HOME
 *             cp -a /etc/skel/. $HOME/.
 *             echo Home directory created
 *         fi
 *     fi
 */

#include <pwd.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#include <sys/vfs.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

int main(int argc, char **argv)
{
    struct passwd *pw;
    struct stat buf;
    int ret, printed;
    int create_fake = 0;

    struct statfs user1, user2;

    char *realhome, *fakehome, realhome1[1024], realhome2[1024], errormsg[2048];

    /* Who are we ? */

    pw = getpwuid(getuid());

    /* Can we stat our home directory (checks real home and the link) */

    if ((ret = stat(pw->pw_dir, &buf)) != 0) {

	/* Prep some useful variables we'll use below */

	printed =
	    snprintf(realhome1, 1024, "%s/%s", "/nfs/user1", pw->pw_name);

	if (printed < (strlen("/nfs/user1/") + strlen(pw->pw_name))) {
	    printf
		("Problem constructing path %s (%d vs %ld) - please report to help@vpac.org !\n", realhome1, printed, (strlen("/nfs/user1/") + strlen(pw->pw_name)));
	    exit(-1);
	}

	printed =
	    snprintf(realhome2, 1024, "%s/%s", "/nfs/user2", pw->pw_name);

	if (printed < (strlen("/nfs/user2/") + strlen(pw->pw_name))) {
	    printf
		("Problem constructing path %s (%d vs %ld) - please report to help@vpac.org !\n", realhome2, printed, (strlen("/nfs/user2/") + strlen(pw->pw_name)));
	    exit(-1);
	}

	/* Stat failed, so now we need to make sure they've not got an existing home directory. */

	if(!stat(realhome1, &buf))
	{
		realhome=realhome1;
		printf("Your home directory already exists, just creating the /home link\n");
		goto link;
	}

	if(!stat(realhome2, &buf))
	{
		realhome=realhome2;
		printf("Your home directory already exists, just creating the /home link\n");
		goto link;
	}

        /* Create fake symlink in alternate partition as well */
        create_fake = 1;

	/* That failed, so lets make our home directory and link */

	/* First we need to know which partition to create on */

	/* Stat both filesystems, error if we get an error */

	if (statfs("/nfs/user1", &user1)) {
	    perror
		("statfs of /nfs/user1 failed - please report to help@vpac.org");
	    exit(-1);
	}

	if (statfs("/nfs/user2", &user2)) {
	    perror
		("statfs of /nfs/user2 failed - please report to help@vpac.org");
	    exit(-1);
	}

	/* Pick the filesystem which has most space */
	/* Assign the other one to fakehome */

	realhome =
	    (user1.f_bfree > user2.f_bfree) ? realhome1 : realhome2;

	fakehome =
	    (user1.f_bfree > user2.f_bfree) ? realhome2 : realhome1;

	/* Create the users home directory */

	ret = mkdir(realhome, 0777);

	if ((ret) && (ret != EEXIST)) {
	    snprintf(errormsg, 2048,
		     "Failed to create %s, please report to help@vpac.org",
		     realhome);
	    perror(errormsg);
	    exit(-1);
	}

	/* Set the ownership of the home directory */

	ret = chown(realhome, -1, getgid());

	if (ret) {
	    snprintf(errormsg, 2048,
		     "Failed to set ownership of %s, please report to help@vpac.org",
		     realhome);
	    perror(errormsg);
	    exit(-1);
	}

	link:

	/* Remove the symlink, ignore if it fails */
	unlink(pw->pw_dir);

	/* Create the symlink from their home directory to the real location */
	ret = symlink(realhome, pw->pw_dir);

	if (ret) {
	    snprintf(errormsg, 2048,
		     "Failed to make link from %s to %s, please report to help@vpac.org",
		     pw->pw_dir, realhome);
	    perror(errormsg);
	    exit(-1);
	}

        if (create_fake == 1) {

		/* Create the symlink on the other filesystem */
		ret = symlink(realhome, fakehome);

		if (ret) {
		    snprintf(errormsg, 2048,
			     "Failed to make link from %s to %s, please report to help@vpac.org",
			     fakehome, realhome);
		    perror(errormsg);
		    exit(-1);
		}
	}

    }

    /* Exit with:
     *     status -1 on fatal error
     *     status 0 on normal creation of home directory for the first time
     *     status 3 on recreation of symlink only
     */

    if (create_fake == 1) {
        exit(0);
    }

    exit(3);

}
