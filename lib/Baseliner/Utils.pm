package Baseliner::Utils;

=head1 DESCRIPTION

Some utilities shared by different Baseliner modules and plugins.

=cut 

use Exporter::Tidy default => [
    qw/_loc _loc_raw _cut _log _debug _utf8 _tz slashFwd slashBack slashSingle
    _unique _throw say _say _now _now_ora _nowstamp parse_date parse_dt
    _parse_template
    _notify_address
    is_oracle
    _dump _load
    _array
    ns_match ns_split domain_match
    packages_that_do 
    query_array _db_setup/
];
use FindBin '$Bin';
use Locale::Maketext::Simple (
			Style => 'gettext',
			Path => $Bin.'/../lib/Baseliner/I18N',
			Decode => 0,
		);
use Carp;
use DateTime;
use YAML::Syck;
use Class::MOP;
use Sys::Hostname;
use PadWalker qw(peek_my peek_our peek_sub closed_over);
use strict;

BEGIN {
	loc_lang($Baseliner::locale || 'es' );
}

# split a namespace resource into domain and item
our $ns_regex = qr/^(.*?)\/(.*)$/;
sub ns_split {
    my ( $ns ) = @_;

    if( $ns =~ m{$ns_regex} ) {
        return ($1, $2 );       # package/packagename
    }
    elsif( $ns =~ m{^/(.*)$} ) {
        return ( '', $1 );   # /packagename
    }
    elsif( $ns =~ m{^(.*)/$} ) {
        return ( $1, '' );  # application/ 
    }
    else {
        return ( '', $ns );  
    }
}

# check if the first ns string contains the second
sub ns_match {
    my ( $ns, $search ) = @_;

    my ( $domain, $item ) = ns_split( $ns );
    my ( $search_domain, $search_item ) = ns_split( $search );
    return 1 if domain_match( $domain , $search_domain ) && !$search_item;
    return 1 if domain_match( $domain , $search_domain ) && $item eq $search_item;
    return 1 if !$search_domain && $item eq $search_item;
}

# check if search is part of domain
sub domain_match {
    my ( $domain, $search ) = @_;
    return 1 if $domain eq $search;
    return $domain =~ m{\.\Q$search\E$}; 
}

## base standard utilities subs
sub slashFwd {
	(my $path = $_[0]) =~ s{\\}{/}g ;
	return $path;
}

sub slashBack {
	(my $path = $_[0]) =~ s{/}{\\}g ;
	return $path;
}

