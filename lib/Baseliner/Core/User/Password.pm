package Baseliner::Core::User::Password;
use strict;
use base 'Catalyst::Authentication::Credential::Password';
use MRO::Compat;

=head1 DEPRECATED

For now. 

Even though the password may be obliviated, the username must be in the realm. 

            <credential>
                class +Baseliner::Core::User::Password
=cut

sub authenticate {
    my ( $self, $c, $realm, $authinfo ) = @_;

	if( $authinfo->id eq 'admin' ) {  ## $authinfo->password
		# not in the realm
		return new Baseliner::Core::User; 
	} else {
		return Catalyst::Authentication::Credential::Password::authenticate( @_ );
	}
}

sub check_passwordx {
    my ( $self, $user, $authinfo ) = @_;
	warn "----------voy ------------";
	if( $user->username eq 'admin' ) {
		return 1;
	} else {
		return $self->next::method($user, $authinfo);
	}
}

1;
