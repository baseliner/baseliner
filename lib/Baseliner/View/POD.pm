package Baseliner::View::POD;

use strict;
our $VERSION = '0.26';

use base qw( Catalyst::View );
use Encode ();
use MRO::Compat;
use Catalyst::Exception;

sub new {
    my($class, $c, $arguments) = @_;
    my $self = $class->next::method($c);
}

sub process {
    my($self, $c) = @_;

    my $output = '';
    my $encoding = 'utf-8';
    $c->res->content_type("text/html; charset=$encoding");
    $c->res->output($output);
}

=head1 TODO
sub runpod2html {
    my($pod, $doindex) = @_;
    my($html, $i, $dir, @dirs);

    $html = $pod;
    $html =~ s/\.(pod|pm)$/.html/g;

    # make sure the destination directories exist
    @dirs = split("/", $html);
    $dir  = "$htmldir/";
    for ($i = 0; $i < $#dirs; $i++) {
	if (! -d "$dir$dirs[$i]") {
	    mkdir("$dir$dirs[$i]", 0755) ||
		die "$0: error creating directory $dir$dirs[$i]: $!\n";
	}
	$dir .= "$dirs[$i]/";
    }

    # invoke pod2html
    print "$podroot/$pod => $htmldir/$html\n" if $verbose;
    Pod::Html::pod2html(
        "--htmldir=$htmldir",
        "--htmlroot=$htmlroot",
        "--podpath=" . join( ":", @podpath ),
        "--podroot=$podroot",
        "--netscape",
        "--header",
        ( $doindex ? "--index" : "--noindex" ),
        "--" . ( $recurse ? "" : "no" ) . "recurse",
        ( $#libpods >= 0 ) ? "--libpods=" . join( ":", @libpods ) : "",
        "--infile=$podroot/$pod",
        "--outfile=$htmldir/$html"
    );
    Catalyst::Exception->throw("$0: error running $pod2html: $!\n") if $?;
}

=cut

1;
