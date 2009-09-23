package BaselinerX::Job::Log;
use Baseliner::Plug;
use Baseliner::Utils;
use JavaScript::Dumper;
use Compress::Zlib;

register 'menu.job.logs' => { label => _loc('Job Logs'), url_comp => '/job/log/list', title=>_loc('Job Logs') };
register 'config.job.log' => {
	metadata => [
		{ id=>'job_id', label=>'Job', width=>200 },
		{ id=>'log_id', label=>'Id', width=>80 },
		{ id=>'lev', label=>_loc('Level'), width=>80 },
		{ id=>'text', label=>_loc('Message'), width=>200 },
	]

};

=head1 Logging

Handles all job logging. 

The basics:

	my $job = $c->stash->{job};
	my $log = $job->logger;
	$log->error( "An error" );

With data:

    $log->error(
        "Another error",
        data      => $stdout_file,
        data_name => 'A title for a log tab'
    );

A file:

    $log->info(
        "An interesting file",
        data      => $file_contents,
        data_name => 'goodfile.txt'
    );

=cut

has 'jobid' => ( is=>'rw', isa=>'Int' );
has 'rc_config' => ( is=>'rw', isa=>'HashRef', default=>sub { { 0=>'info', 1=>'warn', 2=>'error' } } );

=head2 common_log

Centralizes all logging levels. You may create your own levels if you wish.

All data is compressed. 

=cut
sub common_log {
	my ( $lev, $self, $text )=( shift, shift, shift);
    my %p = ( 1 == scalar @_ ) ? ( data=>shift ) : @_; # if it's only a single param, its a data, otherwise expect param=>value,...  
    $text = substr( $text, 0, 2048 );
	my $row = Baseliner->model('Baseliner::BaliLog')->create({ id_job =>$self->jobid, text=> $text, lev=>$lev   }); 
	$p{data} && $row->data( compress $p{data} );  ##TODO even with compression, too much data breaks around here - use dbh directly?
	defined $p{more} && $row->more( $p{more} );
	$p{data_name} && $row->data_name( $p{data_name} );
	$row->update;
    return $row;
}

sub warn { common_log('warn',@_) }
sub error { common_log('error',@_) }
sub fatal { common_log('fatal',@_) }
sub info { common_log('info',@_) }
sub debug { common_log('debug',@_) }


=head2 rc

Allows change the log level depending on a return code value. 

    $log->rc_config({ 0=>'info', 1=>'warn', 99=>'error' });

    # 0 = info
    # 1 to 98 = warning
    # >99 = error

    $log->rc( $some_rc, 'This can be an error or something else', data=>$lots_of_data );

The message will have a " (RC=$rc_code)" string part appended at the end. 

=cut
sub rc {
    my $self = shift;
    my $rc = shift;
    my $msg = shift;
    for my $err ( sort { $b <=> $a } keys %{ $self->rc_config || {} } ) {
        if( $rc >= $err ) {
            common_log( $self->rc_config->{$err}, $self, $msg . " (RC=$rc)" , @_);
            return;
        }
    }
    $self->warn( $msg, @_);
}

=head1 TODO

=over 4

=item * 

Add pluggable log data viewers on the value of "more"

=cut
1;
