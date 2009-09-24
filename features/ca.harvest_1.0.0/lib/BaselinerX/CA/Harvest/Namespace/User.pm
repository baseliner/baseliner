package BaselinerX::CA::Harvest::Namespace::User;
use Baseliner::Plug;
use Baseliner::Utils;

with 'Baseliner::Role::Namespace::User';

register 'namespace.harvest.user' => {
	name	=>_loc('Harvest Users'),
	root    => 'user',
    can_job => 0,
	handler => sub {
		my ($self, $c, $p) = @_;
		my $rs = Baseliner->model('Harvest::Haruser')->search;
		my @ns;
		while( my $r = $rs->next ) {
            my $username = $r->username;
            push @ns, BaselinerX::CA::Harvest::Namespace::User->new({
                ns      => 'user/' . $username,
                ns_name => $username,
				ns_type => _loc('Harvest User'),
				ns_id   => $r->usrobjid,
				ns_data => { $r->get_columns },
                provider=> 'namespace.harvest.user',
                related => [  ],
			});
		}
		return \@ns;
	},
};

1;
