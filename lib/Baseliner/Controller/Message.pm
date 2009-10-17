package Baseliner::Controller::Message;
use Baseliner::Plug;
use Baseliner::Utils;
BEGIN {  extends 'Catalyst::Controller' }

sub detail : Local {
    my ($self,$c) = @_;
	my $p = $c->request->parameters;
    my $message = $c->model('Messaging')->get( id=>$p->{id} );
	$c->stash->{json} = { data => [ $message ] };		
	$c->forward('View::JSON');
}


# only for im, with read after check
sub im_json : Local {
    my ($self,$c) = @_;
	my $p = $c->request->parameters;
    return unless $c->user;
    $c->stash->{messages} = [ $c->model('Messaging')->inbox(username=>$c->user->username || $c->user->id, carrier=>'instant', deliver_now=>1 ) ];
    $c->forward('/message/json');
}

# all messages for the user
sub inbox_json : Local {
    my ($self,$c) = @_;
	my $p = $c->request->parameters;
    return unless $c->user;
    $c->stash->{messages} = [ $c->model('Messaging')->inbox(username=>$c->user->username || $c->user->id, ) ];
    $c->forward('/message/json');
}

sub json : Local {
    my ($self,$c) = @_;
	my $p = $c->request->parameters;
    my ($start, $limit, $query, $dir, $sort, $cnt ) = ( @{$p}{qw/start limit query dir sort/}, 0 );
    $sort ||= 'role';
    $dir ||= 'asc';
    my @rows;
	foreach my $message ( @{ $c->stash->{messages} || [] } ) {
        # produce the grid
        next if( $query && !query_array($query, $message->sender, $message->subject, $message->message ));
        push @rows,
          {
            id         => $message->id,
            id_message => $message->id_message,
            sender     => $message->sender,
            subject    => $message->subject,
            received    => $message->received,
            body    => substr( $message->body, 0, 100 ),
            sent       => $message->sent,
          }
          if ( ( $cnt++ >= $start ) && ( $limit ? scalar @rows < $limit : 1 ) );
    }
	$c->stash->{json} = { totalCount=>$cnt, data => \@rows };		
    use YAML;
    warn "....MSS: " . Dump $c->stash->{json};
	$c->forward('View::JSON');
}

sub delete : Local {
    my ( $self, $c ) = @_;
	my $p = $c->req->params;
	eval {
        $c->model('Messaging')->delete( id=>$p->{id_message} );
    };
	if( $@ ) {
        warn $@;
		$c->stash->{json} = { success => \0, msg => _loc("Error deleting the message ").$@  };
	} else { 
		$c->stash->{json} = { success => \1, msg => _loc("Message '%1' deleted", $p->{name} ) };
	}
	$c->forward('View::JSON');	
}

sub inbox : Local {
    my ( $self, $c ) = @_;
    $c->stash->{template} = '/comp/message_grid.mas';
}


1;

