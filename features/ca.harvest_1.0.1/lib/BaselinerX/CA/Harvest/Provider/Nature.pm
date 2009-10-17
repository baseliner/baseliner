package BaselinerX::CA::Harvest::Provider::Nature;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::CA::Harvest::Namespace::Nature;

with 'Baseliner::Role::Provider';

register 'namespace.harvest.nature' => {
	name	=>_loc('Harvest Nature'),
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

sub namespace { 'BaselinerX::CA::Harvest::Namespace::Nature' }
sub domain    { 'harvest.nature' }

sub find {
    my ($self, $item ) = @_;
	$self->not_implemented;
    #my $package = Baseliner->model('Harvest::Harpackage')->search({ packagename=>$item })->first;
    #return BaselinerX::CA::Harvest::Namespace::Package->new({ row => $package }) if( ref $package );
}

sub list {
    my ($self, $c, $p) = @_;
    my $bl = $p->{bl};
    my $job_type = $p->{job_type};
    my $query = $p->{query};
    my $sql_query;
return [];
		my $rs = Baseliner->model('Harvest::Harpathfullname')->search({  });
		my @ns;
		my $config = Baseliner->registry->get('config.harvest.nature')->data;
		my $cnt = $config->{position};
		my %done;
		while( my $r = $rs->next ) {
			my $path = $r->pathfullname;
			my @parts = split /\\/, $path;
			next unless @parts == ($cnt+1); ## the preceding \ counts as the first item
			my $nature = $parts[$cnt];
			next if $done{ $nature };
			$done{ $nature } =1;
			push @ns, BaselinerX::CA::Harvest::Namespace::Nature->new({
				ns      => 'harvest.nature/' . $nature,
				ns_name => $nature,
				ns_type => _loc('Harvest Nature'),
				ns_id   => 0,
				ns_data => { $r->get_columns },
                provider=> 'namespace.harvest.nature',
			});
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
