package BaselinerX::Type::Service::Config;
use Baseliner::Plug;
use Baseliner::Utils;

with 'Baseliner::Role::Service';

register 'service.edit.config' => {
    name    => 'Config Baseliner',
    handler => \&run,
};

sub run {
	my ($self,$c,$p)=@_;
	_log _dump $p;
	$c->model('ConfigStore')->set( key=>$p->{key}, value=>$p->{value}, ns=>$p->{ns}, bl=>$p->{bl} );
}

1;
