use strict;
use warnings;

use Test::More tests => 1;                      # last test to print

use File::Spec;
my $file = File::Spec->rel2abs(__FILE__);
my $dir = [ File::Spec->splitpath( $file ) ]->[1];
#print $dir;

use Path::Class;
my $f = Path::Class::file( __FILE__ );
#print $f->parent->absolute;
ok Path::Class::dir( 'F:\deva' )->contains( $f ); 
#ok $f->parent->contains( 'F:\dev' );
