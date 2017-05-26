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

sub zerr2txt {
    my $err = shift;
    our %code2name;
    unless (%code2name) {
        foreach my $name (@{$Net::ZooKeeper::EXPORT_TAGS{errors}}) {
            no strict "refs";
            my $code = &$name;
            use strict "refs";
            $code2name{$code} = $name;
        }
    }
    return $code2name{$err};
}

# ZooKeeper recipe Lock
sub new_lock {
    my $class = shift;
    zerr "lock will be released immediately, new_lock called in void context"
        unless defined wantarray;
    my %p = @_;
    zdie "Param zk must be a connect Net::ZooKeeper object"
        unless ref $p{zk};
    zdie "Param path must be a valid ZooKeeper znode path"
        unless $p{path} =~ m|^/.+|;
    $p{blocking} //= 1;

    my $lock = $p{zk}->create(
        "$p{path}/lock-" => hostname . " PID $$",
        flags => ZOO_EPHEMERAL|ZOO_SEQUENCE,
        acl => ZOO_OPEN_ACL_UNSAFE,
    ) or zdie "Could not create $p{path}/lock-: " . zerr2txt($p{zk}->get_error);
    zinfo "Created lock $lock";

    my ($basename, $n) = split /-/, $lock;
    while (1) {
        zdebug "Get lock list:";
        my @locks = $p{zk}->get_children($p{path});
        my $n_prev;
        # Look for other lock with highest sequence number lower than mine
        foreach (@locks) {
            zdebug "  $_";
            my ($basename_i, $n_i) = split /-/;
            next if $n_i >= $n;
            $n_prev = $n_i if !defined $n_prev || $n_i > $n_prev;
        }
        # If none found, the lock is mine
        unless (defined $n_prev) {
            zinfo "Take lock: $lock";
            return bless { lock => $lock, zk => $p{zk} };
        }
        # I can't take lock, abort if non-blocking call
        unless ($p{blocking}) {
            zinfo "Non-blocking call, abort";
            $p{zk}->delete($lock);
            return;
        }
        # Wait for lock with highest seq number lower than mine to be deleted
        my $w = $p{zk}->watch(timeout => 10000);
        $w->wait if $p{zk}->exists("$p{path}/lock-$n_prev", watch => $w);
    }
}

sub DESTROY {
    my $self = shift;
    if ($self->{lock}) {
        zinfo "Release lock: $self->{lock}";
        $self->{zk}->delete($self->{lock});
        delete $self->{lock};
    }
}

1;
