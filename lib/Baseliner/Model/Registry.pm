package Baseliner::Model::Registry;
use Moose;
extends qw/Catalyst::Component::ACCEPT_CONTEXT Catalyst::Model/;
use Baseliner::Utils;
use Carp;

#TODO for now, this is a place holder for Core::Registry
our $AUTOLOAD;
use Baseliner::Core::Registry;
sub AUTOLOAD {
    my $self = shift;
    my $type = ref($self)
        or croak "$self is not an object";

    my $name = $AUTOLOAD;
    my @a = reverse(split(/::/, $name));
    my $method = $a[0];
    Baseliner::Core::Registry->$method( @_);
}

sub get {  ## somehow autoload does not get called for this
    my $self = shift;
    Baseliner::Core::Registry->get( @_);
}

1;


