package BaselinerX::Job::Service::Runner;
use Baseliner::Plug;
use Baseliner::Utils;
use YAML::Syck;
use Path::Class;
use BaselinerX::Job::Elements;
use Carp;
use Try::Tiny;
use utf8;

has 'jobid' => ( is=>'rw', isa=>'Int' );
has 'name' => ( is=>'rw', isa=>'Str' );
has 'logger' => ( is=>'rw', isa=>'Object' );
has 'ns' => ( is=>'rw', isa=>'Str' );
has 'bl' => ( is=>'rw', isa=>'Str' );
has 'status' => ( is=>'rw', isa=>'Str' );
has 'job_type' => ( is=>'rw', isa=>'Str' );
has 'job_stash' => ( is=>'rw', isa=>'HashRef', default=>sub {{}}  );
has 'job_data' => ( is=>'rw', isa=>'HashRef', default=>sub {{}} );

with 'Baseliner::Role::Service';

register 'config.job.runner' => {
    metadata => [
        { id => 'root', default => do { $ENV{BASELINER_TEMP} || $ENV{TEMP} || File::Spec->tmpdir() } },
        { id      => 'step', name    => 'Which phase of the job, pre, post or run', default => 'RUN' },
    ]
};

register 'service.job.run' => { name => 'Job Runner', config => 'config.job', handler => \&job_run, };

register 'action.notify.job.end' => { name=>_loc('Notify when job has finished') };
register 'action.job.approve' => { name=>_loc('Approve jobs') };

our %next_step = ( PRE => 'RUN',   RUN => 'POST',  POST => 'END' );
our %next_state  = ( PRE => 'READY', RUN => 'READY', POST => 'FINISHED' );

# executes jobs sent by the daemon in an independent process
sub job_run {
	my ($self,$c,$config)=@_;

	my $jobid = $config->{jobid};
	$c->stash->{job} = $self;
	$self->jobid( $jobid );
	$self->logger( new BaselinerX::Job::Log({ jobid=>$jobid }) );

	# trap all die signals
    $SIG{__DIE__} = \&_die;

	_log "\n================================| Starting JOB=" . $jobid;

    my $step = $config->{step} or _throw 'Missing step value';

	Catalyst::Exception->throw( "No job chain or service defined for job " . $config->{jobid} )
		unless( $config->{runner} );
	$c->log->debug("Running Service " . $config->{runner} . " for step=$step" ); 

	try {
		my $r = $c->model('Baseliner::BaliJob')->search({ id=>$jobid })->first;
		$self->name( $r->name );
		$self->job_type( $r->type );
		$self->job_data( { $r->get_columns } );

		#thaw job stash from table
		my $stash = {};
		if( $r->stash ) {
			try {
				$stash = YAML::Syck::Load( $r->stash ); 
			} catch {
				$self->logger->warn( 'No he podido recuperar el stash de pase', shift );
			};
		} 
		$self->job_stash( $stash );

		$self->job_stash->{step} = $step;

		# send notifications  TODO : send to all action+ns users
		$c->model('Messaging')->notify(
			subject => _loc('Job %1 started', $self->name ),
			message => '',
			sender => _loc('Job Manager'),
			to => { users => [$self->job_data->{username} ] },
			cc => { actions=> ['action.notify.job.end'], ns=>[] },
		);

		# start main runner
		$c->launch( $config->{runner} ); 

		# finish it
		{
			$self->logger->info( _loc('Step %1 finished', _loc( $step ) ) );
			my $r = $c->model('Baseliner::BaliJob')->search({ id=>$jobid })->first;
			$r->status( $self->status( $next_state{ $r->step } ) );
			$r->step( $next_step{ $r->step } );
			$r->update;

			#freeze job stash to table
			try {
				$r->stash( YAML::Syck::Dump( $self->job_stash ) ); 
				$r->update;
			} catch {
				$self->logger->warn( 'No he podido guardar el stash de pase', shift );
			};
		}
	
	} catch {
		my $error = shift;
		_log "*** Error running Job $jobid ****";
		_log $error;
		$self->logger->error( $error || _loc('Internal Error') );
		my $r = $c->model('Baseliner::BaliJob')->search({ id=>$jobid })->first;
		$r->status( $self->status('ERROR') );
		$r->update;
	};

	# send notifications  TODO : send to all action+ns users
	$c->model('Messaging')->notify(
		subject => _loc('Job %1 finished with status %2', $self->name, _loc( $self->status ) ),
		message => '',
		sender => _loc('Job Manager'),
		to => { users => [$self->job_data->{username} ] },
		cc => { actions=> ['action.notify.job.end'], ns=>[] },
	);
}

=head1 Moved to Contents.pm
sub job_contents {
	my ($self,$c,$config)=@_;
	
	my $log = $self->logger;

	# prepare the contents array (package list)
    $self->job_stash->{contents} = [];

	# prepare the elements object
    $self->job_stash->{elements} = BaselinerX::Job::Elements->new;

	# load the contents array
	$log->debug( 'Job Contents cargando, path=' . $self->job_stash->{path} );
	my $rs =$c->model('Baseliner::BaliJobItems')->search({ id_job=> $self->jobid }); 
	my %services;
	while( my $r = $rs->next ) {
		$log->debug('Cargando contenido de pase para id=' . $r->id );

		# load vars with contents
        my %job_items = $r->get_columns;
        $job_items{data} = YAML::Syck::Load( $job_items{data} ); # deserialize this baby
		push @{ $self->job_stash->{contents} }, \%job_items;

		# group contents
		$services{ $r->service } = 1;
	}

	# call each content service to prepare data for the RUN step
	my $call_runners = 0;   # this is disabled and deprecated
    if( $call_runners && $self->job_data->{step} eq 'PRE' ) {
        foreach my $service ( keys %services ) {
            next unless $service;
            $log->debug('Iniciando servicio de contenido de pase: ' . $service );
            eval {
                $c->launch( $service );
            };
            if( my $error = $@ ) {
                $log->error( "Servicio '$service' ha fallado" , data=>$error );
                die ( $error . "\n" ); 
            }
        }
    }
    $log->debug( 'Contenido del stash del pase', data_name=>'Job Stash', data=>Dump $self->job_stash );
}
=cut

sub _die {
  if ($_[-1] =~ /\n$/s) {
    my $arg = pop @_;
    $arg =~ s/ at .*? line .*?\n$//s;
    push @_, $arg;
  }
  die &Carp::longmess;
}


1;
