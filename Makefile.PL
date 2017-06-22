use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'Net::ZooIt',
    VERSION_FROM => 'lib/perl5/Net/ZooIt.pm',
    ABSTRACT_FROM => 'lib/perl5/Net/ZooIt.pm',
    AUTHOR => 'SZABO Gergely <szg@subogero.com>',
);

sub MY::postamble {
    return <<'EOF';
all :: README
README :: lib/perl5/Net/ZooIt.pm Makefile
	pod2readme $<
	-rm README.bak
EOF
}
