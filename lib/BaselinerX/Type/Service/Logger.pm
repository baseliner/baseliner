package BaselinerX::Type::Service::Logger;
use Baseliner::Utils;
use Moose;

has 'rc' => ( is=>'rw', isa=>'Int', default=>0 );
has 'msg' => ( is=>'rw', isa=>'Str', default=>'' );

sub info {
    my $self = shift;
    $self->msg( $self->msg . join("\n", @_ ) );
}

sub warn { info(@_) }
sub error {
    my $self = shift;
    $self->rc(1);
    $self->info(@_);
}

#TODO write to db too

1;
