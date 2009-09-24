package Baseliner::Controller::Root;
use strict;
use warnings;
use base 'Catalyst::Controller';
use Baseliner::Utils;

use Try::Tiny;

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config->{namespace} = '';

=head1 NAME

Baseliner::Controller::Root - Root Controller for Baseliner

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=cut

=head2 index

=cut

sub begin : Private {
    my ( $self, $c ) = @_;
    $c->res->headers->header( 'Cache-Control' => 'no-cache');
    $c->res->headers->header( Pragma => 'no-cache');
    $c->res->headers->header( Expires => 0 );

    Baseliner->app( $c );

    _db_setup;  # make sure LongReadLen is set after forking

	# catch invalid user object sessions
	try {
		$c->user;
	} catch {
		$c->forward('/auth/logoff');
		$c->forward('/auth/logon_page');
	};
}

sub whoami : Local {
    my ( $self, $c ) = @_;
    $c->res->body( $c->user->username  );

}

sub controllers : Local {
    my ( $self, $c ) = @_;
    $c->res->body( '<pre><li>' . join '<li>', sort $c->controllers );

}

sub models : Local {
    my ( $self, $c ) = @_;
    $c->res->body( '<pre><li>' . join '<li>', sort $c->models );

}

sub index:Private {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;

    if( $p->{tab}  ) {
        push @{ $c->stash->{tab_list} }, { url=>$p->{tab}, title=>$p->{tab} };
    }

    # set language 
    if( $c->user ) {
        if( $c->user ) {
            my $username = $c->user->username || $c->user->id;
            if( $username ) {
                my $prefs = $c->model('ConfigStore')->get('config.user.global', ns=>"user/$username");
                $c->language( $prefs->{language} || $c->config->{default_lang} );
            }
        }
    }

    # load menus
    my @menus;
    if( $c->user ) {
		my @actions = $c->model('Permissions')->list( username=> $c->username );
        $c->stash->{menus} = $c->model('Menus')->menus( allowed_actions=>[ @actions ]);
    }
    $c->stash->{template} = '/site/index.html';
}

use Encode qw( decode_utf8 encode_utf8 is_utf8 );
sub detach: Local {
    my ( $self, $c ) = @_;
    my $html = $c->request->{detach_html};
    my $type = $c->request->{type};
    $html = decode_utf8 $html;
    $html = decode_utf8 $html;
    $c->stash->{detach_html} = $html;
    #$c->stash->{detach_html} = decode_utf8 decode_utf8 $c->request->{detach_html};
    $c->stash->{template} = '/site/detach.html';
}

sub show_comp : Local {
    my ( $self, $c ) = @_;
    my $url = $c->request->{url};
    $c->stash->{url} = $url;
    $c->stash->{template} = '/site/comp.html';
}

sub default:Path {
    my ( $self, $c ) = @_;
    $c->stash->{template} = $c->request->{path} || $c->request->path;
}

## JSON stuff

use JSON::XS;
use constant js_true => JSON::XS::true;
use constant js_false => JSON::XS::false;
use MIME::Base64;

=head2 end

Renders a Mason view by default, passing it all parameters as <%args>.

=cut 

sub end : ActionClass('RenderView') {
    my ( $self, $c ) = @_;
    $c->stash->{$_}=$c->request->parameters->{$_} 
    	foreach( keys %{ $c->req->parameters || ()});
}


=head1 AUTHOR

Rodrigo Gonzalez

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
