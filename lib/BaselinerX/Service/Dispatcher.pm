package BaselinerX::Service::Dispatcher;
use Baseliner::Plug;
use Baseliner::Utils;
use Proc::Background;
use Proc::Exists qw(pexists);

with 'Baseliner::Role::Service';

=head1 DESCRIPTION

Brings up all daemons. 

Checks the daemon table to see if they are active. Stops daemons when they are not.

=cut

register 'config.dispatcher' => {
    name => 'Dispatcher configuration',
    metadata => [
        { id=>'frequency', default=> 30 },
    ],
};

register 'service.dispatcher' => {
    name => 'Dispatcher Service',
    config => 'config.dispatcher',
    handler => \&run,
};

sub run {
    my ( $self, $c, $config ) = @_;

    #TODO if 'start' fork and go nohup .. or proc::background my self in windows
    #TODO if 'stop' go die

    $self->dispatcher( $c, $config );
}

sub dispatcher {
    my ( $self, $c, $config ) = @_;

    my $frequency = $config->{frequency};

    while( 1 ) {
        _log _loc('Checking for daemons started/stopped');
        for my $daemon ( Baseliner->model('Daemon')->list( all => 1 ) ) {
            if ( !$daemon->active ) {
                next unless $daemon->pid;
                next unless pexists( $daemon->pid );
                _debug "Stopping daemon " . $daemon->service;

                if( kill 9,$daemon->pid ) {
                    $daemon->pid( 0 );
                    $daemon->update;
                    _log "Daemon " . $daemon->service . " stopped";
                } else {
                    _log "Could not kill daemon "
                      . $daemon->service
                      . " with pid "
                      . $daemon->pid;
                }
                
            } elsif ( $daemon->active ) {
                next if $daemon->pid && pexists( $daemon->pid );
                _debug "Starting daemon " . $daemon->service;

                # bring it back up
                my $params  = {};
                my @started = Baseliner->model('Daemon')->service_start(
                    service => $daemon->service,
                    params  => $params
                );
                my $started = shift @started;
                $daemon->pid( $started->{pid} );
                $daemon->update;

                # $c->launch( $daemon->{service} );
            }
        }
        sleep $frequency;
    }
}

=head1 nohup

use POSIX qw/setsid/;
my $pid = fork();
die "can't fork: $!" unless defined $pid;
exit 0 if $pid;
setsid();
open (STDIN, "</dev/null");
open (STDOUT, ">/dev/null");
open (STDERR,">&STDOUT");
exec "some_system_command";

=cut


1;
