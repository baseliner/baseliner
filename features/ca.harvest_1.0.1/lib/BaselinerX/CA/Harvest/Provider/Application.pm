package BaselinerX::CA::Harvest::Provider::Application;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::CA::Harvest::Namespace::Application;

with 'Baseliner::Role::Provider';

register 'namespace.harvest.application' => {
	name	=>_loc('Application'),
	domain  => domain(),
	can_job => 1,
    finder =>  \&find,
	handler =>  \&list,
};

sub namespace { 'BaselinerX::CA::Harvest::Namespace::Application' }
sub domain    { 'harvest.application' }

sub find {
    my ($self, $item ) = @_;
	my $rs = Baseliner->model('Harvest::Harenvironment')->search({ environmentname=>$item });
	my $row = $rs->first;
	if( ref $row ) {
		my $app = BaselinerX::CA::Harvest::Project::get_apl_code($row->environmentname);
		return BaselinerX::CA::Harvest::Namespace::Application->new({
				ns      => 'application/' . $app,
				ns_name => $app,
				ns_type => _loc('Application'),
				ns_id   => $app,
				ns_data => { $row->get_columns },
				provider=> 'namespace.harvest.application',
				related => [  ],
				});
	}
	#$self->not_implemented;
    #my $package = Baseliner->model('Harvest::Harpackage')->search({ packagename=>$item })->first;
    #return BaselinerX::CA::Harvest::Namespace::Package->new({ row => $package }) if( ref $package );
}

sub get { find(@_) }

sub list {
    my ($self, $c, $p) = @_;
    my $bl = $p->{bl};
    my $job_type = $p->{job_type};
    my $query = $p->{query};
    my $sql_query;
return [];
		my $rs = Baseliner->model('Harvest::Harenvironment')->search({ envobjid=>{ '>', '0'}, envisactive=>'Y' });
        my %apps;
		while( my $r = $rs->next ) {
			my $env_short = BaselinerX::CA::Harvest::Project::get_apl_code($r->environmentname);
            $apps{ $env_short }{ $r->environmentname } = { data=>{ $r->get_columns } };
		}
		my @ns;
        foreach my $app ( keys %apps ) {
            push @ns, BaselinerX::CA::Harvest::Namespace::Application->new({
                ns      => 'application/' . $app,
                ns_name => $app,
				ns_type => _loc('Application'),
				ns_id   => $app,
				ns_data => $apps{ $app },
                provider=> 'namespace.harvest.application',
                related => [  ],
			});
        }
		return \@ns;
}

1;
