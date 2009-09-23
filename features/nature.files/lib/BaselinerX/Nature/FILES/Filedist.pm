package BaselinerX::Nature::FILES::Filedist;
use strict;
use Carp;
use File::Find;
use Error qw(:try);

sub new {
    my $class = shift();
    my ($ns,$bl) = @_;
    my @mappings = ();

    my $self = {
        bl  => $bl,
        ns => $ns,
        mappings => @mappings,
    };
    bless( $self, $class );
}

sub load {
	my $self = shift();
	my $c = shift();
	my @mappings = ();
	my $rs = $c->model('Baseliner::BaliFileDist')->search();
	while(my $r = $rs->next){
	    my $row = { $r->get_columns };
		push @mappings, { 
            ns => $row->{ns},
            bl => $row->{bl},
            value => $row,
        };
	}

    my @new_mappings = BaselinerX::Type::Config::best_match_on_viagra( $self->{ns}, $self->{bl}, @mappings  );
	
	$self->{mappings} = \@new_mappings;
}

sub save{
	my $self = shift();
	my $c = shift();
	my $mapping = shift();	
			
	my $rs = $c->model('Baseliner::BaliFileDist')->search({ ns=>$self->{ns}, bl=>$self->{bl}, id=>$mapping->{id} });	
			
	if (my $r = $rs->next){
		$r->set_columns($mapping);
		$r->update;
	}else{	
		my $r = $c->model('Baseliner::BaliFileDist')->create($mapping);				
		$r->update;
	}
		
}

sub delete {
	my $self = shift();
	my $c = shift();
	my $id = shift();
	
	BaselinerX::Nature::FILES::SSHScript->deleteByFileDist($c,$id);	
	my $rs = $c->model('Baseliner::BaliFileDist')->search({ ns=>$self->{ns}, bl=>$self->{bl}, id=>$id });
	if(my $r = $rs->next){
		$r->delete;		
	}
}

sub distribuir{
	my $self = shift();
	my $c = shift();
	my $path = shift();
	my @distribuciones = ();

	my $job = $c->stash->{job};
	my $log = $job->logger;  

	for my $mapeo (@{$self->{mappings}}){
		#my $mapeo = {$map->{value}};
		my $origen = $mapeo->{src_dir};
		use File::Spec;
	    $origen = File::Spec->catdir( $path, $origen );	
		
		my $destino = $mapeo->{dest_dir};
		my @filtros = split(";",$mapeo->{filter});
		my $opts = ($mapeo->{isrecursive} eq 1)?"":"-maxdepth 1";
		
		eval("$origen = '" . $mapeo->{src_dir} . "'") if(index($origen, "\$") > -1);
		eval("$destino = '" . $mapeo->{dest_dir} . "'") if(index($destino, "\$") > -1);
		
		$origen = "." if($origen eq "");

		$log->debug("Parseando mapeo.",data=>YAML::Dump($mapeo));		
		my $filename = "tarfile_dist_$mapeo->{id}.tar";	
		my $empaquetado = 1;
		for my $filtro (@filtros){
			my $tarflags = (-e "$origen/$filename")?"uvf":"cvf";
			my $command = "cd $origen ; find . -name \"$filtro\" -type f $opts | xargs tar $tarflags $origen/$filename";
			if(system($command)!=0){
				$log->warn("Fallo al empaquetar el mapeo $mapeo (Es posible que la ruta no exista para esta naturaleza).", data=> "Comando: $command\nError=$?");
				$empaquetado = 0;
				#die("No es posible empaquetar el mapeo $mapeo.");	
			}else{
				$empaquetado = 0 if(length($command)<20);
			}
		}		

		if($empaquetado == 1){
			push @distribuciones, {	id=>$mapeo->{id},
									dir_origen=>$origen,
									fichero=>$filename,
									dir_destino=>$destino,
									ssh=>$mapeo->{ssh_host}};
		}
		
	}

	$log->debug("Distribuciones generadas.",data=>YAML::Dump(@distribuciones));	
	$log->info("Ejecutando distribuciones de ficheros...");
	for my $distribucion (@distribuciones){
		$log->debug("Ejecutando distribucion.",data=>YAML::Dump($distribucion));

		my $fs_remoto = Baseliner::Core::Filesys->new( home=>'$distribucion->{ssh}' );
					
		my ($rc,$ret) = $fs_remoto->execute(qq{mkdir -p $distribucion->{dir_destino}});
		$log->warn("No se pudo crear el directorio de destino $distribucion->{dir_destino}.", data=>$ret) if($rc!=0);
		
		my $pathOrigen = File::Spec->catfile($distribucion->{dir_origen},$distribucion->{fichero});
		my $pathDestino = File::Spec->catfile($distribucion->{dir_destino},$distribucion->{fichero});
		
		($rc,$ret) = $fs_remoto->copy($pathOrigen,$distribucion->{dir_destino});
		if($rc!=0){
			$log->error("Error al copiar $pathOrigen en $distribucion->{dir_destino}.", data=>$ret);
			die("No es posible copiar el paquete de distribucion $distribucion->{fichero}.");	
		} 			
		
		($rc,$ret) = $fs_remoto->execute(qq{cd $distribucion->{dir_destino}; tar xvf $distribucion->{fichero}});
		if($rc!=0){
			$log->error("Error al desempaquetar $distribucion->{fichero} en $distribucion->{dir_destino}.", data=>$ret);
			die("No es posible desempaquetar $distribucion->{fichero}.");	
		} 			

		($rc,$ret) = $fs_remoto->execute(qq{cd $distribucion->{dir_destino}; rm $distribucion->{fichero}});
		$log->warn("No he podido eliminar el paquete temporal $distribucion->{dir_destino}/$distribucion->{fichero}, debera borrarse de forma manual.", data=>$ret) if($rc!=0);
		
		$fs_remoto->end();
		
		my @scripts = BaselinerX::Nature::FILES::SSHScript->getFromFileDistId($c,$distribucion->{id});	
		my @sorted_scripts =  sort { $a->{xorder} <=> $b->{xorder} } @scripts;
		
		for my $script (@sorted_scripts){
			my $script_command = $script->{script};
			my $script_params = $script->{params};
			$script_params =~ s/;/ /;			
			
			$log->debug("Ejecutando script: '$script_command $script_params'.",data=>YAML::Dump($script));
			$fs_remoto = Baseliner::Core::Filesys->new( home=>'$script->{ssh_host}' );
			($rc,$ret) = $fs_remoto->execute(qq{$script_command $script_params});
			if($rc!=0){
				$log->error("No es posible ejecutar  '$script_command $script_params'.", data=>$ret);
				die("El script '$script_command $script_params' ha devuelto un error.");	
			} 			
			$fs_remoto->end();			
			$log->info("El script '$script_command $script_params' se ha ejecutado correctamente.",data=>$ret);
		}
		
	}
	
	
	#my $listado = $fs_remoto->execute(qq{cd /opt/ca/pase/J2EE/bpe; find});
	
}

1;
