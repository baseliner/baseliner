package BaselinerX::Job::Service::Contents;
use Baseliner::Plug;
use Baseliner::Utils;
use Carp;
use Try::Tiny;
use utf8;

with 'Baseliner::Role::Service';

register 'service.job.contents' => { name => 'Job Runner Contents Loader', config => 'config.job.runner', handler => \&run, };

sub run {
	my ($self,$c,$config)=@_;
	
	my $job = $c->stash->{job};
	my $log = $job->logger;

	# prepare the contents array (package list)
    $job->job_stash->{contents} = [];

	# prepare the elements object
    $job->job_stash->{elements} = BaselinerX::Job::Elements->new;

	# load the contents array
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
	my $call_runners = 0;   # this is disabled and deprecated
    if( $call_runners && $job->job_data->{step} eq 'PRE' ) {
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
    $log->debug( 'Contenido del stash del pase', data_name=>'Job Stash', data=>_dump( $job->job_stash ) );
}

1;
