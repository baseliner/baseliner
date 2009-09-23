use strict;
use warnings;
use Getopt::Long;
use FindBin '$Bin';
use Path::Class;

GetOptions(
    'dir|d'        => \( my $fdir ),
);

scalar( @ARGV ) or die "usage: feature.pl [-d feature_dir ] feature_name\n";

$fdir ||= $Bin.'/../features';

die "Could not find the features directory '$fdir'\n" unless -d $fdir;
chdir $fdir or die $!;

for my $feature ( @ARGV ) {
	my ($name) = split /_|-/, $feature;
	my $dir = Path::Class::dir( $feature );
	warn "Feature dir $dir already exists. Overwriting.\n" if -d $dir;
	mkdir $feature;
	mkdir "$feature/lib";
	mkdir "$feature/t";
	mkdir "$feature/root";
	mkdir "$feature/root/static";
	mkdir "$feature/root/comp";
	mkdir "$feature/lib/BaselinerX";
	open my $out, ">", "$feature/$feature.conf";
	print $out "<$name>\n";
	print $out "</$name>\n";
	close $out;
	print "Feature $feature created successfully in ". $dir->absolute ."\n";
	$dir->recurse( callback => sub { my $d = shift; print " $d\n"; } );
}

