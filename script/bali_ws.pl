#!/usr/bin/perl
use strict;
use warnings;
use RPC::XML::Client;

my $service = shift @ARGV;

my $server = $ENV{BASELINER_SERVER} || $ENV{CATALYST_SERVER} || 'localhost';
my $port = $ENV{BASELINER_PORT} || $ENV{CATALYST_PORT} || 3000;

my $rpc = RPC::XML::Client->new("http://$server:$port/rpc");
my $result = $rpc->simple_request($service, @ARGV );
unless( defined $result ) {
    print STDERR "***RPC Error: " . $RPC::XML::ERROR;
    exit 1;
} else {
    print $result->{msg};
    exit $result->{rc};
}
#use Data::Dumper;
#print Dumper $result;


