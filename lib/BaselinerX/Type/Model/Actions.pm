package BaselinerX::Type::Model::Actions;
use Moose;
extends qw/Catalyst::Component::ACCEPT_CONTEXT Catalyst::Model/;
use Baseliner::Utils;
use Carp;

sub list {
    my ($self,%p) = @_;
    my $c = $self->context;
    my @actions = $c->model('Registry')->search_for(key=>'action.');
    return @actions;
}

1;

