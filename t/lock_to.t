#!/usr/bin/perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib/perl5";
use Net::ZooIt;
use Net::ZooKeeper qw(:all);
use Test::More;

$| = 1;
Net::ZooIt::set_log_level(ZOOIT_DEBUG);

my $file = 'incr.txt';
unlink $file;

my $url = shift // '127.0.0.1:2181';

my $pid = fork;
my $zk = Net::ZooKeeper->new($url);
$zk->create('/zooitlock' => $$, acl => ZOO_OPEN_ACL_UNSAFE);

incr() for 0 .. 9;
$pid ? wait : exit;
$zk->delete('/zooitlock');

open FILE, $file or die $!;
my $n;
(undef, $n) = split /\s/ while <FILE>;
close FILE;
ok($n == 20, 'n incrmented to 20, races avoided');

done_testing;

sub incr {
    my $lock;
    until ($lock = Net::ZooIt->new_lock(zk => $zk, path => '/zooitlock', timeout => 1)) {
        sleep 1;
    }
    my $num;
    if (open FILE, $file) {
        (undef, $num) = split /\s/ while <FILE>;
        close FILE;
    }
    $num //= 0;
    $num++;
    sleep 1 + rand 3;
    open FILE, ">>", $file or die $!;
    print STDERR "$$ $num\n";
    print FILE "$$ $num\n";
    close FILE;
}
