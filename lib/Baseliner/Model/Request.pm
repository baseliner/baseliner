package Baseliner::Model::Request;
use Baseliner::Plug;
extends qw/Catalyst::Model/;
no Moose;
use Baseliner::Utils;
use Digest::MD5;

sub generate_key {
    return Digest::MD5::md5_hex( _now . rand() . $$ );
}

register 'action.approve.item' => {
    name => 'Approve Items',
};

=head2 request

    $m->request(
        name   => 'Aprobación del pase N.DESA1029210',  # this will become the subject
        action => $action,   # look for people who can approve this
        vars   => {  reason=>'promoción a producción' },  # send it to the template
        template => '/email/another.html',
        ns     => $item, 
        bl     => $bl, 
    );

=cut
sub request {
    my ($self, %p ) = @_;

    $p{action} || die 'Missing parameter action';
    $p{ns} || die 'Missing parameter ns';
    $p{bl} ||= '*';

    my $username = $p{username} || 'internal';

    # look for existing requests
    my $pending = $self->pending( ns=>$p{ns}, action=>$p{action} );

    while( my $r = $pending->next ) {
        $r->status('cancelled');
        $r->finished_by($username);
        $r->finished_on(_now_ora);
        $r->update;
    }

    # request new
    my $key = $self->generate_key;
    my $request = Baseliner->model('Baseliner::BaliRequest')->create(
        {
            ns           => $p{ns},
            action       => $p{action},
            requested_on => _now_ora,
            requested_by => $username, 
            key          => $key,
        }
    );

    my $name = $p{name} || _loc('Request %1', _now . ':' . $request->id );
    $request->name( $name );
    $request->update;
   
    $self->notify_request(
        action  => $p{action},
        vars  => $p{vars},
        template  => $p{template},
        request => $request,
        ns      => $p{ns},
        bl      => $p{bl},
    );

	return $request;
}

sub pending {
    my ($self, %p ) = @_;

    my $query = { ns => $p{ns}, status => { -in => [ 'pending', 'notified' ] } };
    $p{action} and $query->{action} = $p{action};

    my $rs = Baseliner->model('Baseliner::BaliRequest')->search($query);
    return $rs;
}

sub notify_request {
    my ($self, %p ) = @_;

    my $request = $p{request} || _throw 'Missing request object';
    my @items = _array $p{ns};
    my $key = $request->key || _throw 'Missing approval key';
    my @users;
    for my $item ( @items ) {
        push @users, Baseliner->model('Permissions')->list(
            action => $p{action},
            ns     => $item,
            bl     => $p{bl},
        );
    }

    _debug "Notifying users " . join ',',@users;

    _throw _loc( "No users found for action '$p{action}' and namespace(s) '%1'",
        join( "','", @items ) )
      unless @users;

    my %vars = %{ $p{vars} || {} };
    my $items = join ' ', @items;
    Baseliner->model('Messaging')->notify(
        to       => { users => [ _unique(@users) ] },
        subject  => $request->name,
        carrier  => 'email',
        template => $p{template} || 'email/approval.html',
        vars     => {
            items => $items,
            from  => _loc('Approval Request'),
            url_approve   => _notify_address . "/request/approve/$key",
            url_reject   => _notify_address . "/request/reject/$key",
            %vars,
        }
    );

}

sub status_by_key {
    my ( $self, %p ) = @_;
    my $rs = Baseliner->model('Baseliner::BaliRequest')->search({ key => $p{key} });
    _throw _loc('Could not find a request for %1', $p{key} ) unless ref $rs;
    while( my $r = $rs->next ) {
        _throw _loc( 'Request %1 has been %2', $r->id, _loc($r->status) )
          if ( $r->status ne 'pending' );
        warn "STATUS=" . $r->status;
        $r->status( $p{status} );
        $r->finished_on( _now );
        $r->finished_by( $p{username} );
        $r->update;
    }
}

sub approve_by_key {
    my ( $self, %p ) = @_;
    $self->status_by_key( key=>$p{key}, status=>'approved' );
}

sub reject_by_key {
    my ( $self, %p ) = @_;
    $self->status_by_key( key=>$p{key}, status=>'rejected' );
}

=head1 DESCRIPTION

pending => create request, but not notified
notified => request notified
cancelled => request cancelled or overwritten by a new one
approved => ok
rejected => nok

=cut
1;
