=head1 NAME

Baseliner::Core::DBI - DBI convenience subs. 

=head1 SYNOPSIS
    
    my $db = new Baseliner::Core::DBI({ model=>'Baseliner' });
    my %results = $db->hash( 'select * from table' );
    $db->commit;

    # for the dbi savvy:
    my $dbh = $self->dbh;

=cut
package Baseliner::Core::DBI;
use Baseliner::Plug;
use Baseliner::Utils;
use DBI;

has 'model' => ( is=>'rw', isa=>'Str', default=>'Baseliner' );
has 'dbi' => ( is=>'rw', isa=>'Any' );

sub dbh {
    my $self = shift;
    return $self->model
        ? Baseliner->model($self->model)->storage->dbh
        : $self->dbi;
}

sub commit {
    my $self = shift;
    $self->dbh->commit;
}

sub rollback {
    my $self = shift;
    $self->dbh->rollback;
}

sub do {
    my ($self,$sql) = @_;
    my $cnt = $self->dbh->do( $sql );
    $cnt=0 if($cnt eq "0E0");
    return $cnt;
}

sub value {
    my ($self,$sql) = @_;
    my $ret;
    my $stmt = $self->dbh->prepare( $sql );
    my $cnt = $stmt->execute;
    $stmt->bind_columns( undef, \$ret );
    $stmt->fetch;
    $stmt->finish;
    return $ret;
}

sub hash {
    my ($self,$sql) = @_;
    my %ret;
    my $stmt = $self->dbh->prepare( $sql );
    my $cnt = $stmt->execute;
    while( my @row = $stmt->fetchrow_array ) {
        my $key = shift @row;
        $ret{$key} = [ @row ];
    }
    $stmt->finish;
    return %ret;
}

sub array_hash {
    my ($self,$sql) = @_;
    my @ret;
    my $stmt = $self->dbh->prepare( $sql );
    my $cnt = $stmt->execute;
    while( my $row = $stmt->fetchrow_hashref('NAME_lc') ) {
        push @ret, $row;
    }
    $stmt->finish;
    return @ret;
}

sub array {
    my ($self,$sql) = @_;
    my @ret;
    my $stmt = $self->dbh->prepare( $sql );
    my $cnt = $stmt->execute;
    while( my @row = $stmt->fetchrow_array ) {
        push @ret,@row;
    }
    $stmt->finish;
    return @ret;
}

# Oracle Procedures

sub ora_func {
    my ($self,$sql) = @_;
	my $ret = ();
	my $stmt = $self->dbh->prepare("BEGIN 
					$sql;
				END;");
				
    #$stmt->bind_param_inout(1, \$ret, 1 );
	$stmt->execute;
	return $ret;
}

sub ora_proc {
    my ($self,$sql) = @_;
	my $stmt = $self->dbh->prepare("BEGIN 
					:1 := $sql;
				END;");
    my $sth2='';
    my %ret;
    eval q{ require DBD::Oracle qw(:ora_types) };
    _throw(__PACKAGE__.": Oracle perl libraries not available.")
        if( $@ );
    my $type = eval "{ ora_type => ORA_RSET }";
	$stmt->bind_param_inout(1, \$sth2, 0, $type );
	$stmt->execute();
	while ( my @row = $sth2->fetchrow_array ) { 
		    my $key = shift @row;
            $ret{$key} = ( [ @row ] );
	}
    $stmt->finish;
	return %ret;
}

# Legacy

sub oval { value(@_) }
sub osqla { array(@_) }
sub osqlh { hash(@_) }
sub osqlah { array_hash(@_) }

1;
