package BaselinerX::Job::Controller::Job;
use Baseliner::Plug;
use Baseliner::Utils;
use DateTime;
use YAML;
use JavaScript::Dumper;
use Baseliner::Core::Namespace;
use JSON::XS;
use utf8;

# comment
#  otro

BEGIN { extends 'Catalyst::Controller' }
BEGIN { 
    ## Oracle needs this
    $ENV{'NLS_DATE_FORMAT'} = 'YYYY-MM-DD HH24:MI:SS';
}

sub job_create : Path('/job/create')  {
    my ( $self, $c ) = @_;
	$c->forward('/namespace/load_namespaces'); # all namespaces
	$c->forward('/baseline/load_baselines_no_root');
    $c->stash->{template} = '/comp/job_new.mas';
}

sub job_items_json : Path('/job/items/json') {
    my ( $self, $c ) = @_;
	my $p = $c->req->params;
    # get namespaces that can_job
		#@ns_list = Baseliner::Core::Namespace->namespaces({ can_job=>1, bl=>$p->{bl}, job_type=>$p->{job_type}, query=>$p->{query} });
 warn ".............................JT=" . $p->{job_type};
    $c->stash->{ns_query} = { can_job=>1, bl=>$p->{bl}, job_type=>$p->{job_type}, query=>$p->{query} };
    $c->forward('/namespace/load_namespaces');
    my @ns_list = @{ $c->stash->{ns_list} || [] };
    # create json struct
	my @job_items;
	my $cnt=1;
	for my $n ( @ns_list ) {
        push @job_items,
          {
			id => $cnt++,
            provider => $n->provider,
            related => $n->related,
            ns_type  => $n->ns_type,
            icon     => $n->icon,
            item     => $n->ns_name,
            ns       => $n->ns,
            user     => $n->user,
            service  => $n->service,
            text     => $n->ns_info,
            date     => $n->date,
            data     => $n->ns_data
          };
	}
	$c->stash->{json} = {
		totalCount => scalar @job_items,
		data => [ @job_items ]
	};
	$c->forward('View::JSON');
}

sub monitor_json : Path('/job/monitor_json') {
    my ( $self, $c ) = @_;
	my $p = $c->request->parameters;
    my ($start, $limit, $query, $dir, $sort, $cnt ) = @{$p}{qw/start limit query dir sort/};
	my $rs = $c->model('Baseliner::BaliJob')->search(undef, { order_by => $sort ? "$sort $dir" : "id desc" });
	my @rows;
	while( my $r = $rs->next ) {
        my $step = _loc( $r->step );
        my $status = _loc( $r->status );
        my $type = _loc( $r->type );
        next if( $query && !query_array($query, $status, $step, $r->name, $r->comments, $r->type, $type, $r->bl, $r->owner, $r->username ));
        push @rows, {
            id           => $r->id,
            name         => $r->name,
            bl           => $r->bl,
            bl_text      => $r->bl,                        #TODO resolve bl name
            starttime    => $r->get_column('starttime'),
            maxstarttime => $r->get_column('maxstarttime'),
            endtime      => $r->get_column('endtime'),
            comments     => $r->get_column('comments'),
            username     => $r->get_column('username'),
            step         => $step,
            pid          => $r->get_column('pid'),
            owner        => $r->get_column('owner'),
            host         => $r->get_column('host'),
            status       => $status,
            status_code  => $r->status,
            type         => $type,
            runner       => $r->runner,
          }
          if ( ( $cnt++ >= $start ) && ( $limit ? scalar @rows < $limit : 1 ) );
	}
	$c->stash->{json} = { 
        totalCount=> scalar @rows,
        data => \@rows
     };	
	$c->forward('View::JSON');
}

sub monitor_json_from_config : Path('/job/monitor_json_from_config') {
    my ( $self, $c ) = @_;
	my $p = $c->request->parameters;
	my $config = $c->registry->get( 'config.job' );
	my @rows = $config->rows( query=> $p->{query}, sort_field=> $p->{'sort'}, dir=>$p->{dir}  );
	#my @jobs = qw/N0001 N0002 N0003/;
	#push @rows, { job=>$_, start_date=>'22/10/1974', status=>'Running' } for( $p->{dir} eq 'ASC' ? reverse @jobs : @jobs );
	$c->stash->{json} = { cat => \@rows };	
	$c->forward('View::JSON');
}