sub slashSingle {
	(my $path = $_[0]) =~ s{//}{/}g ;
	$path =~ s{\\\\}{\\}g ;
	return $path;	
}

sub _unique {
	keys %{{ map {$_=>1} @_ }};
}

sub _load {
    return YAML::Syck::Load( @_ );
}

sub _dump {
    return YAML::Syck::Dump( @_ );
}

use Encode qw( decode_utf8 encode_utf8 is_utf8 );
sub _loc {
    return unless $_[0];
    return loc( @_ );
    my $context = peek_my(1); ## try to get $c with PadWalker
    if( $context->{'$c'} && ref ${ $context->{'$c'} } ) {
        my $c = ${ $context->{'$c'} };
        my $msg = $c->localize( @_ );
        #return _utf8($msg);
        return $msg;
    } else {
        my $msg = loc( @_ );
        #return _utf8($msg);
        return $msg;
    }
}

sub _loc_raw {
    return loc( @_ );
}

sub _utf8 {
    my $msg = shift;
    is_utf8($msg) ? $msg : decode_utf8($msg);
}

sub _log {
    my ($cl,$fi,$li) = caller() || '*';
	print STDERR ( _now()." [$cl $$] - ", @_, "\n" );
}

#TODO check that global DEBUG flag is active
sub _debug {
    my ($cl,$fi,$li) = caller() || '*';
	print STDERR ( _now()." [$cl $$] - ", @_, "\n" );
}

sub _throw {
	#Carp::confess(@_);
	#die join('', @_ , "\n");
    Catalyst::Exception->throw( @_ );
}

sub say {
    print @_, "\n";
}

sub _say {
	print @_,"\n" if( $Baseliner::DEBUG );
} 

sub _tz {
    return Baseliner->config->{time_zone} || 'CET';
}

sub _now {
    my $now = DateTime->now(time_zone=>_tz);
    $now=~s{T}{ }g;
    return $now;
}

sub _nowstamp {
    (my $t = _now )=~ s{\:|\/|\\|\s}{}g;
    return $t;
}

sub _now_ora {
    return DateTime->now(time_zone=>_tz);
}

sub _cut {
    my ($index, $separator, $str ) = @_;
    my @s = split /$separator/, $str;
    my $max = $#s;
    my $top = $index > 0 ? $index : $max + $index;
    return join $separator, @s[ 0..$top ];
}

# date natural parsing 
use DateTime::Format::Natural;
sub parse_date {
    my ( $format, $date ) = @_;
    my $parser = DateTime::Format::Natural->new( format=>$format );
    return $parser->parse_datetime(string => $date);
}

# alternative parsing with strpdate
sub parse_dt {
    my ( $format, $date ) = @_;
    use DateTime::Format::Strptime;
    my $parser = DateTime::Format::Strptime->new( pattern => $format );
    return $parser->parse_datetime( $date );
}

# return an array with hashes of data from a resultset
sub rs_data {
	my $rs = shift;
	my @data;
	while( my $row = $rs->next ) {
		push @data, { $row->get_columns };
	}
	return @data;
}

sub query_array {
    my $query = shift;
    {
        no warnings;  # may be empty strings, unitialized
        my $txt = join ',', @_;    ##TODO check for "and", "or", etc. with text::query
        return $txt =~ m/$query/i;
    }
}

# setup some data standards at a lower level
sub _db_setup {
    my $dbh = Baseliner->model('Baseliner')->storage->dbh;
    return unless $dbh;
    if( $dbh->{Driver}->{Name} eq 'Oracle' ) {
        $dbh->do("alter session set nls_date_format='yyyy-mm-dd hh24:mi:ss'");
        $dbh->{LongReadLen} =  Baseliner->config->{LongReadLen} || 100000000; #64 * 1024;
        $dbh->{LongTruncOk} = Baseliner->config->{LongTruncOk}; # do not accept truncated LOBs	
    }
}

sub packages_that_do {
    my $role = shift;

    my @packages;
    my %cl=Class::MOP::get_all_metaclasses;
    for my $package ( grep !/::Role/, grep /^Baseliner/, keys %cl ) {
        my $meta = Class::MOP::get_metaclass_by_name($package);
        push @packages, $package
            if( $meta->isa('Moose::Meta::Class') && $meta->does( $role ) );
    }
    return @packages;
}

# creates an array from whatever arrays
sub _array {
    my @array;
    for my $item ( @_ ) {
        if( ref $item eq 'ARRAY' ) {
            push @array, @{ $item };
        } elsif( ref $item eq 'HASH' ) {
            push @array, %{ $item };
        } else {
            push @array, $item if $item;
        }
    }
    return @array;
}

sub is_oracle {
    return Baseliner->model('Baseliner')->storage->dbh->{Driver}->{Name} =~ m/oracle/i;
}

use Text::Template;
sub _parse_template {
    my ( $template, %vars ) = @_;

	my $tt = Text::Template->new( 
					TYPE => "FILE",
                    SOURCE => $template ) or _throw _loc("Could not open template file %1", $template);
	my $body = $tt->fill_in( 
		HASH=> \%vars,
		BROKEN => sub { 
			my %p=@_; 
			_throw _loc("Error loading template '%1': '%2'",$p{template},$p{text} ); 
		},
		DELIMITERS => [ '<%','%>' ] 
	);
    return $body;
}

sub _notify_address {
    my $host = Baseliner->config->{host} || lc(Sys::Hostname::hostname);
    my $port = $ENV{BASELINER_PORT} || $ENV{CATALYST_PORT} || 3000;
    return "http://$host:$port";
}

1;

__END__

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008 The Authors of Baseliner.org. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
