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

use Test::More;

$| = 1;

Net::ZooIt::set_log_level(ZOOIT_DEBUG);

diag "GROUP MEMBERSHIP VIA HERD RECIPE";

my $server = ZooItServer->start;
eval { $server->connect } or no_server();

my $zk = $server->connect;
$zk->create('/herd' => $$, acl => ZOO_OPEN_ACL_UNSAFE);

my $herd = Net::ZooIt->new_herd(zk => $zk, path => '/herd');

ok($herd->join_herd() =~ m|/_|, 'default group prefix _');
ok($herd->join_herd(group => 'sheep') =~ m|/sheep_|, 'sheep');
ok($herd->join_herd(group => 'goat') =~ m|/goat_|, 'goat');

ok($herd->count_herd == 3, 'herd counts 3');

$herd->leave_herd(group => 'goat');
ok($herd->count_herd == 2, 'herd counts 2 after goat leaves');
$herd->leave_herd(group => '.*');
ok($herd->count_herd == 0, 'herd counts 0 after wildcard leave');

done_testing;

sub no_server {
    ok(1, 'Skipping test, no ZK server available');
    done_testing;
    _exit 0;
}