sub job_check_time : Path('/job/check_time') {
    my ( $self, $c ) = @_;
	my $p = $c->request->parameters;
	my $day = $p->{job_date};
    my $contents = decode_json $p->{job_contents};
    my @ns;
    for my $item ( @{ $contents || [] } ) {
        my $provider = $item->{provider};
        push @ns, @{ $item->{related} || [] };
        push @ns, $item->{ns};
        # 
    }
    warn "....................NS: " . join ',', @ns;
	# get calendar range list
    $c->stash->{day} = $day;
    $c->stash->{bl} = $p->{bl};
    $c->stash->{ns} = \@ns;
	$c->forward('/calendar/calendar_range');
    #warn Dump $c->stash->{calendar_range_expand} ; 
	$c->stash->{json} = { data => $c->stash->{calendar_range_expand} };	
	$c->forward('View::JSON');
}

sub job_submit : Path('/job/submit') {
    my ( $self, $c ) = @_;
	my $p = $c->request->parameters;
	my $config = $c->registry->get('config.job')->data;
	my $runner = $config->{runner};
	my $job_name;
    my $username = $c->user ? $c->user->username || $c->user->id : '';
	eval {
		if( $p->{action} eq 'delete' ) {
			my $job = $c->model('Baseliner::BaliJob')->search({ id=> $p->{id_job} })->first;
			die _loc('Job %1 is currently running and cannot be deleted')
				unless( $job->is_not_running );
			#$job->delete;
			$job->status( 'CANCELLED' );
            $job->update;
		}
		elsif( $p->{action} eq 'rerun' ) {
			my $job = $c->model('Baseliner::BaliJob')->search({ id=> $p->{id_job} })->first;
			die _loc('Job %1 not found.', $p->{id_job} ) unless $job;
			die _loc('Job %1 is currently running (%2) and cannot be rerun', $job->name, $job->status)
				unless( $job->is_not_running );

			my $now = DateTime->now;
			$now->set_time_zone(_tz);
			my $end = $now->clone->add( hours => 1 );
			my $ora_now =  $now->strftime('%Y-%m-%d %T');
			my $ora_end =  $end->strftime('%Y-%m-%d %T');
			$job->starttime( $ora_now );
			$job->maxstarttime( $ora_end );
			$job->status( 'READY' );
			$job->step( 'PRE' );
            $job->username( $username );
			$job->update;
		}
		else {
			my $bl = $p->{bl};
			my $comments = $p->{comments};
			my $job_date = $p->{job_date};
			my $job_time = $p->{job_time};
			my $job_type = $p->{job_type};
			my $contents = decode_json $p->{job_contents};
			die _loc('No job contents') if( !$contents );
			# create job
			my $start = parse_date('dd/mm/Y', "$job_date $job_time");
			#$start->set_time_zone('CET');
			my $end = $start->clone->add( hours => 1 );
			my $ora_start =  $start->strftime('%Y-%m-%d %T');
			my $ora_end =  $end->strftime('%Y-%m-%d %T');
			my $job = $c->model('Baseliner::BaliJob')->create(
				{
					name         => 'temp' . $$,
					starttime    => $ora_start,
					endtime      => $ora_end,
					maxstarttime => $ora_end,
					status       => 'IN-EDIT',
                    step         => 'PRE',
					type         => $job_type,
					ns           => '/',
					bl           => $bl,
                    username     => $username,
					runner       => $runner,
					comments     => $comments,
				}
			);
			$job_name = $c->model('Jobs')->job_name({ mask=>'%s.%s%08d', type=>$job_type, bl=>$bl, id=>$job->id });
			$job->name( $job_name );
			$job->update;
			# create job items
			my @item_list;
			for my $item ( @{ $contents || [] } ) {
				warn Dump $item;
				my $items = $c->model('Baseliner::BaliJobItems')->create({
					data => YAML::Dump($item->{data}),
					item => $item->{item},
					service => $item->{service}, 
					provider => $item->{provider}, 
					id_job => $job->id,
				});
				push @item_list, '<li>'.$item->{item}.' ('.$item->{ns_type}.')';
			}
			# log job items
			my $log = new BaselinerX::Job::Log({ jobid=>$job->id });
			$log->info('Contenido del pase', join'',@item_list );

			# let it run
			$job->status( 'READY' );
			$job->update;
		}
	};
	if( $@ ) {
        warn $@;
		$c->stash->{json} = { success => \0, msg => _loc("Error creating the job: ").$@ };
	} else {
		$c->stash->{json} = { success => \1, msg => _loc("Job %1 created", $job_name) };
	}
	$c->forward('View::JSON');	
}

sub monitor : Path('/job/monitor') {
    my ( $self, $c ) = @_;
    $c->languages( ['es'] );
	my $config = $c->registry->get( 'config.job' );
    $c->stash->{template} = '/comp/monitor_grid.mas';
}


1;
