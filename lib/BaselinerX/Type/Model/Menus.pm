package BaselinerX::Type::Model::Menus;
use strict;
use base qw/Catalyst::Component::ACCEPT_CONTEXT Catalyst::Model/;
#use Baseliner::Utils;
#use Carp;
#use namespace::clean;

sub menus {
    my ($self,%p) = @_;
    my @menus;
    push @menus,$_->ext_menu_json(allowed_actions=>$p{allowed_actions} )
        foreach (
                sort { $a->index <=> $b->index }
                    $self->context->model('Registry')->search_for(key=>'menu.', allowed_actions=>$p{allowed_actions}, depth=>1, check_enabled=>1)
        ) ;
    return [ @menus ];
}

1;
