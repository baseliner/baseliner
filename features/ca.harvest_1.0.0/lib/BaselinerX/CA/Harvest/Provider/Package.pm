package BaselinerX::CA::Harvest::Provider::Package;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::CA::Harvest::Namespace::Package;

with 'Baseliner::Role::Provider';

register 'namespace.harvest.package' => {
	name	=>_loc('Harvest Packages'),
	domain  => domain(),
	can_job => 1,
    finder =>  \&find,
	handler =>  \&list,
};

#TODO needs to be in config:
our %from_states = ( 
	DESA => {  promote => [ 'Desarrollo', 'Desarrollo Integrado' ], demote => 0 },
	PREP => {  promote => [ 'Desarrollo Integrado' ], demote => [ 'Pruebas Integradas', 'Pruebas de Acceptación', 'Pruebas Sistemas' ] },
	PROD => {  promote => [ 'Pruebas Sistemas' ], demote => [ 'Producción' ] },
);

register 'config.harvest.transition.states' => {
    metadata => [
        { id=>'promote', label=>_loc('Promote States'), type=>'hash' },   #TODO 'text' no, 'commas'
        { id=>'demote', label=>_loc('Demote States'), type=>'hash' },   #TODO 'text' no, 'commas'
    ]
};


sub namespace { 'BaselinerX::CA::Harvest::Namespace::Package' }
sub domain    { 'harvest.package' }

sub find {
    my ($self, $item ) = @_;
    my $package = Baseliner->model('Harvest::Harpackage')->search({ packagename=>$item })->first;
    return BaselinerX::CA::Harvest::Namespace::Package->new({ row => $package }) if( ref $package );
}

sub list {
    my ($self, $c, $p) = @_;
    my $bl = $p->{bl};
    my $job_type = $p->{job_type};
    my $query = $p->{query};
    my $sql_query;
    if( $p->{can_job} ) {
        my $states = state_for_job({ bl=> $bl, job_type=>$job_type });
        $sql_query = { packageobjid => { '>', 0 }, statename => $states };
    }
    elsif( $p->{states} ) {
        $sql_query = { packageobjid => { '>', 0 }, statename => $p->{states} };
    }
    else {
        $sql_query = { packageobjid => { '>', 0 } };
    }
    my $rs = Baseliner->model('Harvest::Harpackage')->search(
        $sql_query,
        { join => [ 'state','modifier', 'envobjid' ],
          prefetch => [ 'state','modifier', 'envobjid' ] }
    );
    my @ns;
    my $ns_type= _loc('Harvest Package');
    while( my $r = $rs->next ) {
        next if( $query && !query_array($query, $r->packagename, $r->modifier->username, $r->state->statename, $ns_type ));
        push @ns, BaselinerX::CA::Harvest::Namespace::Package->new({ row => $r });
    }
    return \@ns;
}

sub state_for_job {
	my $p = shift;
	my $env = $from_states{ $p->{bl} };
	my $states = $env->{ $p->{job_type} };	
	unless( ref $states ) {
		return;
	} else {
		return $states;
	}
}

1;
