package Baseliner::Core::Authentication;
use strict;
use Baseliner::Core::Authentication::Backend;

sub new {
    my ( $class, $config, $app ) = @_;
    return Baseliner::Core::Authentication::Backend->new(
        $config);
}


1;

