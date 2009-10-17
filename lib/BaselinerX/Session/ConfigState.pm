package BaselinerX::Session::ConfigState;
    use Catalyst qw/
      Session
      Session::Store::FastMmap
      Session::State::Cookie
      /;
      
my $DefaultBL = "*";
my $DefaultNS = "/";
      
sub setConfigState{
	my ($self,$c,$ns,$bl) = @_;

	$c->session->{ns} = $c->request->parameters->{ns} || $ns || $DefaultNS;		
	$c->session->{bl} = $c->request->parameters->{bl} || $bl || $DefaultBL;		

} 

sub getConfigState{
	my ($self,$c) = @_;
	
	my $ns = $c->session->{ns} || $c->request->parameters->{ns} || $DefaultNS;
	my $bl = $c->session->{bl} || $c->request->parameters->{bl} || $DefaultBL;

    warn "NS = $ns | BL = $bl";
	
	return ($ns,$bl);
} 

sub reset{
	my ($self,$c) = @_;
	$c->session->{ns} = undef;
	$c->session->{bl} = undef;
}

#sub getConfigState{
#	my ($self,$c) = @_;
#		
#	if($c->session->{bl} eq undef or $c->session->{ns} eq undef){
#		initSessionFromRequest($self,$c);		
#	}
#
#	my $bl = $c->session->{bl};
#	my $ns = $c->session->{ns};
#	my $packageId = $c->session->{packageId};
#	my $projectId = $c->session->{projectId};
#	my $packageName = $c->session->{packageName};	
#	
#	return {ns=>$ns,bl=>$bl,packageId=>$packageId,projectId=>$projectId,packageName=>$packageName};
#} 
#
#sub initSessionFromRequest{
#	my ($self,$c) = @_;
#	my $packageId = $c->request->params->{PACKAGE_ID};
#	my $projectId = $c->request->params->{PROJECT_ID};
#	my $packageName = $c->request->params->{PACKAGE_NAME};
#	
#	$c->session->{packageId} = $packageId;
#	$c->session->{projectId} = $projectId;
#	$c->session->{packageName} = $packageName;
#
#	if($projectId eq undef or $packageId eq undef){
#		$c->session->{bl} = $DefaultBL;
#		$c->session->{ns} = $DefaultNS;	
#	}else{
#		my $rs = $c->model('Harvest::Harpackage')->search({packageobjid=> $packageId});
#		if(my $r = $rs->next){		
#			$c->session->{ns} = '/' . $r->envobjid->environmentname;			
#			$c->session->{bl} = getBaselineFromState($self,$c,$r->state->statename);
#						
#		}else{
#			$c->session->{bl} = $DefaultBL;
#			$c->session->{ns} = $DefaultNS;			
#		}
#		
#	}
#	
#}
#
#sub getBaselineFromState{
#	my ($self,$c,$statename) = @_;
#	my $rs = $c->model('Baseliner::BaliBaseline')->search({name=>$statename});
#	my $bl = $DefaultBL;
#	if(my $r = $rs->next){
#		$bl = $r->bl;
#	}
#	return $bl;
#}
#
#sub getNamespaceTree{
#	my ($self,$c) = @_;
#	my $rs = $c->model('Harvest::Haritems')->search({itemtype=>0,parentobjid=>0});
#	return $rs->get_columns();
#}
#
