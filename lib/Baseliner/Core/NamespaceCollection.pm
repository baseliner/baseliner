package Baseliner::Core::NamespaceCollection;
use Moose;

with 'Baseliner::Role::Namespace';

has 'items' => ( is=>'rw', isa=>'ArrayRef', default=>sub {[]} );

sub next {  }

sub search {  }

1;
