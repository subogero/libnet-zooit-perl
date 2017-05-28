all: README
README: lib/perl5/Net/ZooIt.pm Makefile
	pod2readme $<
	-rm README.bak
