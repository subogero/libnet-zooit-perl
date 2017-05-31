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

# Create 2 child processes to consume queue
my $parent = $$;
for (1 .. 2) {
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
    $queue->put_queue($_) for 1 .. 10;
    print STDERR "Waiting for children...\n";
    wait; wait;
    done_testing;
    exit;
}

while (my $data = $queue->get_queue(timeout => 5)) {
    print "$$ $data\n";
    sleep rand 3;
}
