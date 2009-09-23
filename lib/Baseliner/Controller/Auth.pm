package Baseliner::Controller::Auth;
use Moose;
use Baseliner::Utils;
BEGIN { extends 'Catalyst::Controller'; }
use Try::Tiny;
use YAML;
use MIME::Base64;
use Baseliner::Role::User;

sub go : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    if( $p->{USER_NAME} ) {  #TODO check for referer 'harvest'
        my $login = decode_base64($p->{USER_NAME});
        #$c->set_authenticated( 'default' , $login );  
        $c->authenticate(  $login );  
    }
    $c->forward('/index');
}

sub login_local : Local {
    my ( $self, $c, $login, $password ) = @_;
    my $p = $c->req->params;
	my $auth = $c->authenticate({ id=>$c->stash->{login}, password=>$c->stash->{password} }, 'local');
	if( ref $auth ) {
		#Baseliner::Role::User->meta->apply( $c->user );
		$c->stash->{json} = { success => \1, msg => _loc("OK") };
	} else {
		$c->stash->{json} = { success => \0, msg => _loc("Invalid User or Password") };
	}
}

sub login : Global {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    my $login= $p->{login};
    my $password = $p->{password};

    _log "LOGIN: " . $p->{login};
    #_log "PW   : " . $p->{password}; #TODO only for testing!

	if( $login && $password ) {
		if( $login =~ /^local\/(.*)$/i ) {
			$c->stash->{login} = $1;
			$c->stash->{password} = $password;
			$c->forward('/auth/login_local');
		} else {
			my $auth = $c->authenticate({
					id          => $login, 
					password    => $password,
					});
			if( ref $auth ) {
				$c->stash->{json} = { success => \1, msg => _loc("OK") };
			} else {
				$c->stash->{json} = { success => \0, msg => _loc("Invalid User or Password") };
			}
		}
    } else {
        # invalid form input
		$c->stash->{json} = { success => \0, msg => _loc("Missing User or Password") };
	}
	$c->forward('View::JSON');	
    #$c->res->body("Welcome " . $c->user->username || $c->user->id . "!");
}

sub error : Private {
    my ( $self, $c, $username ) = @_;
    $c->stash->{error_msg} = _loc( 'Invalid User.' );
    $c->stash->{error_msg} .= ' '._loc( "User '%1' not found", $username ) if( $username );
    $c->stash->{template} = '/site/error.html';
}

sub logout : Global {
    my ( $self, $c ) = @_;

    $c->delete_session;
    $c->logout;
}

sub logoff : Global {
    my ( $self, $c ) = @_;
    $c->delete_session;
}

sub logon_page : Global {
    my ( $self, $c ) = @_;
}

1;
