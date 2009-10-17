package Baseliner::Model::Daemon;
use Baseliner::Plug;
extends qw/Catalyst::Model/;
use Baseliner::Utils;

sub list {
    my ( $self, %p ) = @_;
    
    my $query = {};
    $query->{active} = defined $p{active} ? $p{active} : 1;
    $p{all} and delete $query->{active};

    my @daemons;
    my $rs = Baseliner->model('Baseliner::BaliDaemon')->search($query);

    while( my $r = $rs->next ) {
        #my $config_key = $r->config;
        #my $inf = Baseliner->model('ConfigStore')->get( $config_key );
        #my $frequency = 10;
        #if( ref $inf ) {
            #$frequency = $inf->{frequency} or next;
        #}

        # push @daemons, { $r->get_columns, };
        push @daemons, $r ;
    }
    return @daemons;
}

=head2 service_start

Start a separate perl process for a background service.

    services=>['service.name', 'service.name2', ... ]

    params  => {  job_id=>111, etc=>'aaa' }

=cut
sub service_start {
    my ( $self, %p ) = @_;

    my @services = _array $p{services}, $p{service};

    _throw 'No service specified' unless @services;

    my %params = _array $p{params}, $p{param};

    my @started;
    for my $service_name ( @services ) {
        my $params = join ' ', map { "$_=$params{$_}" } keys %params;
        my $cmd = "perl $0 $service_name $params";
        _debug "Starting service background command '$cmd'";
        my $proc = Proc::Background->new($cmd)
          or _throw "Could not start service $service_name: $!";
        push @started,
          {
            service => $service_name,
            pid     => $proc->pid,
            host    => lc( Sys::Hostname::hostname() ),
            owner   => $ENV{USER} || $ENV{USERNAME}
          };
    }
    return @started;
}

1;
