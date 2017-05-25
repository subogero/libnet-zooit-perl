package Net::ZooIt;
use strict;
use warnings;

use Sys::Hostname qw(hostname);
use POSIX qw(strftime);
use feature ':5.10';

use Net::ZooKeeper qw(:all);

use base qw(Exporter);
our @EXPORT = qw(ZOOIT_DIE ZOOIT_ERR ZOOIT_WARN ZOOIT_INFO ZOOIT_DEBUG);

# Logging
sub ZOOIT_DIE { 0 }
sub ZOOIT_ERR { 1 }
sub ZOOIT_WARN { 2 }
sub ZOOIT_INFO { 3 }
sub ZOOIT_DEBUG { 4 }
my @log_levels = qw(ZOOIT_DIE ZOOIT_ERR ZOOIT_WARN ZOOIT_INFO ZOOIT_DEBUG);
my $log_level = 1;

sub set_log_level {
    my $level = shift;
    return unless $level =~ /^\d+$/;
    $log_level = $level;
}

sub logger {
    my ($level, $msg) = @_;
    return unless $level =~ /^\d+$/;
    return if $level > $log_level;
    $msg =~ s/\n$//;
    my $prefix = strftime '%Y-%m-%dT%H:%M:%SZ', gmtime;
    $prefix .= " $$";
    $prefix .= " $log_levels[$level]";
    print STDERR "$prefix $msg\n";
    die $msg if $level == 0;
}

sub zdie { logger ZOOIT_DIE, @_ }
sub zerr { logger ZOOIT_ERR, @_ }
sub zwarn { logger ZOOIT_WARN, @_ }
sub zinfo { logger ZOOIT_INFO, @_ }
sub zdebug { logger ZOOIT_DEBUG, @_ }

1;
