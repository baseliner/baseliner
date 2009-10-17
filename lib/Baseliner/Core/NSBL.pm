=head1 Baseliner::Core::NSBL
    
A combined representation of Namespace + Baseline

=cut
package Baseliner::Core::NSBL;
use Baseliner::Utils;
use Moose;

has 'ns' => ( is=>'rw', isa=>'Object', required=>1 ); ## the namespace
has 'bl' => ( is=>'rw', isa=>'Object', required=>1 ); ## the baseline

no Moose;

use Baseliner::Core::Namespace;
use Baseliner::Core::Baseline;

sub best_match {
    my ($ns,$bl,@values) = @_;
    my $val;
    for( @values ) {
        $val = $_->{value} if( ($_->{bl} eq $bl) && ($_->{ns} eq $ns) );
    }
    unless( defined $val || ($ns eq '/' && $bl eq '*') ) {
        if( $bl ne '*' ) {
            return best_match( $ns, '*', @values );
        }
        else {
            if( $ns ne '/' ) {
                my @ns2 = split /\//, $ns;
                $ns = join "/", @ns2[ 0..(scalar(@ns2)-2) ]; 
                return best_match( $ns, '*', @values );
            } else {
                return best_match( '/', '*', @values );
            }
        }
    }
    return $val;
}

sub sort_nsbl {
    my $opt = ref $_[0] ? shift : {} ;
    my @nsbl = @_;
    for my $ns ( Baseliner::Core::Namespace::sort_ns({ asc=>1 }, @ns ) ) {
    }
}

1;

