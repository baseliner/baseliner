package BaselinerX::CA::Harvest::Service::Transition;
use Baseliner::Plug;
use Baseliner::Utils;
use Try::Tiny;

use utf8;

with 'Baseliner::Role::Service';

register 'service.harvest.transition' => {
	name => 'Transition Packages from one state to another',
	handler => \&run,
};

register 'config.harvest.transition.states' => {
    metadata => [
        { id=>'bl_to_state', label=>_loc('Baseline to State'), type=>'hash', }, 
        { id=>'promote', label=>_loc('Promote States'), type=>'hash' },   #TODO 'text' no, 'commas'
        { id=>'demote', label=>_loc('Demote States'), type=>'hash' },   #TODO 'text' no, 'commas'
    ]
};

our %to_state_map = (
	'promote' => {
		'TEST' => [ 'Development', 'Desarrollo Integrado', 'Consolidación', 'Pruebas' ],
		'PREP' => [ 'Preproducción', 'Pruebas Integradas' ],
		'CAPL' => [ 'Preproducción' ],
		'PROD' => [ 'Producción' ],
	},
	'demote' => {
		'TEST' => [ 'Desarrollo Integrado', 'Consolidación', 'Pruebas' ],
		'PREP' => [ 'Desarrollo Integrado', 'Pruebas' ],
		'CAPL' => [ 'Consolidación' ],
		'PROD' => [ 'Producción', 'Producción Correctivo' ],
	},
);

sub run {
	my ($self, $c, $p ) = @_;

	my $job = $c->stash->{job};
	my $log = $job->logger;

	my $bl = $job->bl;
	my $job_type = $job->job_type;

	unless( $job_type =~ m/promote|demote|rollback/ ) {
		$log->debug( _loc('No transition for job type "%1"', $job_type ) );
		return;
	}

	my $contents = $job->job_stash->{contents};
	my $inf = $c->model('ConfigStore')->get('config.harvest.transition.states', ns=>'/', bl=>$job->bl );
	my $inf_cli = Baseliner->model('ConfigStore')->get('config.ca.harvest.cli', ns=>'/', bl=>$job->bl );

	my %packages; 
	foreach my $job_item ( _array $contents ) {
		#my $data = YAML::Load( $job_item->{data} );
		my $item = $job_item->{item};
		my $ns_package = $c->model('Namespaces')->get( $item ); 
		next unless ref $ns_package;
		next unless $ns_package->isa('BaselinerX::CA::Harvest::Namespace::Package');

		# group packages by application:state
		my $env = $ns_package->environmentname;
		my $state = $ns_package->state; 
		my $key = "$env¡$state";
		$log->debug( _loc('Aplicacion:Estado %1 para el paquete %2', $key, $ns_package->ns_data->{packagename} ) );
		push @{ $packages{$key} }, $ns_package->ns_data->{packagename};
	}
	$log->debug('Agrupacion de paquetes por aplicacion', data=>_dump \%packages );

	my $to_state;
	ref $job->job_stash->{harvest_data} and $to_state = $job->job_stash->{harvest_data}->{to_state};
	foreach my $key ( keys %packages ) {
		my ($env, $state ) = split /¡/, $key; 
		my @env_packages = _array $packages{ $key };
		my $env_packages = join ',', @env_packages;
		$log->info( _loc('Promoting packages %1 from state %2 to state %3 in project %4', $env_packages, $state, $to_state, $env) ); 	

		# find to_state in case the job_stash doesn't have it
		$to_state ||= $self->find_to_state( project=>$env, state=>$state, job_type=>$job_type, bl=>$bl );
		$to_state or _throw _loc('No to_state found in the job stash or in config.ca.harvest.map for baseline %1 and job type %2. Harvest package transition cancelled.', $bl, $job_type);

		# decide if it's a promote or demote
		my ( $process_name, $type ) = $self->find_process( project=>$env, state=>$state, to_state=>$to_state)
			or _throw _loc('Could not find a Harvest process to promote/demote from state "%1"', $state );

		$log->debug( _loc('Found "%1" process name "%2"', $type, $process_name ) );

		# transition
		my $cli = new BaselinerX::CA::Harvest::CLI({ broker=>$inf_cli->{broker}, login=>$inf_cli->{login} });
		my $ret = $cli->transition( cmd=>'promote', project=>$env, process=>$process_name, state=>$state, packages=>[ @env_packages ] );

		# publish log
		$log->debug( _loc('Resultado de la promoción (rc=%1)', $ret->{rc} ), data=>$ret->{msg} );
	}
}

sub find_to_state {
	my ($self, %p ) = @_;
	my $project = $p{project};
	my $bl = $p{bl};
	my $state = $p{state};
	my $job_type = $p{job_type};
	my $to_state;
	#$job_type='promote' if $job_type eq 'normal';
	$job_type='demote' if $job_type eq 'rollback';
	try {
		$to_state = $to_state_map{$job_type}{$bl};
	} catch {
		my $error = shift;
	};
	return $to_state;
}

sub find_process {
	my ($self, %p ) = @_;
	my $project = $p{project};
	my $state = $p{state};
	my $to_state = $p{to_state};
	my $env_row = Baseliner->model('Harvest::Harenvironment')->search({ environmentname=>$project })->first;
	ref $env_row or _throw _loc 'Could not find Harvest project "%1"', $project;
	my $eid = $env_row->envobjid;
	my $state_row = Baseliner->model('Harvest::Harstate')->search({ envobjid=>$eid, statename=>$state })->first;
	ref $state_row or _throw _loc 'Could not find Harvest state "%1"', $state;
	my $state_id = $state_row->stateobjid;
	my $to_state_row = Baseliner->model('Harvest::Harstate')->search({ envobjid=>$eid, statename=>$to_state })->first;
	ref $to_state_row or _throw _loc 'Could not find Harvest state "%1"', $to_state;
	my $to_state_id = $to_state_row->stateobjid;
	
	my $proc = Baseliner->model('Harvest::Harpromoteproc')->search({ stateobjid=>$state_id, tostateid=>$to_state_id })->first;
	if( ref $proc ) {
		return ( $proc->processname, 'promote' );
	}
	
	$proc = Baseliner->model('Harvest::Hardemoteproc')->search({ stateobjid=>$state_id, tostateid=>$to_state_id })->first;
	ref $proc or _throw _loc 'Could not find a promote/demote process in Harvest';
	return ( $proc->processname, 'demote' );
}

1;
