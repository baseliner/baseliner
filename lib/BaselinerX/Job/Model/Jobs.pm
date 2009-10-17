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

sub cancel {
	my ($self, %p )=@_;
	my $job = Baseliner->model('Baseliner::BaliJob')->search({ id=> $p{id} })->first;
	if( ref $job ) {
		_throw _loc('Job %1 is currently running and cannot be deleted')
			unless( $job->is_not_running );
		$job->delete if $job->status =~ /^CANCELLED/;
		$job->status( 'CANCELLED' );
		$job->update;
	} else {
		_throw _loc('Could not find job id %1', $p{id} );
	}
}

sub create {
	my ($self, %p )=@_;

	my $ns = $p{ns} || '/';
	my $bl = $p{bl} || '*';

	my $contents = $p{items} || $p{contents};

	my $config = Baseliner->model('ConfigStore')->get( 'config.job' );

	my $status = $p{status} || 'IN-EDIT';
	#$now->set_time_zone('CET');
    my $now = DateTime->now(time_zone=>_tz);
	my $end = $now->clone->add( hours => 1 );
	my $start_time = $p{start_time} || $now;
	my $end_time = $p{end_time} || $end ;

	#if( is_oracle ) {
		$start_time =  $start_time->strftime('%Y-%m-%d %T');
		$end_time =  $end_time->strftime('%Y-%m-%d %T');
	#}
    my $job = Baseliner->model('Baseliner::BaliJob')->create({
            name         => 'temp' . $$,
            starttime    => $start_time,
            endtime      => $end_time,
            maxstarttime => $end_time,
            status       => $status,
            step         => $p{step} || 'PRE',
            type         => $p{type} || $p{job_type} || $config->{type},
            runner       => $p{runner} || $config->{runner},
			username     => $p{username} || $config->{username} || 'internal',
            comments     => $p{comments},
            ns           => $ns,
            bl           => $bl,
	});

	# setup name
	my $name = $config->{name} 
        || $self->job_name({ mask=>$config->{mask}, type=>'promote', bl=>$bl, id=>$job->id });

	$config->{runner} && $job->runner( $config->{runner} );
	$config->{chain} && $job->chain( $config->{chain} );

	$job->name( $name );
	$job->update;

	# create job items
	if( ref $contents eq 'ARRAY' ) {
		my @item_list;
		for my $item ( _array $contents ) {
			$item->{ns} ||= $item->{item};
			_throw _loc 'Missing item ns name' unless $item->{ns};
			my $items = $job->bali_job_items->create({
					data => YAML::Dump($item->{data} || $item->{ns_data} ),
					item => $item->{ns},
					service => $item->{service}, 
					provider => $item->{provider}, 
					id_job => $job->id,
				});
			#$items->update;
			push @item_list, '<li>'.$item->{ns}.' ('.$item->{ns_type}.')';
		}
		# log job items
		my $log = new BaselinerX::Job::Log({ jobid=>$job->id });
		$log->info('Contenido del pase', join'',@item_list );
	}

	# now let it run
	$job->status( 'READY' );
	$job->update;
	return $job;
}

1;
