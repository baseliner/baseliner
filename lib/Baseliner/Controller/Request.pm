package Baseliner::Controller::Request;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Core::Baseline;
use Try::Tiny;

BEGIN {  extends 'Catalyst::Controller' }

sub reject : Local : Args(1) {
    my ( $self, $c, $key ) = @_;

    try {
        $c->model('Request')->approve_by_key( key=> $key, user=>$c->user->username || $c->user->id );
        $c->stash->{template} = '/plain/approved.html';
    } catch {
        $c->stash->{message} = shift;
        $c->stash->{template} = '/plain/error.html';
    };
}

sub approve : Local : Args(1) {
    my ( $self, $c, $key ) = @_;

    try {
        $c->model('Request')->reject_by_key( key=> $key, user=>$c->user->username || $c->user->id,  );
        push @{ $c->stash->{alert} }, { message=>'Approved', title=>_loc('Approval') };
        $c->forward('/index');
    } catch {
        push @{ $c->stash->{alert} }, { message=>shift, title=>_loc('Approval') };
        $c->forward('/index');
    };
    #$c->stash->{template} = '/site/approval.mas';
}

sub list_json : Local {
    my ( $self, $c ) = @_;
    $c->stash->{json} = {};
    $c->forward('View::JSON');
}

sub main : Local {
    my ( $self, $c ) = @_;
    $c->stash->{template} = '/comp/request_grid.mas';
}

1;
