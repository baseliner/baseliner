#!/opt/perl/bin/perl
use strict;
use Path::Class;
use Encode qw/is_utf8 encode_utf8/;
use Encode::Guess;
use Pod::Usage;
use Getopt::Long;

my @find;
my @processed;

GetOptions(
    'test|t'        => \( my $test ),
    'conv|c'        => \( my $convert ),
    'delete|d'      => \( my $delete ),
    'block|b=i'      => \( my $block_view ),
    'usual|u'       => \( my $usual ),
    'new|n'         => \( my $new_only ),
    'list|l'        => \( my $list ),
    'help|h'        => \( my $help ),
    'ignore_case|i' => \( my $case ),
    'exe|x=s'       => \( my $exe ),
    'ext|e=s'       => \( my $ext ),
    'find|f=s'      => \@find,
);

pod2usage(1) if $help;

scalar @ARGV or die pod2usage(1);

$ext and $usual and die "options -e and -u are mutually exclusive\n";

my @find_re;
for my $find ( @find ) {
	push @find_re, qr/$find/i;
}

if( $ext ) {
	$ext =~ s{\.}{\\\.}g;
	$ext =~ s{\*}{\.\*}g;
	$ext =~ s{,}{\|}g;
}
my $re = $usual ? qr/^.*\.(pm|mas|pl|js|html|t|po)$/i
: $ext ? qr/^.*$ext$/i : qr//;
process($_) for @ARGV;

execute_cmd(@processed) if $exe;

exit 0;

sub process {
	my $path = shift;
	-d $path ? process_dir($path) : process_file($path);
}

sub process_dir {
	my $path = shift;
	my $dir = Path::Class::dir($path);

	$dir->recurse( callback => sub {
			my $p = shift;
			return if $p->is_dir;
			process_file( $p );
	});
}

sub process_file {
	my $p = shift;
	my $f = $p->basename;
	return if $ext && $f!~ $re;
	scalar(@find) and (find_string($p) or return);
	$convert ? convert( $p ) : $delete ? delete_file($p) : undef;
	push @processed, $p->stringify;
}

sub delete_file {
	my $file = shift;
	print STDERR "d $file\n";
	return if $test;
	unlink $file;
}

sub find_string {
	my $file = shift;
	return if -B $file;
	open my $in, '<', $file or die $!;
	my $curr ;
	my $flag ;
    my @lines = <$in>;
    my $i=0;
    chomp @lines;
	foreach( @lines ) {
		if( found($_) ) {
			$flag ||= 1;
            $curr = $_;
            unless( $list ) {
               if( $block_view ) {
                   print "**** $file: \n\t".join("\n",format_line(@lines[$i-$block_view .. $i+$block_view]) ),"\n";
               } else {
                   ($curr ) = format_line( $curr );
                    $list or print "$file: $curr\n";
               }
            }
		}
        $i++;
	}
	close $in;
	$list and $flag and print "$file\n" ;
	return $flag;
}

sub format_line {
    my @out;
    my $multiple = scalar(@_) > 1 ? 1 : 0;
    for( @_ ) {
        if( $multiple ) {
            s{\t}{ }g;
        } else {
            s{^(\t|\s)+}{}g;
            s{\t+}{ }g;
        }
        push @out, $_;
    }
    @out;
}

sub found {
	my $s = shift;
	my $ok = 1;
	for my $re ( @find_re ) {
		$ok = 0 unless $s=~ m/$re/g;
	}
	return $ok;
}

sub convert {
	my $file = shift;
	open my $in, "<:raw",  $file or die "$file: $!";
	my $d;
	{ 
		local $/;
		$d = <$in>;
		$d=~ s{\r}{}g;
	}
	close $in;

	my $enc = guess_encoding( $d );
	my $name = ref $enc ? $enc->name : '?' ;

	if( $name eq 'utf8' ) {
		print "lf $file (" . $name . " - lf only )";
		write_encoding( $file, $d );
		print "\n";
	} else {
		print "c $file ($name)";
		write_encoding( $file, $d, ':utf8' );
		print "\n";
	}
	
}

sub write_encoding {
	my ($file , $d, $enc) = @_;

	return if $test;

	my $file2 = "${file}.new" ;
	open my $out, ">$enc", $file2  or die $!;
	print { $out } $d or die $!;
	close $out;
	unless( $new_only ) {
		unlink $file;
		rename $file2, $file;
	}
}
sub execute_cmd {
	return unless @_;
	my $cmd = $exe . ' "' . join('" "',@_) . '" ';
	$cmd = "start $cmd" if $^O =~ m/mswin/i ;
	system($cmd);
}

=head1 NAME

scan - find files and do things with them

=head1 SYNOPSIS

 scan.pl [options] path1 path2 ...

 Options:
   -t -test           just list files but don't change anything  
   -u -usual          find the usual file extensions (pm,pl,mas,html,js,t,pod)
   -h -help           display this help and exits
   -b -block n        print find results in blocks of lines
   -c -conv           try to convert files to UNIX LF + UTF-8
   -n -new            create a .new file if converting
   -d -delete         delete files (not directories)
   -l -list           only list files found, to combine with other commands
   -i -ignore_case    ignore case in all matches (content or extension)
   -e -ext            file extensions to search, ex: -e mas,js

 Examples:
      find -f str1 -f str2 .      # finds lines that have both str1 and str2
      find -d -e .bak .           # deletes files that end in .bak
      find -d -e bak,new lib t    # deletes files that end in .bak or .new in ./lib and ./t
      find -t -d -e .bak .        # test deletion list (won't delete anything)
      find -c -u .                # converts to utf8+unix lf files w/ extension .pm, .pl, etc.

=cut
