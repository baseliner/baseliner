package BaselinerX::Job::Service::Init;
use Baseliner::Plug;
use Baseliner::Utils;
use Carp;
use Try::Tiny;
use File::Spec;
use File::Path qw/remove_tree/;

use utf8;

with 'Baseliner::Role::Service';

register 'service.job.init' => { name => 'Job Runner Initializer', config => 'config.job.runner', handler => \&job_init, };

our %next_step = ( PRE => 'RUN',   RUN => 'POST',  POST => 'END' );
our %next_state  = ( PRE => 'READY', RUN => 'READY', POST => 'FINISHED' );

# executes jobs sent by the daemon in an independent process

sub job_init {
	my ($self,$c,$config)=@_;
	
	my $job = $c->stash->{job};
	my $log = $job->logger;

	my $job_dir = File::Spec->catdir( $config->{root}, $job->name );
	$log->debug( 'Creando directorio de pase ' . $job_dir );
	unless( -e $job_dir ) {
		mkdir $job_dir;
	} else {
        remove_tree $job_dir, { keep_root=>1 };
    }
    warn "=============JOB: " . Dump $job;
	$job->job_stash->{path} = $job_dir;
}

1;
