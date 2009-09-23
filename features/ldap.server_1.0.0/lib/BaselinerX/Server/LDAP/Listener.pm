package BaselinerX::Server::LDAP::Listener;
use Net::Daemon;
use base 'Net::Daemon';
use BaselinerX::Server::LDAP::Backend;

sub Run {
	my $self = shift;
	
	my $handler = BaselinerX::Server::LDAP::Backend->new($self->{socket});
	while (1) {
		my $finished = $handler->handle;
		if ($finished) {
			# we have finished with the socket
			$self->{socket}->close;
			return;
		}
	}
}

1;
