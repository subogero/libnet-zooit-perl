package ZooItServer;

use strict;
use warnings;

use FindBin;
use File::Temp qw(tempdir);

use Net::ZooKeeper qw(:all);

sub _gen_cfg {
    my $ip = '127.0.0.1';
    my $port = 2182;
    my $url = "$ip:$port";
    my $ETC = "$FindBin::Bin/etc";
    my $VAR = tempdir(CLEANUP => 1);
    open DEF, '<', "$ETC/zoo.cfg.default" or die $!;
    open CFG, '>', "$VAR/zoo.cfg" or die $!;
    while (<DEF>) {
        s/^(dataDir)=.*/$1=$VAR/;
        s/^(clientPort)=.*/$1=$port/;
        s/^#(preAllocSize)=.*/$1=1024/;
        print CFG;
    }
    close DEF;
    close CFG;
    my $cmd = <<EOF;
/usr/bin/java -cp $ETC:/usr/share/java/jline.jar:/usr/share/java/log4j-1.2.jar:/usr/share/java/xercesImpl.jar:/usr/share/java/xmlParserAPIs.jar:/usr/share/java/netty.jar:/usr/share/java/slf4j-api.jar:/usr/share/java/slf4j-log4j12.jar:/usr/share/java/zookeeper.jar -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.local.only=false -Dzookeeper.log.dir=$VAR -Dzookeeper.root.logger=INFO,ROLLINGFILE org.apache.zookeeper.server.quorum.QuorumPeerMain $VAR/zoo.cfg
EOF
    return $cmd, $url, $VAR;
}

sub start {
    my $self;
    if (ref $_[0]) {
        $self = shift;
    } else {
        $self = bless {}, shift;
    }

    my ($cmd, $url, $dir) = _gen_cfg();
    print STDERR "Running in $dir\n";

    # Start server
    $self->stop if $self->{pid};
    $self->{pid} = fork;
    die $! unless defined $self->{pid};
    unless ($self->{pid}) {
        print STDERR "Starting ZooKeeper server on $url\n";
        exec $cmd;
        die $!;

    }

    # Init client
    $self->{zk} = Net::ZooKeeper->new($url, session_timeout => 5000);
    for (1 .. 20) {
        sleep 1;
        print STDERR "Tryimg to connect to $url\n";
        my @z = $self->{zk}->get_children('/');
        my $err = $self->{zk}->get_error;
        next unless $err == ZOK;
        print STDERR "Connected to $url\n";
        last;
    }

    $self->{url} = $url;
    $self->{dir} = $dir;
    return $self;
}

sub stop {
    my $self = shift;
    $self->{pid} and kill 'TERM', $self->{pid};
    wait;
    delete $self->{pid};
}

sub url { shift()->{url} }

sub zk { shift()->{zk} }

sub DESTROY {
    my $self = shift;
    print STDERR "Stopping server\n";
    $self->stop;
}

1;
