package BaselinerX::Type::Controller::Service;
use Baseliner::Plug;
use Baseliner::Utils;
use Try::Tiny;
BEGIN { extends 'Catalyst::Controller' };

sub list_services : Path('/admin/type/service/list_services') {
	my ($self,$c)=@_;
	use YAML;
	$c->res->body( "<pre>".Dump $c->registry->starts_with( 'service' ) );
}

sub rest : Local {
	my ($self,$c)=@_;
	my $p = $c->req->parameters;
	try {
		my $ret = $c->launch( $p->{service} );
		$c->stash->{json} = { msg=>1 };
	} catch {
		$c->stash->{json} = { msg=>shift };
	};
	$c->forward('View::JSON');
}

sub launch : Regex('^service.') {
	my ($self,$c)=@_;
    my $service_name = $c->request->path;
    my $ns = $c->request->params->{ns} || '/';
    my $bl = $c->request->params->{bl} || '*';
    warn "Invoking service '$service_name'";
    my $service = $c->registry->get($service_name) || die _loc("Could not find service %1",  $service_name);
    my $config = $c->registry->get( $service->config ) if( $service->{config} );
    my $config_data;
    if( $config ) {
        $config_data = $config->factory( $c, ns=>$ns, bl=>$bl, data=>$c->request->params );
    }
    #warn "Configdata:" . Dumper $config_data;
    my $ret = $service->run( $c, $config_data );
    $c->res->body( '<pre>' . $ret->{msg} );
}

1;
