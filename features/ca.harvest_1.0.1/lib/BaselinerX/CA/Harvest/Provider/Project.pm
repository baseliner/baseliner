package BaselinerX::CA::Harvest::Provider::Project;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::CA::Harvest::Namespace::Project;

with 'Baseliner::Role::Provider';

register 'namespace.harvest.project' => {
	name	=>_loc('Harvest Project'),
};

register 'namespace.harvest.project' => {
	name	=>_loc('Harvest Projects'),
	root    => 'harvest.project',
    can_job => 0,
	domain  => domain(),
    finder =>  \&find,
	handler =>  \&list,
};


sub namespace { 'BaselinerX::CA::Harvest::Namespace::Project' }
sub domain    { 'harvest.project' }

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
		my $rs = Baseliner->model('Harvest::Harenvironment')->search({ envobjid=>{ '>', '0'}, envisactive=>'Y' });
		my @ns;
		while( my $r = $rs->next ) {
			( my $env_short = $r->environmentname )=~ s/\s/_/g;
            push @ns, BaselinerX::CA::Harvest::Namespace::Project->new({
                ns      => 'harvest.project/' . $env_short,
                ns_name => $env_short,
				ns_type => _loc('Harvest Project'),
				ns_id   => $r->envobjid,
				ns_data => { $r->get_columns },
                provider=> 'namespace.harvest.project',
                related => [  ],
			});
		}
		return \@ns;
}

1;
