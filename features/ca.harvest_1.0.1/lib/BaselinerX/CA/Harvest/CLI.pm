package BaselinerX::CA::Harvest::CLI;
use Moose;
use Baseliner::Utils;
use BaselinerX::CA::Harvest::CLI::Version;
use Path::Class::Dir; 
use File::Spec;
use DateTime;
use FindBin '$Bin';

## General attributes
has 'tempdir' => ( is=>'rw', isa=>'Str', default=>$ENV{BASELINER_TEMP} || $ENV{TEMP} );
has 'harvesthome' => ( is=>'rw', isa=>'Str', default=> $ENV{SCMHOME} || $ENV{HARVESTHOME} );
## Context attributes
has 'broker' => ( is=>'rw', isa=>'Str', default=>'localhost' );
has 'login' => ( is=>'rw', isa=>'Str', default=>find_dfo()  );
has 'project' => ( is=>'rw', isa=>'Str' );
has 'state' => ( is=>'rw', isa=>'Str' );


no Moose;

sub find_dfo {
	my $harvest_home = $ENV{HARVESTHOME} || $ENV{SCMHOME} || '';
	my @files = ("$Bin/../etc/baseliner.dfo", "$harvest_home/baseliner.dfo" ) ;
	my @found = grep { -f $_ } @files;
	return $found[0] || './baseliner.dfo';
}

our %cmd_map = ( promote=>'hpp', demote=>'hdp', checkin=>'hci', checkout=>'hco' );

sub _logfile {
    my ($self,$prefix)=@_;
    Path::Class::Dir->new( $self->tempdir . "/$prefix$$-"._nowstamp.".log" );
}

sub _quote { '"'.join('","', @{ $_[0] || [] }) . '"'; }
sub _quote_space { ' "'.join('" "', @{ $_[0] || [] }) . '" '; }

sub run {
    my ($self, %p)=@_;
	my $logfile = $self->_logfile( $p{cmd} );
    my $args;
    for( grep /^\-/, keys %p ) {
        if( defined $p{$_} ) {
            if( ref($p{$_}) eq 'ARRAY' ) {
                $args.= qq{ $_ } . _quote_space( $p{$_} );
            } else {
                $args.= qq{ $_ "$p{ $_ }" };  ## ie. -en aaaa"
            }
        } else {
            $args.= qq{ $_ }; ## ie. -br
        }
    }
    if( ref $p{args} eq 'ARRAY' ) {
        $args.= " ". _quote( $p{args} );
    } else {
        $args.= $p{args};
    }
    my $farg = $self->write_argfile(qq{-o "$logfile" -b "$self->{broker}" $self->{login} $args }); #"
    my @RET = `$p{cmd} -i "$farg" 2>&1`;				
    my $rc = $?;
    my $ret = capture_log($logfile,@RET);
    return wantarray ? ( rc=>$rc, msg=>$ret ) : { rc=>$rc, msg=>$ret };
}

sub promote {
    my ($self, %p)=@_;
    $self->transition( cmd=>'promote', %p );
}

sub transition {
    my ($self, %p)=@_;
    die "Error: no packages selected for promote" if( ! ref $p{packages} );
    my $k = @{ $p{packages} };
    my $cmd = $cmd_map{ $p{cmd} };
    $p{project} ||= $self->project;
    $p{state} ||= $self->state;
    my $packages = '"'.join('","', @{ $p{packages} || [] }) . '"';
	my $r;
	if( $p{process} ) {
		$r = $self->run( cmd=>$cmd, -en=>$p{project}, -st=>$p{state}, -pn=>$p{process}, args=>$p{packages} );
	} else {
		$r = $self->run( cmd=>$cmd, -en=>$p{project}, -st=>$p{state}, args=>$p{packages} );
	}
    if( $r->{rc} eq 0) {
        _log "Promote of $k package(s) ok in $p{en}.", $r->{msg}
    }
    else { 				
        _throw "Error during promotion/demotion.", $r->{msg};
    }
	return $r;
}

sub hsync {
    my ($self, %p)=@_;
    $p{mask} ||= '*';
    my $r = $self->run( cmd=>'hsync', -en=>$p{project}, -st=>$p{state}, -vp=>$p{vp}, -cp=>$p{cp},  );
    return { rc=>$r->{rc}, msg=>$r->{msg}, }; 
}

sub checkout {
    my ($self, %p)=@_;
    $p{mask} ||= '*';
    $p{type} ||= 'br';
    my $r = $self->run( cmd=>'hco', -en=>$p{project}, -st=>$p{state}, -vp=>$p{vp}, -cp=>$p{cp}, "-$p{type}"=>undef, -s=>$p{mask} );
    return { rc=>$r->{rc}, msg=>$r->{msg}, }; 
}

sub select_versions {
    my ($self, %p)=@_;
    my $mask = $p{mask} || '*';
    my $r = $self->run( cmd=>'hsv', -en=>$p{project}, -st=>$p{state}, -vp=>$p{vp}, -p=>$p{package}, -s=>$mask );
    my @versions;
    unless( $r->{rc} ) {
        my @data = split /\n/, $r->{msg}; 
        delete @data[0..2];
        for my $row ( @data ) {
            next unless $row;
            next unless( $row =~ /\t/ );
            my @fields = split /\t/, $row;
			if( $fields[3] eq 'M' and $fields[4] eq '') {  # probably a bug in hsv for Merged items 
				splice @fields,4,1; # delete the 4th extra element
				$fields[4] = 0;   	
			}
			_log _dump \@fields;
            my %h = map { $_=>shift @fields } qw/name path version tag data_size package creator created_on modifier modified_file modified_on/;
            $h{mask} = '/application/nature/project'; #TODO from a config 'harvest.repo.mask'
			$h{modified_on} ||= $h{created_on};
            push @versions, new BaselinerX::CA::Harvest::CLI::Version(\%h);
        }
    }
    return { rc=>$r->{rc}, msg=>$r->{msg}, versions=>\@versions }; 
}

sub write_argfile {
	my ($self, $data) = @_;
    my $infile = Path::Class::Dir->new($self->tempdir . "/harvestparam$$-"._nowstamp().".in");
	open FIN,">$infile" or die "Error: could not create argument file '$infile': $!";
	print FIN $data;
	close FIN;
	return $infile;
}

sub capture_log {   
	my $logfile = Path::Class::Dir->new(shift);
	my @RET;
	push @RET, @_;
	if( (-e $logfile) && (open(LOG,"<$logfile") ) ) {
		my @LogFile=<LOG>;
		close(LOG);
		#unlink $logfile unless($logfile eq "");
		push @RET,@LogFile;
	}
	return join '', @RET;
}
1;

