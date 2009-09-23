package Baseliner::Model::Messaging;
use Moose;
extends qw/Catalyst::Model/;
no Moose;
use Baseliner::Utils;
use Baseliner::Core::Message;

=head1 DESCRIPTION

By default messages are sent by both email and instant messaging. 

    # notify admins:
    $c->model('Messaging')->notify( subject=>'Internal Error', message=>'Maybe you want to take a look');

    # notify users
    $c->model('Messaging')->notify(
        subject=>'Job Started',
        message=>'Maybe you want to take a look',
        type=> ['email', 'instant']
        to_user=> [qw/U1 U2/],
        to_actions=> [{ ns=>'/application/AAA0001', action=>'action.notify.job.end' }]
    );

    ->notify( subject=>'sss', template=>'job_start.templ', vars=>{ job_name=>'N001101' } );

=cut

# creates a message with no queue
sub create {
    my ($self,%p)=@_;

    my $body = $p{body};

    _throw "No subject specified" unless $p{subject};

    if( $p{template} ) {
        my $template = Baseliner->path_to('root', $p{template} );
        $body = _parse_template( $template, %{ $p{vars} || {} } );
    }

    $p{sender} ||= _loc('internal');

    my $msg = Baseliner->model('Baseliner::BaliMessage')->create(
        {
            subject => $p{subject},
            body    => $body,
            sender  => $p{sender},
            attach  => $p{attach},
        }
    );
    return $msg;
}

sub delete {
    my ( $self, %p ) = @_;

    my $msg = Baseliner->model('Baseliner::BaliMessage')->find({ id=> $p{id} }) if $p{id} ;
    $msg->delete if ref $msg; 
}

sub read {

}

=head2 notify

Creates a message and puts a notification in the queue. 

  subject => 'about...',
  body => 'body',
  sender  =>  'me',
  attach  => (data)

  carriers => ['email', 'instant', ... ],

Then the destination (users):
    to => {
        users => [ 'A', 'B', ... ],
    },
    cc => { 
        users => [ ... ]
    }

Or to destination actions:

    to => {
      actions => [ .. ],
      ns => [ ... ],    # optional, defaults to /
      bl => [ ... ],    # optional, defaults to *
    },
    cc => {
            ...
    },


=cut
sub notify {
    my ($self,%p)=@_;

    my @carriers = _array( $p{carriers} , $p{carrier} );

    my %users;

    for my $param ( qw/to cc bcc/ ) {
        my $dest = $p{$param};
        next unless ref $dest eq 'HASH';

        die 'notify can take either "actions" or "users" but not both'
          if defined $dest->{users} && defined $dest->{actions};

        push @{ $users{$param} }, _array( $dest->{users}, $dest->{user} );

        my @actions = _array( $dest->{actions}, $dest->{action} ); 
        for my $action ( @actions ) {
        warn "AC=$action";
            my @users = Baseliner->model('Permissions')->list(
                action => $action,
                bl     => ( $dest->{bl} || 'any' ),
                ns     => ( $dest->{ns} || 'any' )
            );
            push @{ $users{$param} }, @users; 
        }
    }

    my $msg = $self->create(%p);

    for my $carrier ( @carriers ) {
        for my $param ( qw/to cc bcc/ ) {
            for my $username ( _array $users{$param} ) {
                $msg->bali_message_queues->create({ username=>$username, carrier=>$carrier, carrier_param=>$param });
            }
        }
    }
    return $msg;
}

=head2 inbox

List all available messages for a given username. 
    
    username => 'me',

By default, only lists active (unread) messages. 

If you are a queue carrier, to list all, set:
    
    all => 1

=cut
sub inbox {
    my ($self,%p)=@_;
    my @messages;

    my $search = {};
    $search->{active} = 1 unless $p{all};
    exists $p{username} and $search->{username} = delete $p{username} if $p{username};
    exists $p{carrier} and $search->{carrier} = delete $p{carrier};
    
    my $rs = Baseliner->model('Baseliner::BaliMessageQueue')->search($search);

    while( my $r = $rs->next ) {
        my $message = new Baseliner::Core::Message(
            {
                $r->id_message->get_columns, $r->get_columns,
                id_message => $r->id_message->id
            }
        );
        push @messages, $message;

        if( $p{deliver_now} ) {
            $r->deliver_now;
        }
    }
    return @messages;
}

sub delivered {
    my ($self,%p)=@_;
    
    my $search = {};
    $p{id} and $search->{id} = $p{id}; 

    my $rs = Baseliner->model('Baseliner::BaliMessageQueue')->search($search);
    while( my $r = $rs->next )  {
        $r->deliver_now;
        $r->update;
    }
}

sub failed {
    my ($self,%p)=@_;
    
    my $search = {};
    my $max_attempts = $p{max_attempts} || 10;  #TODO to config
    $p{id} and $search->{id} = $p{id}; 
    my $rs = Baseliner->model('Baseliner::BaliMessageQueue')->search($search);
    while( my $r = $rs->next )  {
        if( $r->attempts < $max_attempts ) {
            $r->active( 1 );
        } else {
            $r->active( 0 );
        }
        $r->result( $p{result} );
        $r->attempts(  $r->attempts + 1 );
        $r->update;
    }
}

sub get {
    my ($self,%p)=@_;
    my $r = Baseliner->model('Baseliner::BaliMessageQueue')->find({ id=>$p{id} });
    #my $message = new Baseliner::Core::Message({ $r->get_columns, $r->id_message->get_columns });
    return { $r->get_columns, $r->id_message->get_columns } if ref $r;
}

sub has_unread_messages {
    my ( $self, %p ) = @_;

    my $search = {};
    $search->{active} = 1 unless $p{all};
    exists $p{username} and $search->{username} = delete $p{username} if $p{username};
    exists $p{carrier} and $search->{carrier} = delete $p{carrier};

    return Baseliner->model('Baseliner::BaliMessageQueue')->search($search)->count;
}


1;
