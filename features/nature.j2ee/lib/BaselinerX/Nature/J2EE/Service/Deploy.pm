package BaselinerX::Nature::J2EE::Service::Deploy;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::Eclipse;
use BaselinerX::Eclipse::J2EE;
use Baseliner::Core::Filesys;
use BaselinerX::Session::ConfigState;
use BaselinerX::Nature::J2EE::Controller::Common;
use YAML::Syck;

use constant J2EE_TIPO_EAR => "EAR";
use constant J2EE_TIPO_PARCIAL => "PARCIAL";
use constant J2EE_TIPO_FICHEROS => "FICHEROS";

my @TipoDistribucionJ2EE =  [J2EE_TIPO_EAR,J2EE_TIPO_PARCIAL,J2EE_TIPO_FICHEROS];
	
extends 'BaselinerX::Type::Service';
register 'config.nature.j2ee.deploy' => {
          name=> _loc('J2EE Deploy Configuration'),
          metadata=> [
                      { id=>'ns', label=>_loc('Namespace'),  type=>'namespaces', url=>'/j2ee/deploy/json', reloadChildren=>\1 },
                      { id=>'bl', label=>_loc('Baseline'),  type=>'baselines', url=>'/j2ee/deploy/json', reloadChildren=>\1 },          
                      { id=>'was', label=>'Servidor WAS', type=>'text' },
                      { id=>'was_dir', label=>'Directorio destino(WAS)', type=>'text', extjs =>{width=>'250'} },
                      { id=>'xtype', label=>'Tipo (por defecto)', type=>'combo', store =>getTipoDistribuciones() },
                      
          ]
};

register 'service.nature.j2ee.deploy' => {
          name => _loc('J2EE Deploy Service'),
          config => 'config.nature.j2ee.deploy',   
          handler => sub {
                    my ( $self, $c )=@_;
                    my $job = $c->stash->{job};
                    my $log = $job->logger;  
                    my $job_stash = $job->job_stash;
					
					my $elements = $job_stash->{elements};					
					$elements = $elements->cut_to_subset( 'nature', 'J2EE' );					
					my @aplicaciones = $elements->list('application');
					my @subapls = $elements->list('subapplication'); 
					
                    $log->info("Inicio <b>despliegue</b> J2EE");
			         foreach my $aplicacion ( @aplicaciones ) {
                            my $datos = $c->model('ConfigStore')->get( 'config.nature.j2ee.deploy', ns=>"application/$aplicacion", bl=>$job->bl );
	                   	 $log->info("Desplegando <b>$aplicacion</b> J2EE", data=>Dump($datos));
						 	use File::Spec;
						    my $path = $job_stash->{path}; 
						    $path = File::Spec->catdir( $path, $aplicacion );
						    $path = File::Spec->catdir( $path, 'J2EE' );
						    $path = File::Spec->canonpath($path);	              
					
							#TODO: Hay que adaptar el funcionamiento de esto al factory
							#my $filedist = BaselinerX::Nature::FILES::Filedist->new( '/application/$aplicacion', $job->bl );    	  
							my $filedist = BaselinerX::Nature::FILES::Filedist->new( '/application/$aplicacion', $job->bl );
							$filedist->load($c);
							$filedist->distribuir($c,$path);
			        }
          }            
};

register 'menu.nature.j2ee.deploy' => { label => 'Deploy', url_comp => '/j2ee/deploy', title=>'Deploy' };


sub getTipoDistribuciones{
	return @TipoDistribucionJ2EE;
}

1;
