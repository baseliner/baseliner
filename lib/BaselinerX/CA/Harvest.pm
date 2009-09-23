package BaselinerX::CA::Harvest;
use Baseliner::Plug;
use Baseliner::Utils;
use File::Find::Rule;
extends 'BaselinerX::Type::Service';
use YAML::Syck;

#my $dbh = Baseliner->model('Harvest')->storage->dbh;
#if( $dbh->{Driver}->{Name} eq 'Oracle' ) {
	#$dbh->do("alter session set nls_date_format='yyyy-mm-dd hh24:mi:ss'");
#}

register 'config.harvest.db' => {
    name => 'Harvest DB Connection Data',
	metadata => [
		{ id=>'connection', label=>'Connection String', type=>'text' },
		{ id=>'username', label=>'User', type=>'text' },
		{ id=>'password', label=>'Password', type=>'text' },
	]
};

register 'config.ca.harvest.cli' => {
    name => 'Harvest Client Connection Data',
    metadata => [
        { id=>'broker', type=>'text' },
        { id=>'login', type=>'text' },
        { id=>'permissions', label=>'Checkout File Permissions', type=>'text' },
    ]
};

register 'config.ca.harvest.map' => {
    name => 'Harvest View, State and Baseline relationships',
    metadata => [
        { id=>'view_to_baseline', label=>'From View to Baseline', type=>'hash' },
    ]
};



use BaselinerX::Job::Elements;
register 'service.harvest.runner.package' => {
	name => 'Job Service for Harvest Packages',
    config=> 'config.ca.harvest.cli',
	handler => sub {
		my ($self,$c,$config) =@_;

		my $job = $c->stash->{job};
		my $log = $job->logger;
        my @contents = @{ $job->job_stash->{contents} || [] };
        my ( @elements, %co_packages );

		$log->debug( 'Iniciando Servicio de Paquetes de Harvest path=' . $job->{job_stash}->{path} );

        my $cli = new BaselinerX::CA::Harvest::CLI({ broker=>$config->{broker}, login=>$config->{login} });


        foreach my $job_item ( @contents ) {
            #my $data = YAML::Load( $job_item->{data} );
            my $data = $job_item->{data} ;
            $log->debug( "Item data for $job_item->{item}", data=>Dump($job_item->{data}) );
            my $r = $c->model('Harvest::Harpackage')->search(
                { packageobjid => $data->{packageobjid} },
                {
                    join     => [ 'state', 'modifier', 'envobjid' ],
                    prefetch => [ 'state', 'modifier', 'envobjid' ]
                }
            )->first;
            my $project = $r->envobjid->get_column('environmentname');
            my $state = $r->state->get_column('statename');
            my $vp = '/';
            my $package = $job_item->{item};
            my $mask = '*'; 
            # element list
            my $sv = $cli->select_versions( project=>$project, state=>$state, vp=>$vp, package=>$package, mask=>$mask );
            $log->info( "Versiones en el paquete '$package' " , data=>$sv->{msg} );
            $log->debug( "Versiones en el paquete '$package' (struct)" , data=>Dump $sv->{versions} );
            push @elements, @{ $sv->{versions} };
            $co_packages{$project}{$state}{$package} = $data;
        }
        # put elements into stash
        my $e = $job->job_stash->{elements} || BaselinerX::Job::Elements->new;
        $e->push_elements( @elements );
        $job->job_stash->{elements} = $e;
        # checkouts
        if( %co_packages ) {
            foreach my $project ( keys %co_packages ) {
                foreach my $state ( keys %{ $co_packages{$project} || {} } ) {
                    my $inf = $c->registry->get('config.harvest.transition.states')->factory($c, ns=>'/', bl=>$job->bl );
                    if( $job->bl ne 'DESA' ) { #TODO if bl ne current_state_view
                        # promote
                    }
                    # CO state
                    my $packages = $co_packages{$project}{$state}; 
                    $log->info( "Inicio Checkout del estado $project:$state. Espere...", Dump $packages );
                    my $co = $cli->run(
                        cmd      => 'hsync', 
                        -en  => $project,
                        -st    => $state,
                        -vp       => '/',
                        -cp       => $job->job_stash->{path},
                    );
                    $log->debug( "Resultado del Checkout del estado $project:$state", data=>$co->{msg}, data_name=>'CheckoutState' );
                    # CO packages trunk
                    if( $state =~ /^Desarrollo$/i ) {   #TODO state where package checkout is needed....
                        $packages = $co_packages{$project}{$state}; 
                        $log->info( "Inicio Checkout de Tronco de Paquetes $project:$state. Espere...", Dump $packages );
                        $co = $cli->run(
                            cmd      => 'hsync', 
                            -en  => $project,
                            -st    => $state,
                            -to       => undef,
                            -vp       => '/',
                            -cp       => $job->job_stash->{path},
                            -pl => [ keys %{$packages} ]
                        );
                        $log->debug( "Resultado del Checkout de Tronco de Paquetes $project:$state", data=>$co->{msg}, data_name=>'CheckoutTronco' );
                    }
                    if( 0 ) {
                        # CO packages branch  TODO multiple packages with branches will co randomly ?
                        $packages = $co_packages{$project}{$state}; 
                        $log->info( "Inicio Checkout de Rama de Paquetes $project:$state. Espere...", Dump $packages );
                        $co = $cli->run(
                            cmd      => 'hsync', 
                            -en  => $project,
                            -st    => $state,
                            -bo       => undef,
                            -vp       => '/',
                            -cp       => $job->job_stash->{path},
                            -pl => [ keys %{$packages} ]
                        );
                        $log->debug( "Resultado del Checkout de Rama de Paquetes $project:$state", data=>$co->{msg}, data_name=>'CheckoutRama' );
                    }
                    # change permissions 
                    my @files = File::Find::Rule->file()->name('*')->in( $job->job_stash->{path} );
                    my $file_cnt = chmod( oct($config->{permissions}) , @files ); 
                    my $path = $job->job_stash->{path};
                    $log->debug("Permisos cambiados a $config->{permissions} en $file_cnt ficheros en $path", data=>join("\n",@files) );
                    
                }
            }
        } else {
            $c->warn( 'No hay paquetes para checkout' );
        }

	}

};

