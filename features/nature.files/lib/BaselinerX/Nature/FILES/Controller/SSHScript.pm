package BaselinerX::Nature::FILES::Controller::SSHScript;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Core::Filesys;


register 'config.nature.filedist.ssh' => {
          metadata=> [
                      { id=>'id', type=>'hidden' },
                      { id=>'fid', type=>'hidden' },
                      { id=>'ns', type=>'hidden' },
                      { id=>'bl', type=>'hidden' },
                      { id=>'script', label=>'Script', type=>'text', nullable=>0, extjs =>{width=>'250'}  },
                      { id=>'ssh_host', label=>'Usuario@Host SSH', type=>'text', nullable=>0, extjs =>{width=>'250'}  },
                      { id=>'xorder', label=>'Orden', type=>'combo', store =>order_index() },
                      { id=>'params', type=>'listbox', nullable=>0, 
                      	title=>'Listado de parametros',
          				width=>410, height=>200,
			          	newLabel=>'Nuevo parametro',
			          	delLabel=>'Eliminar parametro'                      	
                      }                     
          ]
};

BEGIN { extends 'Catalyst::Controller' }
use YAML;
use JavaScript::Dumper;

sub filedist_ssh_json : Path('/filedist/ssh/json') {
    my ( $self, $c ) = @_;
    	  my $fid = $c->request->parameters->{fid};    	
		  my ($ns,$bl) =  BaselinerX::Session::ConfigState->getConfigState($c);
    	      	      	    
    	  my $scripts = BaselinerX::Nature::FILES::SSHScript->new( $ns,$bl,$fid );		  
		  $scripts->loadByFileDist($c);
		  
          my @json_array = ();
          
          for my $r (@{$scripts->{scripts}}){
          	push @json_array, {$r->get_columns,fid=>$fid};
          }
             
          $c->stash->{json} = { success=>\1, data => \@json_array  };    
          $c->forward('View::JSON');
}

sub filedist_ssh : Path('/filedist/ssh') {
    my ( $self, $c ) = @_;
	
	parseStashData($self,$c);
	
    $c->stash->{template} = '/comp/sshscript.mas';
}

sub parseStashData{
    my ( $self, $c ) = @_;	
    my $config = $c->registry->get( 'config.nature.filedist.ssh' );	
    my $fid = $c->request->parameters->{fid};   
       	  
    $c->languages( ['es'] );
    $c->stash->{url_script_store} = '/filedist/ssh/json?fid=' . $fid;
    $c->stash->{url_script_submit} = '/filedist/ssh/submit';
    $c->stash->{url_script_delete} = '/filedist/ssh/delete';
    
    $c->stash->{title_script} = _loc('Ejecucion de Scripts');

    $c->stash->{metadata_sshscript} = $config->metadata; ## lo utilizará el config_form.mas    
    
}

sub filedist_ssh_json_params : Path('/filedist/ssh/json_params') {
    my ( $self, $c ) = @_;

}

sub filedist_ssh_submit : Path('/filedist/ssh/submit') {
          my ($self,$c)=@_;
          my $p = $c->req->params;
 		  my ($ns,$bl) =  BaselinerX::Session::ConfigState->getConfigState($c);         
    	  my $scripts = BaselinerX::Nature::FILES::SSHScript->new( $ns,$bl,$p->{fid} );
		  
		  ##$scripts->loadByFileDist($c);

          $scripts->save($c,
          {	
          	id=>$p->{id},
          	ns=>$ns,
          	bl=>$bl, 
          	script=>$p->{script},
          	params=>$p->{params},
          	ssh_host=>$p->{ssh_host},
          	xorder=>$p->{xorder}
          });
          
          $c->stash->{json} = { success=>\1 };    
          $c->forward('View::JSON');          
}

sub filedist_ssh_delete : Path('/filedist/ssh/delete') {
          my ($self,$c)=@_;
          my $p = $c->req->params;
         
          my $id = $p->{id};         
          BaselinerX::Nature::FILES::SSHScript->delete($c,$id);
          
          $c->stash->{json} = { success=>\1 };    
          $c->forward('View::JSON');            
}

sub parseValue{
	my ($val,$default) = @_;
	return ($val eq undef)?$default:$val;	
}

sub order_index{
	my @vals = ();
	for (my $i=0; $i<=10; $i++){ push @vals,$i;}
	return \@vals;	
}

