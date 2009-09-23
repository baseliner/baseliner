package BaselinerX::Job::Runner;
use Baseliner::Plug;
use Baseliner::Utils;
use YAML::Syck;
use Path::Class;
use Carp;
use Try::Tiny;

#extends 'BaselinerX::Type::Service';

	has 'jobid' => ( is=>'rw', isa=>'Int' );
	has 'name' => ( is=>'rw', isa=>'Str' );
	has 'logger' => ( is=>'rw', isa=>'Object' );
	has 'ns' => ( is=>'rw', isa=>'Str' );
	has 'bl' => ( is=>'rw', isa=>'Str' );
	has 'status' => ( is=>'rw', isa=>'Str' );
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
register 'service.job.runner.simple.chain' => { name => 'Simple Chain Job Runner', config => 'config.job', handler => \&job_simple_chain, };
register 'service.job.init' => { name => 'Job Runner Initializer', config => 'config.job.runner', handler => \&job_init, };
register 'service.job.contents' => { name => 'Job Contents Runner', config => 'config.job.runner', handler => \&job_contents, };
register 'service.job.approve' => { name => 'Job Approval', config => 'config.job.runner', handler => \&job_approve, };

register 'action.notify.job.end' => { name=>_loc('Notify when job has finished') };
register 'action.job.approve' => { name=>_loc('Approve jobs') };

register 'service.job.purge.files' => {
	name => 'Purge job directories',
    scheduled => 1,
    frequency_key => 'config.job.purge.files.frequency',
	config => 'config.job',
	handler => sub {
        my ($self,$c,$config)=@_;
        my $log = $self->log;
        my @dirs = grep { $_->is_dir } Path::Class::dir( $config->{root} )->children;
        foreach my $job_dir ( @dirs ) {
           my $job_name = $job_dir->relative( $job_dir->parent )->stringify;
           my $job = $c->model('Jobs')->get( $job_name );
           $log->info( "Checking if $job_name is running...");
           if( $job->is_not_running ) {
               $log->info( "Deleteting job directory tree for $job_name");
               File::Path::remove_tree( $job_dir ); 
               $log->info( "$job_name directories deleted" );
           }
        }
    },
};

our %next_step = ( PRE => 'RUN',   RUN => 'POST',  POST => 'END' );
our %next_state  = ( PRE => 'READY', RUN => 'READY', POST => 'FINISHED' );

# executes jobs sent by the daemon in an independent process
sub job_run {
	my ($self,$c,$config)=@_;

	my $jobid = $config->{jobid};
	$c->stash->{job} = $self;
	$self->jobid( $jobid );
	$self->logger( new BaselinerX::Job::Log({ jobid=>$jobid }) );
    $SIG{__DIE__} = \&_die;

	_log "\n================================| Starting JOB=" . $jobid;

    my $step = $config->{step} or _throw 'Missing step value';

	if( $config->{runner} ) {
		$c->log->debug("Running Service " . $config->{runner} . " for step=$step" ); 

		try {
			my $r = $c->model('Baseliner::BaliJob')->search({ id=>$jobid })->first;
			$self->name( $r->name );
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
	else {
		Catalyst::Exception->throw( "No job chain or service defined for job " . $config->{jobid} );
	}
}

# process the chained services
sub job_simple_chain {
	my ($self,$c, $config)=@_;

	my $job = $c->stash->{job};
	my $log = $job->logger;

	$log->debug('Iniciando Simple Chain Runner PID=' . $job->job_data->{pid} );

    my $step = $job->job_stash->{step};
    _throw "Missing job chain step" unless $step;

	my $chain = $c->model('Baseliner::BaliChain')->search({ id=> 1})->first;
	my $rs_chain = $c->model('Baseliner::BaliChainedService')->search({ step=>$step, chain_id=>$chain->id, active=>'1' }, { order_by=>'seq' });
	while( my $r = $rs_chain->next ) {
		$log->debug('Running Service ' . $r->key);
		$c->launch( $r->key );
	}
}

use File::Spec;
use File::Path qw/remove_tree/;
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

sub job_contents {
	my ($self,$c,$config)=@_;
	
	my $job = $c->stash->{job};
	my $log = $job->logger;

	$log->debug( 'Job Contents cargando, path=' . $job->job_stash->{path} );
	my $rs =$c->model('Baseliner::BaliJobItems')->search({ id_job=> $job->jobid }); 
	my %services;
	while( my $r = $rs->next ) {
		$log->debug('Cargando contenido de pase para id=' . $r->id );

		# load vars with contents
        my %job_items = $r->get_columns;
        $job_items{data} = YAML::Syck::Load( $job_items{data} ); # deserialize this baby
		push @{ $job->job_stash->{contents} }, \%job_items;

		# group contents
		$services{ $r->service } = 1;
	}

	# call each content service to prepare data for the RUN step
    if( $job->job_data->{step} eq 'PRE' ) {
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
    $log->debug( 'Contenido del stash del pase', data_name=>'Job Stash', data=>Dump $job->job_stash );
}

sub job_approve {
    my ( $self, $c, $config ) = @_;
    
	my $job = $c->stash->{job};
	my $log = $job->logger;

    my $bl = $job->job_data->{bl};
    $log->debug( "Verificando si hay aprobaciones para $bl" );

    use utf8;
    for my $item ( _array $job->job_stash->{contents} )  {
        my $item_ns = 'endevor.package/' . $item->{item};   #TODO get real ns names
        $log->info( "Pidiendo aprobación para el pase en la linea base $bl, item $item_ns" );
            Baseliner->model('Request')->request(
                name   => 'Aprobación del pase N.DESA1029210',
                action => 'action.job.approve',
                vars   => { reason=>"promoción a $bl" },
                ns     => '/GBP.0000',
                bl     => $bl, 
            );
    }
}

sub _die {
  if ($_[-1] =~ /\n$/s) {
    my $arg = pop @_;
    $arg =~ s/ at .*? line .*?\n$//s;
    push @_, $arg;
  }
  die &Carp::longmess;
}


1;
