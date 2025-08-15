#include "grep.h"
#include "public.h"
#include <sys/types.h>

char *usagemsg = "usage: %s [ -bchilnvx ] [ -e exp ] [ -f file ] [ strings ] [ file ] ...\n";
char *stdinmsg;

void init(void)
{
	Fflag = 1;
	ac_select();
	options = "bce:f:hilnrRvxyz";
}

void misop(void)
{
	usage();
}

/*
 * Dummies.
 */
void eg_select(void)
{
}

void st_select(void)
{
}

void rc_select(void)
{
}

int main(int argc, char **argv)
{
	return grep_run(argc, argv);
}