package BaselinerX::Job::Service::Purge;
use Baseliner::Plug;
use Baseliner::Utils;
use Path::Class;
use BaselinerX::Job::Elements;
use Carp;
use Try::Tiny;
use utf8;

with 'Baseliner::Role::Service';

register 'service.job.purge.files' => {
	name => 'Purge job directories',
    scheduled => 1,
    frequency_key => 'config.job.purge.files.frequency',
	config => 'config.job',
	handler => \&run,
};

sub run {
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
}

1;
