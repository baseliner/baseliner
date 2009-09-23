#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Catalyst::Test 'Baseliner';

# my $help = 0;
# GetOptions( 'help|?' => \$help );
# pod2usage(1) if ( $help || !$ARGV[0] );

print request('/service/run/$service')->content . "\n";

1;


