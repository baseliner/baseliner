package BaselinerX::Server::LDAP;
use Baseliner::Plug;
use BaselinerX::Server::LDAP::Listener;

register 'service.server.ldap' => {
	name => 'A simple forking ldap server', 
	handler => sub {
		my $listener = BaselinerX::Server::LDAP::Listener->new({
			localport => 8080,
			logfile => 'STDERR',
			pidfile => 'none',
			mode => 'fork'
		});
		$listener->Bind;
	},
};

1;
