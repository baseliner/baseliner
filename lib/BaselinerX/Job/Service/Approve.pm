package BaselinerX::Job::Service::Approve;
use Baseliner::Plug;
use Baseliner::Utils;
use utf8;

with 'Baseliner::Role::Service';

register 'service.job.approve' => { name => 'Job Approval', config => 'config.job.runner', handler => \&run, };
register 'action.job.approve' => { name=>_loc('Approve jobs') };

our %next_step = ( PRE => 'RUN',   RUN => 'POST',  POST => 'END' );
our %next_state  = ( PRE => 'READY', RUN => 'READY', POST => 'FINISHED' );

sub run {
    my ( $self, $c, $config ) = @_;
    
	my $job = $c->stash->{job};
	my $log = $job->logger;

    my $bl = $job->job_data->{bl};
    $log->debug( "Verificando si hay aprobaciones para $bl" );

    for my $item ( _array $job->job_stash->{contents} )  {
        my $item_ns = 'endevor.package/' . $item->{item};   #TODO get real ns names
        $log->info( _loc('Requesting approval for baseline %1, item %2', $bl, $item_ns ) );
            Baseliner->model('Request')->request(
                name   => 'Aprobación del pase N.DESA1029210',
                action => 'action.job.approve',
                vars   => { reason=>"promoción a $bl" },
                ns     => '/GBP.0000',
                bl     => $bl, 
            );
    }
}

1;
