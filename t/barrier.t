#!/usr/bin/perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";
use POSIX;
use Net::ZooIt;
use Net::ZooKeeper qw(:all);
use ZooItServer;
use integer;

use Test::More;

$| = 1;

Net::ZooIt::set_log_level(ZOOIT_DEBUG);

diag "IMPLEMENT BARRIER USING HERD RECIPE";

my $server = ZooItServer->start;
eval { $server->connect } or no_server();

# Create 2 child processes
my $parent = $$;
for (1 .. 2) {
    my $pid = fork;
    last unless $pid;
    rand;
    print STDERR "Child $pid forked\n";
}
my $zk = $server->connect;
$zk->create('/barrier' => $$, acl => ZOO_OPEN_ACL_UNSAFE);

my $barrier = Net::ZooIt->new_herd(zk => $zk, path => '/barrier');

$barrier->join_herd;
my $dt = $$ == $parent
    ? 1
    : 2 + rand 5;
print STDERR "$$ sleeping for $dt [s]\n";
sleep $dt;
$barrier->join_herd(group => 'ready');
$barrier->count_herd(timeout => 10, waitfor => sub {
    my $ready = grep { /^ready_/ } @_;
    my $all = grep { /^_/ } @_;
    print STDERR "$$ $ready ready of $all\n";
    return $ready > $all / 2;
});
sleep 5;
$barrier->leave_herd(group => '.*');

if ($$ == $parent) {
    wait for 1 .. 2;
    done_testing;
}

sub no_server {
    ok(1, 'Skipping test, no ZK server available');
    done_testing;
    _exit 0;
}
