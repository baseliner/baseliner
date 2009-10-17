package BaselinerX::Job::Controller::Log;
use Moose;
use Baseliner::Utils;
use JavaScript::Dumper;
use Compress::Zlib;
use YAML;
use JSON::XS;

BEGIN { extends 'Catalyst::Controller' }

sub logs_list : Path('/job/log/list') {
    my ( $self, $c ) = @_;
	my $p = $c->req->params;
    $c->stash->{id_job} = $p->{id_job};
    $c->stash->{template} = '/comp/log_grid.mas';
}

sub logs_json : Path('/job/log/json') {
	my ( $self,$c )=@_;
    _db_setup;
	my $p = $c->request->parameters;
    my ($start, $limit, $query, $dir, $sort, $filter, $cnt ) = @{$p}{qw/start limit query dir sort filter/};
    $limit||=50;
    $filter = decode_json $filter if $filter;
    CORE::warn Dump $filter;
	my $config = $c->registry->get( 'config.job.log' );
	my @rows = ();
    #TODO    store filter preferences in a session instead of a cookie, on a by id_job basis
    #my $job = $c->model( 'Baseliner::BaliJob')->search({ id=>$p->{id_job} })->first;
    my $rs = $c->model( 'Baseliner::BaliLog')->search($p->{id_job} ? { id_job=>$p->{id_job} } : undef,
                {   order_by=> $sort ? "$sort $dir" : 'me.id',
                    join=>['job'], prefetch=>['job'],
                });
	while( my $r = $rs->next ) {
        my $data = uncompress( $r->data ) || $r->data;
        next if( $query && !query_array($query, $r->job->name, $r->get_column('timestamp'), $r->text, $r->provider, $r->lev, $r->data_name, $data, $r->ns ));
        if( $filter ) {
           next if defined($filter->{$r->lev}) && !$filter->{$r->lev};
        }
        my $data_len = length( $data || '' ) ;
        my $more = $r->more;
        my $data_name = $r->data_name || ''; 
        my $file = $data_name =~ m/\.\w+$/
            ? $data_name
            : ( $data_len > ( 4 * 1024 ) )
                ? $data_name . ".txt"
                : '';
        push @rows,
          {
            id       => $r->id,
            id_job   => $r->id_job,
            job      => $r->job->name,
            text     => $r->text,
            ts       => $r->get_column('timestamp'),
            lev      => $r->lev,
            module   => $r->module,
            ns       => $r->ns,
            provider => $r->provider,
            more     => { more=>$more, data_name=> $r->data_name, data=> $r->data ? \1 : \0, file=>$file },
          } if( ($cnt++>=$start) && ( $limit ? scalar @rows < $limit : 1 ) );
	}
	$c->stash->{json} = {
        totalCount => $cnt,
        data => \@rows
     };	
    # CORE::warn Dump $c->stash->{json};
	$c->forward('View::JSON');
}

sub log_data : Path('/job/log/data') {
    my ( $self, $c ) = @_;
    _db_setup;
	my $p = $c->req->params;
	my $log = $c->model('Baseliner::BaliLog')->search({ id=> $p->{id} })->first;
	$c->res->body( "<pre>" . (uncompress($log->data) || $log->data)  . " " );
}

sub log_file : Path('/job/log/download_data') {
    my ( $self, $c ) = @_;
    _db_setup;
	my $p = $c->req->params;
	my $log = $c->model('Baseliner::BaliLog')->search({ id=> $p->{id} })->first;
    my $filename = $p->{file_name} || $log->data_name || 'attachment-'.$log->id_job.'-'.$p->{id}.'.dat';
    $c->res->header('Content-Disposition', qq[attachment; filename="$filename"]);
	$c->res->body( uncompress($log->data) || $log->data );
}

1;
