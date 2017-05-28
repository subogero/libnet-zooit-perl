#!/usr/bin/perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib/perl5";
use Net::ZooIt;
use Net::ZooKeeper qw(:all);
use Test::More;
use YAML::XS;

$| = 1;

Net::ZooIt::set_log_level(ZOOIT_DEBUG);

sub T_MAX { 30 }
sub T_MAX_ERR { 41 }

# Create 3 child processes running for leadership for random periods of time
my $parent = $$;
for (1 .. 3) {
    my $pid = fork;
    last unless $pid;
    print STDERR "Child $pid forked\n";
}

# Parent waiting for workers to complete
if ($$ == $parent) {
    $SIG{ALRM} = sub { ok(0, 'Children still running') };
    alarm T_MAX_ERR;
    wait; wait; wait;
    done_testing;
    exit;
}

# Child processes doing the leader election
my $t0 = time;

my $url = shift // '127.0.0.1:2181';
my $zk = Net::ZooKeeper->new($url, session_timeout => 5000);
$zk->create('/zooitelect' => $$, acl => ZOO_OPEN_ACL_UNSAFE);

while (1) {
    my $lock = Net::ZooIt->new_lock(zk => $zk, path => '/zooitelect');
    if ($lock) {
        print STDERR "$$ elected\n";
        sleep 1 + int rand 5;
        print STDERR "$$ resigns\n";
    } else {
        sleep 1 + int rand 5;
        print STDERR "$$ retrying\n";
    }
    if (time > $t0 + T_MAX) {
        print STDERR "$$ exiting\n";
        last;
    }
}
