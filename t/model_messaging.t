use strict;
use warnings;
use Test::More tests => 24;

BEGIN { use_ok 'Catalyst::Test', 'Baseliner' }
BEGIN { use_ok 'Baseliner::Model::Permissions' }

my $c = Baseliner->new();

my $m;

{
    ok( $m = $c->model('Messaging'), 'got model Messaging' );
}

{
    my $message = $m->notify(
        subject  => 'subject',
        body  => 'things',
        sender   => 'me',
        attach   => '',
        carriers => 'email',
        to       => { users => [ 'AA', 'BB' ], },
        cc       => { users => [ 'Me', 'Them' ], },
    );

    ok( ref $message, 'message created' );

    ok( ( grep { /things/ } map { $_->body } $m->inbox(username=>'AA') ), 'message in inbox for AA' );

    ok( scalar $m->inbox(username=>'BB', ) , 'there are unread messages in inbox for BB' );

    ok( $m->has_unread_messages(username=>'BB', ) , 'BB has_unread_messages' );

    ok( ( grep { /things/ } map { $_->body } $m->inbox(username=>'BB', deliver_now=>1 ) ), 'message in inbox for BB' );

    ok( ! scalar $m->inbox(username=>'BB', ) , 'no more messages in inbox for BB' );

    ok( ( grep { /things/ } map { $_->body } $m->inbox(username=>'Me') ), 'message in inbox for Me' );

    ok( ( grep { /things/ } map { $_->body } $m->inbox(username=>'Me', carrier=>'email' ) ), 'email in inbox for Me' );

    ok( ! $m->has_unread_messages(username=>'BB', carrier=>'kkkkkk' ) , 'BB not has_unread_messages for invalid carrier' );

    $message->delete;

    ok( ! ( grep { /things/ } map { $_->body } $m->inbox(username=>'Me') ), 'no more messages in inbox for Me' );
}

{
    my $message = $m->notify(
        subject  => 'subject',
        template => 'email/test.html',
        sender   => 'me',
        attach   => '',
        carriers => 'email',
        to       => { users => [ 'ROG2833Z' ], },
    );

    ok( ref $message, 'template message created' );

    ok( ( grep { /test message/ } $message->body ), 'template message body' );


}
