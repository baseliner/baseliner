package BaselinerX::CA::Harvest::Service::Job;
use Baseliner::Plug;
use Baseliner::Utils;

use utf8;

with 'Baseliner::Role::Service';

register 'config.harvest.job' => {
	metadata=> [
		{ id=>'name', label => 'Job Name', type=>'text', width=>180 },
		{ id=>'job_type', label => 'Job Type', type=>'text', },
		{ id=>'project', label => 'Harvest Project', type=>'text', },
		{ id=>'from_state', label => 'From State', type=>'text', },
		{ id=>'to_state', label => 'To State', type=>'text', },
		{ id=>'start', label => 'Start Time', type=>'text', },
		{ id=>'end', label => 'End Time', type=>'text', },
		{ id=>'username', label => 'Creator', type=>'text', },
		{ id=>'package', label => 'Comment', type=>'list' },
		{ id=>'comment', label => 'Comment', type=>'text' },
	],
}; 

register 'service.harvest.job.new' => {
	name => 'Schedule a new job from selecting Harvest Packages',
	config => 'config.harvest.job',
	handler => \&run,
};

sub run {
	my ($self, $c, $p ) = @_;
	my $bl = $p->{bl};
	*STDERR = *STDOUT;  # send stderr to stdout to avoid false error msg logs
	#_log _dump $p;
	_throw _loc('Missing parameter package') unless defined $p->{package};
	my @contents;
	@contents = map { 
		my $item = Baseliner->model('Namespaces')->get( "harvest.package/$_" );
		_throw _loc 'Could not find package "%1"', $_ unless ref $item;
		$item;
	} _array( $p->{package} ); 

	my $job_type = $p->{job_type};
	_throw "Parameter --to_state needs a --job_type of either 'promote' or 'demote'" 
		if( $p->{to_state} && $job_type !~ m/promote|demote/ );
	#_log _dump \@contents;
    my $job = $c->model('Model::Jobs')->create(
        bl       => $bl,
        type     => $job_type,
        username => $p->{username},
        runner   => $p->{runner},
        comments => $p->{comments},
        items    => [ @contents ]
    );
	$job->update;

	# store parameters for later use
	#$p->{to_state} = Encode::encode_utf8( $p->{to_state} );
	my $stash = _load $job->stash;
	$stash->{harvest_data} = $p;
	$job->stash( _dump $stash );
	$job->update;

	print _loc( "Created job %1 of type %2 ok.", $job->name, $job->type );
}

=head1 USAGE

perl f:\dev\baseliner\script\bali.pl harvest.job.new
	--bl DESA
	--job_type promote
	--username "[user]"
	--project "[project]"
	--from_state "[state]"
	--to_state "[state]"
	--packages ["package"]

=cut
1;
