#!/usr/bin/perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";
use Net::ZooKeeper qw(:all);
use ZooItServer;

use Test::More;

$| = 1;

my $server = ZooItServer->start;
my @z = $server->zk->get_children('/');
print "@z\n";
ok(@z >= 1, "At least one Znode found");

$server->stop;
@z = $server->zk->get_children('/');
ok(@z == 0, "No Znode found after server stop");

$server->start;
my @z = $server->zk->get_children('/');
print "@z\n";
ok(@z >= 1, "At least one Znode found after server restart");

done_testing;
