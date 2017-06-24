use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'Net::ZooIt',
    VERSION_FROM => 'lib/Net/ZooIt.pm',
    ABSTRACT_FROM => 'lib/Net/ZooIt.pm',
    AUTHOR => 'SZABO Gergely <szg@subogero.com>',
    PREREQ_PM => {
        Carp => 0,
        Exporter => 0,
        'File::Temp' => 0,
        FindBin => 0,
        'Net::ZooKeeper' => 0,
        POSIX => 0,
        'Sys::Hostname' => 0,
        'Time::HiRes' => 0,
        base => 0,
        feature => 0,
        strict => 0,
        warnings => 0,
    },
);


sub MY::postamble {
    return <<'EOF';
all :: README
README :: lib/Net/ZooIt.pm Makefile
	pod2readme $<
	-rm README.bak
EOF
}
