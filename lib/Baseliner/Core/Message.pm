package Baseliner::Core::Message;
use Moose;

has 'id' => ( is=>'rw', isa=>'Int' );
has 'id_message' => ( is=>'rw', isa=>'Int' );
has 'subject' => ( is=>'rw', isa=>'Str' );
has 'body' => ( is=>'rw', isa=>'Any' );
has 'attach' => ( is=>'rw', isa=>'Any' );
has 'sender' => ( is=>'rw', isa=>'Any' );
has 'sent' => ( is=>'rw', isa=>'Any' );
has 'received' => ( is=>'rw', isa=>'Any' );
has 'created' => ( is=>'rw', isa=>'Any' );
has 'active' => ( is=>'rw', isa=>'Int' );

sub from { my $self=shift; $self->sender(@_) }

1;
