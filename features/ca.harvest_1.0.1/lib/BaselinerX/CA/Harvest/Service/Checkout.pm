package BaselinerX::CA::Harvest::Service::Checkout;
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

	my %vp;

	foreach my $job_item ( @contents ) {
		#my $data = YAML::Load( $job_item->{data} );
		my $item = $job_item->{item};
		my $data = $job_item->{data} ;
		my $ns_package = $c->model('Namespaces')->get( $item ); 
		next unless ref $ns_package;
		next unless $ns_package->isa('BaselinerX::CA::Harvest::Namespace::Package');
		$log->debug( "Item data for $item", data=>_dump($job_item->{data}) );

		# get viewpaths for checkout
		my @paths = $ns_package->viewpaths(2);
		@vp{ @paths } = ();
		$log->debug( "Paths for package", data=>_dump(\@paths) );

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
        my ( $domain, $package ) = ns_split( $item );
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
	unless( scalar @elements ) {
		$log->warn( 'No hay elementos para checkout de Harvest' );
		return;
	}

	# put elements into stash
	$log->info( "Listado de elementos de Harvest", data=>_dump \@elements );
	my $e = $job->job_stash->{elements} || BaselinerX::Job::Elements->new;
	$e->push_elements( @elements );
	$job->job_stash->{elements} = $e;
	my @natures = $e->list('nature');
	$log->info( _loc('Naturalezas incluidas en el pase'), data=>_dump(\@natures) );

	# checkouts
	unless( %co_packages ) {
		$log->warn( 'No hay paquetes para checkout' );
	} else {
		foreach my $project ( keys %co_packages ) {
			foreach my $state ( keys %{ $co_packages{$project} || {} } ) {
				# CO state
				my $packages = $co_packages{$project}{$state}; 
				foreach my $vp ( keys %vp ) {
					my $cp = $job->job_stash->{path} . $vp;
					#$cp = File::Spec->catpath( $cp, $vp );
					$log->info( "Inicio Checkout del estado $project:$state:$vp a '$cp'. Espere...", _dump $packages );
					my $co = $cli->run(
							cmd      => 'hsync', 
							-en      => $project,
							-st      => $state,
							-vp      => $vp,
							-cp      => $cp,
							);
					_throw _loc 'Error during state checkout: %1', $co->{msg} if $co->{rc};
					$log->debug( "Resultado del Checkout del estado $project:$state:$vp", data=>$co->{msg}, data_name=>'CheckoutState' );
				}

				# CO packages trunk
				if( $state =~ /^Desarrollo$/i ) {   #TODO state where package checkout is needed....
					$packages = $co_packages{$project}{$state}; 
					$log->info( "Inicio Checkout de Tronco de Paquetes $project:$state. Espere...", _dump $packages );
					my $co = $cli->run(
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
					my $co = $cli->run(
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
	}

}

1;
