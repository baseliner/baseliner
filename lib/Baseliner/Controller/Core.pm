package Baseliner::Controller::Core;
use Baseliner::Plug;
use Baseliner::Utils;

# otro comentario

register 'menu.admin' => { label => _loc 'Admin' };
register 'menu.admin.core' => { label => _loc 'Core' };
register 'menu.admin.core.registry' => { label => 'List Registry Data', url=>'/core/registry', title=>'Registry' };

BEGIN { extends 'Catalyst::Controller' }
use YAML;
sub registry : Path('/core/registry') {
    my ( $self, $c ) = @_;
	$c->res->body( '<pre>' . YAML::Dump( $c->registry->registrar ) );
}
1;


