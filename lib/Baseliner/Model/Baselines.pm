package Baseliner::Model::Baselines;
use Moose;
extends qw/Catalyst::Component::ACCEPT_CONTEXT Catalyst::Model/;
use Baseliner::Utils;
use Carp;
use Baseliner::Core::Baseline;

our $AUTOLOAD;
sub AUTOLOAD {
    my $self = shift;
    my $type = ref($self)
        or croak "$self is not an object";

    my $name = $AUTOLOAD;
    my @a = reverse(split(/::/, $name));
    my $method = $a[0];
    Baseliner::Core::Baseline->$method(  @_);
}

1;

