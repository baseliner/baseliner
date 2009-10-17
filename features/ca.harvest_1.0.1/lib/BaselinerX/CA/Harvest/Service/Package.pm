package BaselinerX::CA::Harvest::Service::Package;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::Job::Elements;

with 'Baseliner::Role::Service';

register 'service.harvest.checkout' => {
	name => 'Job Service for Harvest Packages',
    config=> 'config.ca.harvest.cli',
	handler => \&run 

};

sub run {
	my ($self,$c,$config) =@_;

	my $job = $c->stash->{job};
	my $log = $job->logger;
	my @contents = _array $job->job_stash->{contents};
	my ( @elements, %co_packages );

	$log->debug( 'Iniciando Servicio de Paquetes de Harvest path=' . $job->{job_stash}->{path} );

	my $cli = new BaselinerX::CA::Harvest::CLI({ broker=>$config->{broker}, login=>$config->{login} });

	foreach my $job_item ( @contents ) {
		#my $data = YAML::Load( $job_item->{data} );
		my $data = $job_item->{data} ;
		$log->debug( "Item data for $job_item->{item}", data=>_dump($job_item->{data}) );
        my $r = $c->model('Harvest::Harpackage')->search(
            { packageobjid => $data->{packageobjid} },
            {
                join     => [ 'state', 'modifier', 'envobjid' ],
                prefetch => [ 'state', 'modifier', 'envobjid' ]
            }
        )->first;
        my $project = $r->envobjid->get_column('environmentname');
        my $state   = $r->state->get_column('statename');
        my $vp      = '/';
        my ( $domain, $package ) = ns_split( $job_item->{item} );
        $package or _throw 'Missing package name';
        my $mask = '*';

        # element list
        my $sv = $cli->select_versions(
            project => $project,
            state   => $state,
            vp      => $vp,
            package => $package,
            mask    => $mask
        );
        $log->info( "Versiones en el paquete '$package' ", data => $sv->{msg} );
        $log->debug( "Versiones en el paquete '$package' (struct)",
            data => _dump( $sv->{versions} ) );
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
				my $inf = $c->model('ConfigStore')->get('config.harvest.transition.states', ns=>'/', bl=>$job->bl );
				if( $job->bl ne 'DESA' ) { #TODO if bl ne current_state_view
					# promote
				}
				# CO state
				my $packages = $co_packages{$project}{$state}; 
				$log->info( "Inicio Checkout del estado $project:$state. Espere...", _dump $packages );
				my $co = $cli->run(
						cmd      => 'hsync', 
						-en  => $project,
						-st    => $state,
						-vp       => '/',
						-cp       => $job->job_stash->{path},
						);
				_throw _loc 'Error during state checkout: %1', $co->{msg} if $co->{rc};
				$log->debug( "Resultado del Checkout del estado $project:$state", data=>$co->{msg}, data_name=>'CheckoutState' );
				# CO packages trunk
				if( $state =~ /^Desarrollo$/i ) {   #TODO state where package checkout is needed....
					$packages = $co_packages{$project}{$state}; 
					$log->info( "Inicio Checkout de Tronco de Paquetes $project:$state. Espere...", _dump $packages );
					$co = $cli->run(
							cmd      => 'hsync', 
							-en  => $project,
							-st    => $state,
							-to       => undef,
							-vp       => '/',
							-cp       => $job->job_stash->{path},
							-pl => [ keys %{$packages} ]
							);
					_throw _loc 'Error during trunk checkout: %1', $co->{msg} if $co->{rc};
					$log->debug( "Resultado del Checkout de Tronco de Paquetes $project:$state", data=>$co->{msg}, data_name=>'CheckoutTronco' );
				}
				if( 0 ) {
					# CO packages branch  TODO multiple packages with branches will co randomly ?
					$packages = $co_packages{$project}{$state}; 
					$log->info( "Inicio Checkout de Rama de Paquetes $project:$state. Espere...", _dump $packages );
					$co = $cli->run(
							cmd      => 'hsync', 
							-en  => $project,
							-st    => $state,
							-bo       => undef,
							-vp       => '/',
							-cp       => $job->job_stash->{path},
							-pl => [ keys %{$packages} ]
							);
					_throw _loc 'Error during branch checkout: %1', $co->{msg} if $co->{rc};
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

1;
