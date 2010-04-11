package BaselinerX::Nature::J2EE::Controller::Build;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::Session::ConfigState;
use BaselinerX::Nature::J2EE::Common;

BEGIN { extends 'Catalyst::Controller' }
use YAML;
use JavaScript::Dumper;
          
sub j2ee_build_json : Path('/j2ee/build/json') {
    my ( $self, $c ) = @_;
          my $p = $c->request->parameters;
		  $p->{ns} ||= '/';
		  $p->{bl} ||= '*';
          my $config = $c->registry->get( 'config.nature.j2ee.build' );
          my $datos = $config->factory($c,ns=>$p->{ns}, bl=>$p->{bl},default_data=>$p);

          $c->stash->{json} = { success=>\1, data => $datos };  
          
          #Se guarda el estado de ns y bl obtenido mediante el request       
          BaselinerX::Session::ConfigState->setConfigState($c);
          
          $c->forward('View::JSON');
}

sub j2ee_submit : Path('/j2ee/build/submit') {
          my ($self,$c)=@_;
          my $p = $c->req->params;
           
          my $config = $c->registry->get( 'config.nature.j2ee.build' );
          my $ret = $config->store_from_metadata( $c, data=>$p );
          if(  $ret ) {
                      $c->res->body( "true" );
          } else {
                      $c->res->body( "false" );
          }
}

sub j2ee_build : Path('/j2ee/build') {
    my ( $self, $c ) = @_;
    BaselinerX::Session::ConfigState->reset($c);
    
    $c->forward('list_packages');
	$c->forward('/baseline/load_baselines');
	
    my $config = $c->registry->get( 'config.nature.j2ee.build' );	
   
    $c->stash->{url_store} = '/j2ee/build/json';
    $c->stash->{url_cp_store} = '/j2ee/build/json_classpath';
    $c->stash->{url_submit} = '/j2ee/build/submit';
    $c->stash->{title} = _loc('J2EE Build');
    
    $c->stash->{metadata} = $config->metadata;  ## lo utilizará el config_form.mas
    $c->stash->{template} = '/comp/j2ee_build.mas';
   
}

sub list_packages : Path('/j2ee/list_packages') {
    my ( $self, $c ) = @_;
	BaselinerX::Nature::J2EE::Common->list_J2EE_namespaces($c);
}

1;
