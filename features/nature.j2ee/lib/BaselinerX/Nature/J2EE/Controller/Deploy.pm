package BaselinerX::Nature::J2EE::Controller::Deploy;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::Eclipse;
use BaselinerX::Eclipse::J2EE;
use Baseliner::Core::Filesys;
use BaselinerX::Session::ConfigState;
use BaselinerX::Nature::J2EE::Controller::Common;

BEGIN { extends 'Catalyst::Controller' }
use YAML;
use JavaScript::Dumper;
          
sub j2ee_deploy_json : Path('/j2ee/deploy/json') {
    my ( $self, $c ) = @_;
          my $p = $c->request->parameters;
		  $p->{ns} ||= '/';
		  $p->{bl} ||= '*';
          my $config = $c->registry->get( 'config.nature.j2ee.deploy' );
          my $datos = $config->factory($c,ns=>$p->{ns}, bl=>$p->{bl},default_data=>$p);
          $c->stash->{json} = { success=>\1, data => $datos };
          
          #Se guarda el estado de ns y bl obtenido mediante el request       
          BaselinerX::Session::ConfigState->setConfigState($c);          
              
          $c->forward('View::JSON');
}

sub j2ee_deploy_submit : Path('/j2ee/deploy/submit') {
          my ($self,$c)=@_;
          my $p = $c->req->params;
          my $config = $c->registry->get( 'config.nature.j2ee.deploy' );
          my $ret = $config->store_from_metadata( $c, data=>$p );
          if(  $ret ) {
                      $c->res->body( "true" );
          } else {
                      $c->res->body( "false" );
          }
}

sub j2ee_deploy : Path('/j2ee/deploy') {
    my ( $self, $c ) = @_;
    
    BaselinerX::Session::ConfigState->reset($c);
    
    my $config = $c->registry->get( 'config.nature.j2ee.deploy' );	

    $c->forward('list_packages');
	$c->forward('/baseline/load_baselines');
   
    $c->stash->{url_store} = '/j2ee/deploy/json';
    $c->stash->{url_mappings_store} = '/j2ee/deploy/json_mapping';
    $c->stash->{url_submit} = '/j2ee/deploy/submit';
    $c->stash->{title} = _loc('J2EE Deploy');
 
    $c->stash->{metadata} = $config->metadata; ## lo utilizará el config_form.mas

	# Rellenamos el stash para los subcomponentes de la naturaleza
	BaselinerX::Nature::FILES::Controller::Filedist->parseStashData($c,BaselinerX::Nature::FILES::Service::Filedist->TIPO_J2EE);
	BaselinerX::Nature::FILES::Controller::SSHScript->parseStashData($c);
	
    $c->stash->{template} = '/comp/j2ee_deploy.mas';

}

sub list_packages : Path('/j2ee/list_packages') {
    my ( $self, $c ) = @_;
    my @NS;
    my @ns_list = $c->model('Namespaces')->namespaces();
    for my $ns ( @ns_list ) {
    	push @NS, [$ns->ns, $ns->ns_text ] 
    			if( $ns->ns eq '/' 
    				|| $ns->ns =~ m{^harvest.nature/J2EE}
    				|| $ns->ns =~ m{^application}
    				|| $ns->ns =~ m{^harvest.package}
    			);
    }
    $c->stash->{namespaces} = \@NS;
}

1;
