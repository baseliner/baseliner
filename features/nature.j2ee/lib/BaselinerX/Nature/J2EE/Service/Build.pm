package BaselinerX::Nature::J2EE::Service::Build;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::Eclipse;
use BaselinerX::Eclipse::J2EE;
use Baseliner::Core::Filesys;
use BaselinerX::Session::ConfigState;
use BaselinerX::Nature::J2EE::Controller::Common;
use BaselinerX::Job::Elements;
use BaselinerX::Job::Element;
use BaselinerX::CA::Harvest::CLI::Version;
use YAML::Syck;

extends 'BaselinerX::Type::Service';
register 'config.nature.j2ee.build' => {
          name=> _loc('J2EE Build Configuration'),
          metadata=> [
                      { id=>'ns', label=>_loc('Namespace'),  type=>'namespaces', url=>'/j2ee/build/json' },
                      { id=>'bl', label=>_loc('Baseline'),  type=>'baselines', url=>'/j2ee/build/json' },
                      { id=>'host', label=>'Host de staging', type=>'text', nullable=>0, vtype=>'alphanum' },
                      { id=>'user', label=>'Usuario', type=>'text', nullable=>0, vtype=>'alphanum' },
                      { id=>'was_lib', label=>'WAS lib', type=>'text', nullable=>0, extjs =>{width=>'250'} },
                      { id=>'jdk', label=>'JDK', type=>'text', nullable=>1, extjs =>{width=>'250'}  },
                      { id=>'build_path', label=>'Carpeta build', type=>'text', nullable=>0, extjs =>{width=>'250'}  },
                      { id=>'classpath', type=>'listbox', nullable=>1, 
                      	title=>'Listado de ClassPaths',
			          	width=>350, height=>200,
			          	newLabel=>'Nuevo ClassPath',
			          	delLabel=>'Eliminar ClassPath'            	
                      },
          ]
};

