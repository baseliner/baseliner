use strict;
use YAML;
use Getopt::Long;
use Carp;
$SIG{__DIE__ } = \&__carp_confess;
$SIG{__WARN__} = \&__carp_confess;

my @argv = @ARGV;
my $loop=1;
GetOptions(
    'loop|l=i'  => \$loop,
    'verbose|v'	=>\(my $verbose),
    'content|c'	=>\(my $content),
    'headers|h'	=>\(my $headers),
    'echo|e'	=>\(my $echo),
);

sub LWP::Debug::trace {
	return;
}

use WWW::Mechanize::Timed;
use HTTP::Cookies;
#my $cj = HTTP::Cookies->new( file=>'cookie', autosave=>1 );
#cookie: JSESSIONID=0000lHsBlAeuI-NqNcU98ps2qEH:-1
@ARGV || die('missing param url');
for my $url ( @ARGV) {
	print "\n---- $url ----\n";
	my $total=0;
	my @data;
	for(1..$loop) {
		print "Test $_...\n";
		my $ua = WWW::Mechanize::Timed->new();
		#$ua->add_header(  cookie=> 'JSESSIONID=0000vqZOZlXThYRXxULvgwlcP_X:-1' ); 

		$ua->get( $url ) or die "\nCould not get $url: $!\n\n";
		print "Headers Request : ".Dump($ua) if (($headers && !$total) || $echo);
		print "Headers Response: ".Dump($ua->response()->headers()) if (($headers && !$total) || $echo);
		print "Response: ".$ua->content() if (($content && !$total) || $echo);
		#print "Total time: " . $ua->client_total_time . "\n";
		my $et =  $ua->client_elapsed_time;
		print "Elapsed time: " . $et . "\n" if($verbose);
		$total += $et;
		push @data, $et;
	}

	print "Total: $total\n";

	use Statistics::Basic qw(:all);;
	print "Avg: ".($total / @data)."\n";
	print "Median: ".median(@data)."\n";
	print "Req/s: ".( $loop/$total)."\n";
}

