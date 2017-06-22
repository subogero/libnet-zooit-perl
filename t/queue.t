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

Net::ZooIt::set_log_level(ZOOIT_INFO);

my $consumers = 3;
my $items = 100;

# Create 2 child processes to consume queue
my $parent = $$;
for (1 .. $consumers) {
    my $pid = fork;
    last unless $pid;
    print STDERR "Child $pid forked\n";
}

my $url = shift // '127.0.0.1:2181';
my $zk = Net::ZooKeeper->new($url, session_timeout => 5000);
$zk->create('/zooitqueue' => $$, acl => ZOO_OPEN_ACL_UNSAFE);

my $queue = Net::ZooIt->new_queue(path => '/zooitqueue', zk => $zk);

# Parent waiting for workers to complete
if ($$ == $parent) {
    $queue->put_queue($_) for 1 .. $items;
    print STDERR "Waiting for children...\n";
    for (1 .. $consumers) {
        my $pid = wait;
        ok(! $?, "Child $pid exited $?");
    }
    done_testing;
    exit;
}

# Children consuming queue
my $processed = 0;
while (my $data = $queue->get_queue(timeout => 5)) {
    $processed++;
    print "$$ $data\n";
}
ok($processed > 0 && $processed < $items, "Child $$ processed $processed");
