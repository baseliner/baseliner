package BaselinerX::Nature::FILES::Controller::Filedist;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Core::Filesys;
use BaselinerX::Session::ConfigState;
use BaselinerX::Nature::J2EE::Controller::Deploy;

BEGIN { extends 'Catalyst::Controller' }
use YAML;
use JavaScript::Dumper;

sub filedist_json : Path('/filedist/json') {
    my ( $self, $c ) = @_;
    
    	  my ($ns,$bl) =  BaselinerX::Session::ConfigState->getConfigState($c);
		  my $p = $c->request->parameters;
			
		  my $tipo = ($p->{tipo}) ? $p->{tipo}: BaselinerX::Nature::FILES::Service::Filedist->TIPO_FICHEROS; 
			
		warn "--------TIPO DISTRO: " . $tipo;

    	  my $filedist = BaselinerX::Nature::FILES::Filedist->new( $ns, $bl, $tipo );
    	  
		  $filedist->load($c);
		  
          my @json_array = ();
          
          #for my $r (@{$filedist->{mappings}}){
          #	push @json_array, $r->{value};
          #}
                  
          $c->stash->{json} = { success=>\1, data => \@{$filedist->{mappings}}  };    
          $c->forward('View::JSON');
}

sub filedist_json_bl_ns: Path('/filedist/json_bl_ns'){
	    my ( $self, $c ) = @_;
	      my $p = $c->request->parameters;
          my $config = $c->registry->get( 'config.nature.filedist_comp' );
          my $datos = $config->factory($c,ns=>$p->{ns}, bl=>$p->{bl},default_data=>$p);

          #Se guarda el estado de ns y bl obtenido mediante el request       
          BaselinerX::Session::ConfigState->setConfigState($c);          

		  $self->filedist_json($c);		           
}

sub j2ee_filedist_json : Path('/j2ee/filedist/json') {
    my ( $self, $c ) = @_;
    	  my ($ns,$bl) =  BaselinerX::Session::ConfigState->getConfigState($c);
    	  my $filedist = BaselinerX::Nature::FILES::Filedist->new( $ns, $bl );
		  $filedist->load($c,{'src_dir'=>{'like','%/J2EE/%'}});
		  
          my @json_array = ();
          
          for my $r (@{$filedist->mappings}){
          	push @json_array, $r;
          }
          
          my $json_data = js_dumper (\@json_array);          
          $c->stash->{json} = { success=>\1, data => \@json_array  };    
          $c->forward('View::JSON');
}


sub filedist : Path('/filedist') {
    my ( $self, $c ) = @_;
    
    my $config = $c->registry->get( 'config.nature.filedist_comp' );	

    BaselinerX::Session::ConfigState->reset($c);	
	
	$c->forward('/namespace/load_namespaces');
	$c->forward('/baseline/load_baselines');
	
 
    $c->stash->{metadata} = $config->metadata; ## lo utilizará el config_form.mas

	$self->parseStashData($c, BaselinerX::Nature::FILES::Service::Filedist->TIPO_FICHEROS);
	BaselinerX::Nature::FILES::Controller::SSHScript->parseStashData($c);
		
    $c->stash->{template} = '/comp/filedist_comp.mas';
}

sub parseStashData{
    my ( $self, $c, $tipo ) = @_;	
    my $config = $c->registry->get( 'config.nature.filedist' );	
   
	my ($ns,$bl) =  BaselinerX::Session::ConfigState->getConfigState($c);
    	  
    $c->stash->{url_filedist_store} = '/filedist/json?ns='. $ns . '&bl=' . $bl . "&tipo=" . $tipo;
    $c->stash->{url_filedist_submit} = '/filedist/submit';
    $c->stash->{url_filedist_delete} = '/filedist/delete';
    
    $c->stash->{title} = _loc('Distribucion Ficheros');

    $c->stash->{metadata_filedist} = $config->metadata; ## lo utilizará el config_form.mas
    
}

sub filedist_json_filter : Path('/filedist/json_filter') {
    my ( $self, $c ) = @_;

}

sub filedist_submit : Path('/filedist/submit') {
          my ($self,$c)=@_;
          my $p = $c->req->params;
    	  my ($ns,$bl) =  BaselinerX::Session::ConfigState->getConfigState($c);
    	  my $filedist = BaselinerX::Nature::FILES::Filedist->new( $ns, $bl );

          $filedist->save($c,
          {	
          	id=>$p->{id},
          	ns=>$ns,
          	bl=>$bl, 
          	filter=>$p->{filter},
          	isrecursive=>$p->{isrecursive},
          	src_dir=>$p->{src_dir},
          	dest_dir=>$p->{dest_dir},
          	ssh_host=>$p->{ssh_host},
          	xtype=>$p->{xtype}
          });
          
          $c->stash->{json} = { success=>\1 };    
          $c->forward('View::JSON');          
}

sub filedist_delete : Path('/filedist/delete') {
          my ($self,$c)=@_;
          my $p = $c->req->params;
    	  my ($ns,$bl) =  BaselinerX::Session::ConfigState->getConfigState($c);
    	  my $filedist = BaselinerX::Nature::FILES::Filedist->new( $ns, $bl );
          my $id = $p->{id};
         
          $filedist->delete($c,$id);
          $c->stash->{json} = { success=>\1 };    
          $c->forward('View::JSON');            
}

sub parseValue{
	my ($val,$default) = @_;
	return ($val eq undef)?$default:$val;	
}

1;