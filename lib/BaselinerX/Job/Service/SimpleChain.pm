package BaselinerX::Job::Service::SimpleChain;
use Baseliner::Plug;
use Baseliner::Utils;
use Carp;
use Try::Tiny;
use utf8;

with 'Baseliner::Role::Service';

register 'service.job.runner.simple.chain' => { name => 'Simple Chain Job Runner', config => 'config.job', handler => \&job_simple_chain, };

# process the chained services
sub job_simple_chain {
	my ($self,$c, $config)=@_;

	my $job = $c->stash->{job};
	my $log = $job->logger;

	$log->debug('Iniciando Simple Chain Runner PID=' . $job->job_data->{pid} );

    my $step = $job->job_stash->{step};
    _throw "Missing job chain step" unless $step;

	my $chain_id = 1; #FIXME needs to get the current job chain

	my $chain_row = $c->model('Baseliner::BaliChain')->search({ id=> $chain_id })->first;
	_throw _loc( 'Missing default job chain id %1', $chain_id ) unless ref $chain_row;
	my $chain_name = $chain_row->name;
	my $rs_chain = $c->model('Baseliner::BaliChainedService')->search({ step=>$step, chain_id=>$chain_row->id, active=>'1' }, { order_by=>'seq' });
	my @chained_services;

	while( my $service = $rs_chain->next ) {
		push @chained_services, { $service->get_columns } ;
	}

	my $chain_obj = new BaselinerX::Job::Chain( 
		services => [ @chained_services ],
		current_index => 0,
		chain => { $chain_row->get_columns },
		id => $chain_id,
	);

	$job->job_stash->{chain} = $chain_obj;

	$log->debug( _loc('Chain %1 loaded', $chain_name ), data=>_dump $chain_obj );

	while(1) {
		my $service_key;
        #eval {
			# always get the latest from the stash, in case it has changed
			my $chain = $job->job_stash->{chain};

			# get the next service in the chain
			my $service = $chain->next_service or last;
			$service_key = $service->{key};

            $log->debug( _loc('Starting chained service %1 for step %2' , $service_key, $step ) );
            $c->launch( $service->{key} );
            $log->debug( _loc('Finished chained service %1 for step %2' , $service_key, $step ) );

			# are there more services to run?
			last if $chain->done;
        #};
		#if( $@ ) {
            #my $error = $@;
            #$log->error( _loc('Error while running chained service %1 for step %2: %3' , $service_key, $step, $error ) ); 
			#_throw $error;
        #}
	}
}

1;
