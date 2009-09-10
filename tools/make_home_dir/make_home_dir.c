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
 * see README for usage
 * 
 */

/* Exit with:
 *     status -1 on fatal error
 *     status 0 on normal creation of home directory for the first time
 *     status 1 on everything fine, nothing done at all
 *     status 3 on recreation of symlink only
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

int create_real_link(char *realhome, char *home) {

	int ret;
	char errormsg[2048];

	/* Remove the symlink, ignore if it fails */
	unlink(home);

	/* Create the symlink from their home directory to the real location */
	ret = symlink(realhome, home);

	if (ret) {
		snprintf(errormsg, 2048, "Failed to make link from %s to %s, please report to help@vpac.org", home, realhome);
		perror(errormsg);
		exit(-1);
	}

	return 0;

}

int main(int argc, char **argv)
{
	struct passwd *pw;
	struct stat buf;
	int ret, printed;

	struct statfs user1, user2;

	char *realhome, *fakehome, nfsuser1[1024], nfsuser2[1024], errormsg[2048];

	/* Who are we ? */

	pw = getpwuid(getuid());

	/* Can we stat our home directory (checks real home and the link) */

	if ((ret = stat(pw->pw_dir, &buf)) == 0) {
		/* All is fine, bye */
		exit(1);
	}

	/* Prep some useful variables we'll use below */

	printed = snprintf(nfsuser1, 1024, "%s/%s", "/nfs/user1", pw->pw_name);

	if (printed < (strlen("/nfs/user1/") + strlen(pw->pw_name))) {
		printf("Problem constructing path %s (%d vs %ld) - please report to help@vpac.org !\n", nfsuser1, printed, (strlen("/nfs/user1/") + strlen(pw->pw_name)));
		exit(-1);
	}

	printed = snprintf(nfsuser2, 1024, "%s/%s", "/nfs/user2", pw->pw_name);

	if (printed < (strlen("/nfs/user2/") + strlen(pw->pw_name))) {
		printf("Problem constructing path %s (%d vs %ld) - please report to help@vpac.org !\n", nfsuser2, printed, (strlen("/nfs/user2/") + strlen(pw->pw_name)));
		exit(-1);
	}

	/* Stat failed, so now we need to make sure they've not got an existing home directory. */

	if(!stat(nfsuser1, &buf))
	{
		printf("Your home directory already exists, just creating the /home link\n");
		create_real_link(nfsuser1, pw->pw_dir);
		exit(3);
	}

	if(!stat(nfsuser2, &buf))
	{
		printf("Your home directory already exists, just creating the /home link\n");
		create_real_link(nfsuser2, pw->pw_dir);
		exit(3);
	}

	/* That failed, so lets make our home directory and link */

	/* First we need to know which partition to create on */

	/* Stat both filesystems, error if we get an error */

	if (statfs("/nfs/user1", &user1)) {
		perror("statfs of /nfs/user1 failed - please report to help@vpac.org");
		exit(-1);
	}

	if (statfs("/nfs/user2", &user2)) {
		perror("statfs of /nfs/user2 failed - please report to help@vpac.org");
		exit(-1);
	}

	/* Pick the filesystem which has most space */
	/* Assign the other one to fakehome */

	realhome = (user1.f_bfree > user2.f_bfree) ? nfsuser1 : nfsuser2;
	fakehome = (user1.f_bfree > user2.f_bfree) ? nfsuser2 : nfsuser1;

	/* Create the users home directory */

	ret = mkdir(realhome, 0777);

	if ((ret) && (ret != EEXIST)) {
		snprintf(errormsg, 2048, "Failed to create %s, please report to help@vpac.org", realhome);
		perror(errormsg);
		exit(-1);
	}

	/* Set the ownership of the home directory */

	ret = chown(realhome, -1, getgid());

	if (ret) {
		snprintf(errormsg, 2048, "Failed to set ownership of %s, please report to help@vpac.org", realhome);
		perror(errormsg);
		exit(-1);
	}

	/* Create the symlink from their home directory to the real location */
	create_real_link(realhome, pw->pw_dir);

	/* Create the symlink on the other filesystem */
	ret = symlink(realhome, fakehome);

	if (ret) {
		snprintf(errormsg, 2048, "Failed to make link from %s to %s, please report to help@vpac.org", fakehome, realhome);
		perror(errormsg);
		exit(-1);
	}

	exit(0);

}