register 'service.harvest.env_for_item' => {
	name => 'List Environments for Items',
	handler => \&envs_for_item,
};

my %ei_cache;
sub envs_for_item {
	my $iid = shift;
	return () unless $iid;
    return @{ $ei_cache{$iid} || []} if defined $ei_cache{$iid};
	my $item  = Baseliner->model('Harvest::Haritems')->search({ itemobjid=>$iid })->first;
	my $rid = $item->repositobjid;
	my $rep  = Baseliner->model('Harvest::Harrepository')->search({ repositobjid=>$rid })->first;
	my $rv = $rep->harrepinviews;
	my %envs;
	while( my $v = $rv->next ) {
		my $env = { $v->viewobjid->envobjid->get_columns };
		next if $env->{envobjid} eq 0;
		next if $envs{ $env->{envobjid} };
		$envs{ $env->{envobjid} } = $env;
	}
    $ei_cache{$iid} = [ values %envs ];
	return values %envs;
}

register 'config.harvest.subapl' => {
	metadata => [
		{ id=>'position', label=>_loc('Subapplication position within view path'), default=>3 },
	],
};

register 'config.harvest.nature' => {
	metadata => [
		{ id=>'position', label=>_loc('Nature position within view path'), default=>2 },
	],
};

register 'namespace.harvest.subapplication' => {
	name	=>_loc('Harvest Subapplication'),
	root    => 'application',
    can_job => 0,
	handler => sub {
		my ($self, $c, $p) = @_;
		my $rs = Baseliner->model('Harvest::Harpathfullname')->search(undef, { join=>['itemobjid'],prefetch =>['itemobjid'] });
		my @ns;
		my $config = Baseliner->registry->get('config.harvest.subapl')->data;
		my $cnt = $config->{position};
		while( my $r = $rs->next ) {
			my $path = $r->pathfullname;
			my @parts = split /\\/, $path;
			next unless @parts == ($cnt+1); ## the preceding \ counts as the first item
			my $subapl = $parts[$cnt];
			my @envs = envs_for_item( $r->itemobjid->itemobjid );
			for my $env ( @envs ) {
				( my $env_short =  $env->{environmentname} )=~ s/\s/_/g;
				push @ns, BaselinerX::CA::Harvest::Namespace::Subapplication->new({
					ns      => 'harvest.subapplication/' . $subapl,
					ns_name => $subapl,
					ns_type => _loc('Harvest Subapplication'),
					ns_id   => $env->{envobjid},
					ns_parent => '/apl/' . $env_short,
                    parent_class => [ 'application' ],
					ns_data => { $r->get_columns },
                    provider=> 'namespace.harvest.subapplication',
				});
			}
		}
		return \@ns;
	},
};

register 'namespace.harvest.nature' => {
	name	=>_loc('Harvest Nature'),
	root    => 'nature',
	mask    => '',
    can_job => 0,
	handler => sub {
		my ($self, $c, $p) = @_;
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
	},
};

#TODO provider or namespace? 
register 'provider.harvest.users' => {
	name	=>'Harvest Users',
	config	=> 'config.harvest.db',
	list	=> sub {
		my ($self,$b)=@_;
		
		my $conn = $b->stash->{'config.harvest.db.connection'};
		my $username = $b->stash->{'config.harvest.db.connection.username'};
		my $password = $b->stash->{'config.harvest.db.connection.password'};
		
		$b->log->debug('Providing the user list');
	},
};

register 'config.harvest.db.grid.package' => {
	metadata => [
		{ id=>'packagename', label=>'Package', type=>'text' },
		{ id=>'environmentname', label=>'Project', type=>'text' },
		{ id=>'statename', label=>'State', type=>'text' },
		{ id=>'viewname', label=>'View', type=>'text' },
		{ id=>'username', label=>'Asigned to', type=>'text' },
		{ id=>'formdata', label=>'Form', type=>'text' },
	]
};
BEGIN {  extends 'Catalyst::Controller' }

#__PACKAGE__->config->{namespace} = '/ca/harvest';
sub packages_json : Path('/ca/harvest/packages_json') {
	my ($self,$c) = @_;
	my $rs = $c->model('Harvest::Harpackage')->search({ packageobjid => { '>', '0' } });
	my @data;
	while( my $row = $rs->next ) {
		my $rs_af = $row->harassocpkgs;
		while( my $af = $rs_af->next ) {
			my $aa = $af->formobjid;
		}
		push @data, { 
			packageobjid => $row->packageobjid,
			packagename => $row->packagename,
		};
	}
	$c->stash->{json} = { data=> @data };
	$c->forward('View::JSON');
}

1;
