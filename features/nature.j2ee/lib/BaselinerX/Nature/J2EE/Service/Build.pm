package BaselinerX::Nature::J2EE::Service::Build;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::Eclipse;
use BaselinerX::Eclipse::J2EE;
use BaselinerX::Session::ConfigState;
use BaselinerX::Nature::J2EE::Common;
use BaselinerX::Job::Elements;
use BaselinerX::Job::Element;
use BaselinerX::CA::Harvest::CLI::Version;
use YAML::Syck;

use utf8;

with 'Baseliner::Role::Service';

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
				 
					$elements = $elements->cut_to_subset( 'nature', 'J2EE' );
				
					my @packages = $elements->list('package');
					my @aplicaciones = $elements->list('application');
					my @naturalezas = $elements->list('nature');
					my @projects = $elements->list('project');
					my @subapls = $elements->list('subapplication'); 

                    if(@aplicaciones){
                      $log->info("Inicio <b>naturaleza</b> J2EE");
                      $log->debug("Paquetes", data=>YAML::Syck::Dump(@packages));
                      $log->debug("Aplicaciones", data=>YAML::Syck::Dump(@aplicaciones));
                      $log->debug("Proyectos", data=>YAML::Syck::Dump(@projects));
                      $log->debug("Sub-Aplicaciones", data=>YAML::Syck::Dump(@subapls));
			         
			         my @builds = ();
			         
			         foreach my $aplicacion ( @aplicaciones ) {
			         	 	my $sub_elements = $elements->cut_to_subset( 'application', $aplicacion );
							@packages = $sub_elements->list('package');
							@projects = $sub_elements->list('project');                  


							use File::Spec;
							my $path = $job_stash->{path}; 
							$path = File::Spec->catdir( $path, $aplicacion );
							$path = File::Spec->catdir( $path, 'J2EE' );
							$path = File::Spec->canonpath($path);
							
							my $Workspace = BaselinerX::Eclipse::J2EE->parse( workspace=>$path );

							$Workspace->cutToSubset( $Workspace->getRelatedProjects( @projects ) ) ;  
							my @EARS = $Workspace->getEarProjects();
							#my @WARS = $Workspace->getWebProjects();
							#my @EJBS = $Workspace->getEjbProjects();
							$log->debug("EARS=" . join ',', @EARS);
							
							
							foreach my $earprj ( @EARS ) {
								my $subaplicacion = $earprj;
								unless($subaplicacion =~ m/\.ear$/){
									$log->warn("La subaplicación $subaplicacion no tiene una nomenclatura correcta.","La subaplicación $subaplicacion deberia llamarse $subaplicacion.ear.")
								}
								$subaplicacion =~ s/\.ear$//g;
								$subaplicacion =~ s/EAR$//g;
								#TODO: Comprobar que ha reemplazado bien
								my $datos = $c->model('ConfigStore')->get( 'config.nature.j2ee.build', ns=>"subapplication/$subaplicacion", bl=>$job->bl );								
								$log->info("Parseando la subaplicación <b>$subaplicacion</b> J2EE", data=>YAML::Syck::Dump($datos));

								my @classpath = qw{/opt/ca/j2ee/lib};

								my @SUBAPL_PRJ = $Workspace->getChildren( $earprj );
								my $buildxml = $Workspace->getBuildXML( 
										mode=> 'ear',
										# static_ext => [ qw/jpg gif html htm js css/ ],
										# static_file_type => 'tar',                                                                    
										variables=> {
											'org.eclipse.jdt.USER_LIBRARY' => '/opt/ca/j2ee/harsol',
										},
										classpath=> [ @classpath ],
										ear => [ $earprj ],
										projects => [ @SUBAPL_PRJ ],
										j2ee_build_config=>$datos,
										);

								my $buildFileName = "build_$earprj.xml";
								my $buildFilePath = File::Spec->catfile( $path, $buildFileName );

								$log->info( "Fichero <b>build.xml</b> generado", data=>$buildxml->data, name=>'build.xml' );
								$buildxml->save($buildFilePath);
								$log->debug("Generacion de $buildFileName.",data=>Dump $Workspace->output());           


								$log->info("Generando $earprj...");

								my $ret = `cd $path; ant -buildfile $buildFileName 2>&1`;
								my $rc = $?;

								if($rc==0){
									$log->debug("Salida de ANT $buildFileName.", data=>$ret);           		

									my $earFilePath = File::Spec->catdir( $path, $datos->{build_path});
									$earFilePath = File::Spec->catfile( $earFilePath, $earprj );           	

									my $earLOB = BaselinerX::Nature::J2EE::Common->getFileLOB($earFilePath);
									if($earLOB!=-1){
										$log->info("Se ha generado el EAR $earprj.", data=>$earLOB, more=>'file', data_name=>$earprj );           		
									}else{
										$log->warn("Se ha generado el EAR $earprj pero no puedo acceder a él.", $earFilePath);           		
									}								           	

									push @builds, {application=>$aplicacion, subapplication=>$subaplicacion, ear_path=>$earFilePath, config=>$datos};
								} else {
									$log->error("No se ha podido generar el EAR $earprj con ANT $buildFileName.", data=>$ret);           	
									_throw "Error durante la construcción J2EE";
								}							
							}
			         }
				
				#Guardo todas las builds
				$job_stash->{builds} = \@builds;
               } 
          }
};
register 'menu.nature.j2ee' => { label => 'J2EE' };
register 'menu.nature.j2ee.build' => { label => 'Build', url_comp => '/j2ee/build', title=>'Build' };


1;