register 'service.nature.j2ee.build' => {
          name => _loc('J2EE Build Service'),
          config => 'config.nature.j2ee.build',
          handler => sub {
                    my ( $self, $c )=@_;
                    
                    my $job = $c->stash->{job};
                    my $log = $job->logger;  
                    my $job_stash = $job->job_stash;
					
					my $elements = $job_stash->{elements};
					
					$log->debug("Elementos", data=>YAML::Syck::Dump($elements));
					 
					$elements = $elements->cut_to_subset( 'nature', 'J2EE' );

					$log->debug("Elementos Subset", data=>YAML::Syck::Dump($elements));
					
					my @packages = $elements->list('package');
					my @aplicaciones = $elements->list('application');
					my @naturalezas = $elements->list('nature');
					my @projects = $elements->list('project');
					my @subapls = $elements->list('subapplication'); 

#					# bucle elementos (Ejemplo de uso):					
#					foreach my $e ( $elements->elements ) {					
#					            print $e->version;					
#					            print $e->path;					
#					            # partes del path: /application/nature/project					
#					            print $e->path_part(‘application’);					
#					            print $e->path_part(‘project’);					
#					            print $e->path_part(‘nature’);					
#					            print $e->subapplication;  # no es un “path part”, sino que se calcula a partir del path_part(“project”)
#					
#					}                     
                      $log->info("Inicio <b>naturaleza</b> J2EE") if(@aplicaciones);
                      $log->debug("Paquetes", data=>YAML::Syck::Dump(@packages));
                      $log->debug("Aplicaciones", data=>YAML::Syck::Dump(@aplicaciones));
                      $log->debug("Proyectos", data=>YAML::Syck::Dump(@projects));
                      $log->debug("Sub-Aplicaciones", data=>YAML::Syck::Dump(@subapls));
			         
			         foreach my $aplicacion ( @aplicaciones ) {
                          my $datos = $c->model('ConfigStore')->get( 'config.nature.j2ee.build', ns=>"application/$aplicacion", bl=>$job->bl );
                          $log->info("Parseando la aplicación <b>$aplicacion</b> J2EE", data=>YAML::Syck::Dump($datos));
	                      
	                      use File::Spec;
	                      my $path = $job_stash->{path}; 
	                      $path = File::Spec->catdir( $path, $aplicacion );
	                      $path = File::Spec->catdir( $path, 'J2EE' );
	                      $path = File::Spec->canonpath($path);
	                      #my $path = "$job_stash->{path}/$aplicacion/J2EE";
	                      
	                      $log->debug("PATH: $path");
	                      $log->debug("PROYECTO: $aplicacion");
	                      $log->debug( "SUBAPLS: ", data=>YAML::Syck::Dump(@subapls));
	                      my $Workspace = BaselinerX::Eclipse::J2EE->parse( workspace=>$path, j2ee_build_config=>$datos, job=>$job );
#	                      #my @PROYECTOS = qw/AppBPE/;  ## $c->stash->{job}->{subapls};
	                      $Workspace->cutToSubset( $Workspace->getRelatedProjects( @projects ) ) ;  
	                      my @EARS = $Workspace->getEarProjects();
#	                      my @WARS = $Workspace->getWebProjects();
#	                      my @EJBS = $Workspace->getEjbProjects();
	                      $log->debug("EARS=" . join ',', @EARS);
#	                      warn "\nWARS=" . join ',', @WARS;
#	                      warn "\nEJBS=" . join ',', @EJBS;
	                      foreach my $earprj ( @EARS ) {
	                                 my @SUBAPL_PRJ = $Workspace->getChildren( $earprj );
	                                 warn "Proyectos children del $earprj: ". join',',@SUBAPL_PRJ;
	                                 my $buildxml = $Workspace->getBuildXML( 
	                                                         mode=> 'ear',
	                                                         # static_ext => [ qw/jpg gif html htm js css/ ],
	                                                         # static_file_type => 'tar',                                                                    
	                                                         ear => [ $earprj ],
	                                                         projects => [ @SUBAPL_PRJ ],
	                                 );
	                                 
	                                 warn "BUILDXML=" . $buildxml;
	                                 #antBuild(\%Dist, $buildfileBaseliner, $earfile ,$subapl, "clean build package", $buildtype, @OUTPUT )
	                                 my $buildFileName = "build_$earprj.xml";
	                                 my $buildFilePath = File::Spec->catfile( $path, $buildFileName );
	                                 
	                                 $buildxml->save($buildFilePath);
	                                 $log->debug("Generacion de $buildFileName.",data=>Dump $Workspace->output());	                                 
	                                 
#	                                 my @OUTPUT = $Workspace->output();
#	                                 for( @OUTPUT ) {
#	                                             print "SALIDA=" . Dump $_;
#	                                 }
	                                 
	                                 $log->info("Generando $earprj...");
	                                 
	                                 my $ret = `cd $path; ant -buildfile $buildFileName`;
	                                 my $rc = $?;
	                                 
	                                 if($rc==0){
	                                 	my $earFilePath = File::Spec->catdir( $path, $datos->{build_path});
										$earFilePath = File::Spec->catfile( $earFilePath, $earprj );	                                 	
	                                 	my $earLOB = getFileLOB($earFilePath);
	                                 	if($earLOB!=-1){
		                                 	$log->debug("Salida de ANT $buildFileName.", data=>$ret);	                                 		
		                                 	$log->info("Se ha generado el EAR $earprj.", data=>$earLOB, more=>'file', data_name=>$earprj );	                                 		
	                                 	}else{
	                                 		$log->warn("Se ha generado el EAR $earprj pero no puedo acceder a él.", data=>$ret);	                                 		
	                                 	}
	                                 }else{
	                                 	$log->error("No se ha podido generar el EAR $earprj con ANT $buildFileName.", data=>$ret);	                                 	
	                                 }
	                      }
	                      
	
	                      #my $earfile = $Workspace->genfile($earprj);    
	                      #my $buildfileBaseliner = "build_$subapl.xml";
	                      #$buildxml->save($Dist{buildhome}."/".$buildfileBaseliner);
	                      #loginfo "Fichero <b>build.xml</b> para la subaplicacion <b>$subapl</b> y los proyectos: <li>".(join '<li>',@SUBAPL_PRJ), $buildxml->data;
	                      #loginfo "Ficheros que se generarán en la construcción de $earprj:<br><li>". join '<li>', $Workspace->genfiles();
	
	                      ## BUILD
	                      #my @OUTPUT = $Workspace->output();

			         }
                      
          }
};
register 'menu.nature.j2ee' => { label => 'J2EE' };
register 'menu.nature.j2ee.build' => { label => 'Build', url_comp => '/j2ee/build', title=>'Build' };

sub getFileLOB {
    my $filePath = shift();
	my $buff = qq{};
    open( FL, "<$filePath" ) or return -1;
	binmode(FL); 
	read(FL, $buff, 20, 0);    
	close FL;
    return ($buff);
	
}


1;
