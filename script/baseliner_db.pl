#!/usr/bin/env perl

BEGIN { $ENV{CATALYST_DEBUG} = 0 }
use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin/../lib";
use Baseliner::Schema::Baseliner;
use Config::General;




my $cfg = Config::General->new("$Bin/../baseliner.conf");
my $config =  { $cfg->getall };

my ($dsn, $user, $pass) = @ARGV;
eval {
    if (!$dsn) {
        ($dsn, $user, $pass) =
          @{$config->{'Model::Baseliner'}->{'connect_info'}};
    };
};
if($@){
    die "Your DSN line in baseliner.conf doesn't look like a valid DSN.".
      "  Add one, or pass it on the command line.";
}
die "No valid Data Source Name (DSN).\n" if !$dsn;
$dsn =~ s/__HOME__/$FindBin::Bin\/\.\./g;

my $schema = Baseliner::Schema::Baseliner->connect($dsn, $user, $pass) or 
  die "Failed to connect to database";

print "Deploying schema to $dsn\n";
$schema->deploy({add_drop_table=>0, trace=>1});
#$schema->create_initial_data();
