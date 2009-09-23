package BaselinerX::Job::Model::Jobs;
use Moose;
extends qw/Catalyst::Component::ACCEPT_CONTEXT Catalyst::Model/;
use namespace::clean;
use Baseliner::Utils;

sub get {
    my ($self, $job_name ) = @_;
    my $c = $self->context;
    return $c->model('Baseliner::BaliJob')->search({ name=>$job_name })->first;
}

sub list_by_type {
    my $self = shift ;
    my @types = @_;
    my $c = $self->context;
    return $c->model('Baseliner::BaliJob')->search({ type=>{ -in => [ @types ] } });
}

sub check_scheduled {
    my $self = shift;
    my $c = $self->context;
    my @services = $c->model('Services')->search_for( scheduled=>1 );
    foreach my $service ( @services ) {
        my $frequency = $service->frequency;
        unless( $frequency ) {
            $frequency = $c->model('Config')->get( $service->frequency_key );
        }
        if( $frequency ) {
            my $last_run = $c->model('Baseliner::BaliJob')->search({ runner=> $service->key }, { order_by=>'starttime desc' })->first;
        }
    }
}

sub job_name {
    my $self = shift;
	my $p = shift;
	my $prefix = $p->{type} eq 'promote' ? 'N' : 'B';
	return sprintf( $p->{mask}, $prefix, $p->{bl} eq '*' ? 'ALL' : $p->{bl} , $p->{id} );
}

# deprecated: (??)
sub create_job {
	my ($self,$config)=@_;
    my $c = $self->context;
	my $status = $config->{status};
	#my $rs = $c->model('Harvest::Harpackage')->search();
	#while( my $r = $rs->next ) {
	#	warn "P=" . $r->packagename
	#}
	#$c->inf_write( ns=>'/job', bl=>'DESA', key=>'config.job.jobid', value=>$jobid ); 	
	my $now = DateTime->now;
	$now->set_time_zone('CET');
	my $end = $now->clone->add( hours => 1 );
    my $ora_now =  $now->strftime('%Y-%m-%d %T');
    my $ora_end =  $end->strftime('%Y-%m-%d %T');
    #require DateTime::Format::Oracle;
    #my $ora_now = DateTime::Format::Oracle->format_datetime( $now );
    #my $ora_end = DateTime::Format::Oracle->format_datetime( $end );
    #warn "ORA=$ora_now";
	my $job = $c->model('Baseliner::BaliJob')->create({ name=>'temp'.$$, starttime=> $ora_now, endtime=>$ora_end, maxstarttime=>$ora_end, status=> $status, ns=>'/', bl=>'*' });
	my $name = $config->{name} 
        || $c->model('Jobs')->job_name({ mask=>$config->{mask}, type=>'promote', bl=>$c->inf_bl, id=>$job->id });
	$config->{runner} && $job->runner( $config->{runner} );
	#$config->{chain} && $job->chain( $config->{chain} );
	warn "Creating JOB $name";
	$job->name( $name );
	$job->update;
	return $name;
}

1;
