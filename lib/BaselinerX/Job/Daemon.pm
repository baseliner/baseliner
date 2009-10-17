package BaselinerX::Job::Daemon;
use Baseliner::Plug;
use Baseliner::Utils;

with 'Baseliner::Role::Service';

has 'proc_list' => ( is=>'rw', isa=>'ArrayRef', default=>sub { [] } );

register 'service.job.daemon' => {
    name    => 'Watch for new jobs',
    config  => 'config.job.daemon',
    handler => \&job_daemon,
};

register 'service.job.dummy' => {
	name => 'A Dummy Job',
	handler => sub {
		my ($self,$c)=@_;
		warn "DUMMY";
		$c->log->info("A dummy job is running");
	}
};

# daemon - listens for new jobs
use Proc::Background;
use Proc::Exists qw(pexists);
use Sys::Hostname;
sub job_daemon {
	my ($self,$c,$config)=@_;
	my $freq = $config->{frequency};
	while(1) {
        my $now = _now;

        # PRE chain
        {
            my @rs = $c->model('Baseliner::BaliJob')->search({ 
                status => 'READY', step=>'PRE',
                });
            foreach my $r ( @rs ) {
                _log "Starting job ". $r->name;
                $r->status('RUNNING');
                $r->update;
                #warn "$0 :: @ARGV";
                my $cmd = "perl $0 job.run --runner \"". $r->runner ."\" --step PRE --jobid ". $r->id;
                my $proc = Proc::Background->new( $cmd );
                push @{ $self->{proc_list} }, $proc;
                $r->pid( $proc->pid );
                $r->host( lc Sys::Hostname::hostname() );
                $r->owner( $ENV{USER} || $ENV{USERNAME} );
                $r->update;
            }
        }
        # RUN chain
        {
            my @rs = $c->model('Baseliner::BaliJob')->search({ 
                starttime => { '<' , $now }, 
                maxstarttime => { '>' , $now }, 
                status => 'READY', step=>'RUN',
                });
                if( ! @rs ) { 
                    _log "No jobs found for '$now'";	
                }
            foreach my $r ( @rs ) {
                _log "Starting job ". $r->name;
                $r->status('RUNNING');
                $r->update;
                my $cmd = "perl $0 job.run --runner \"". $r->runner ."\" --step RUN --jobid ". $r->id;
                my $proc = Proc::Background->new( $cmd );
                push @{ $self->{proc_list} }, $proc;
                $r->pid( $proc->pid );
                $r->host( lc Sys::Hostname::hostname() );
                $r->owner( $ENV{USER} || $ENV{USERNAME} );
                $r->update;
            }
        }
        # POST chain
        {
            my @rs = $c->model('Baseliner::BaliJob')->search({ 
                status => 'READY', step=>'POST',
                });
            foreach my $r ( @rs ) {
                _log "Starting job ". $r->name;
                $r->status('RUNNING');
                $r->update;
                my $cmd = "perl $0 job.run --runner \"". $r->runner ."\" --step POST --jobid ". $r->id;
                my $proc = Proc::Background->new( $cmd );
                push @{ $self->{proc_list} }, $proc;
                $r->pid( $proc->pid );
                $r->host( lc Sys::Hostname::hostname() );
                $r->owner( $ENV{USER} || $ENV{USERNAME} );
                $r->update;
            }
        }
        $self->check_job_expired($c);
		sleep $freq;	
	}
}

sub check_job_expired {
	my ($self,$c)=@_;
    #_log( "Checking for expired jobs..." );
    my $rs = $c->model('Baseliner::BaliJob')->search({ 
			maxstarttime => { '<' , _now }, 
			status => 'READY',
    });
    while( my $row = $rs->next ) {
		_log( "Job $row->{name} expired (maxstartime=" . $row->{maxstarttime});
		$row->status('EXPIRED');
		$row->update;
    }
    $rs = $c->model('Baseliner::BaliJob')->search({ 
			status => 'RUNNING',
    });
    while( my $row = $rs->next ) {
        _log "Checking row pid ". $row->pid;
		if( $row->pid ) {
			unless( pexists( $row->pid ) ) {
				_log _loc("Detected killed job %1", $row->name ); 
				$row->status('KILLED');
				$row->update;
			} else {
                #if( $^O eq 'MSWin32' ) {
                #    use Win32::Process;
                #    my $win_proc; 
                #    if( Win32::Process::Open( $win_proc, $row->pid ) ) {
                #        $win_proc->Kill;
                #    }

                #} else {
                #    _log "PID " . $row->pid . " ok.";
                #}
            }
		}
    }

    foreach my $proc ( @{ $self->{proc_list} } ) {
        unless( $proc->alive ) {
            $proc->die;
        }
    }
    return;
}

1;

