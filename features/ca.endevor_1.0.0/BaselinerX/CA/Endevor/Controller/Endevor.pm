package BaselinerX::CA::Endevor::Controller::Endevor;
use Baseliner::Plug;
use Baseliner::Utils;
BEGIN { extends 'Catalyst::Controller' }

use BaselinerX::CA::Endevor;
use JavaScript::Dumper;

register 'menu.endevor' => { label => 'Endevor' };
register 'menu.endevor.cache_contents' => { label=>_loc('Cache Contents'), url=>'/endevor/cache/contents', title=>_loc('Cache Contents') };
register 'menu.endevor.list' =>
  { label => _loc('List Packages'), url_comp => '/endevor/list/pkgs', title=>_loc('Endevor Packages') };
#register 'menu.endevor.list_pkgs' => { label => _loc('List Packages'), url_comp => '/release/list', title=>_loc('Releases') };
register 'menu.endevor.reset' => { label => _loc('Reset Cache'), url_run => '/endevor/reset', title=>'Reset' };
register 'menu.endevor.reload' => { label=>_loc('Reload Cache'), url_run=>'/endevor/reload', title=>_loc('Reload') };


register 'config.endevor.package' => {
    metadata => [
        { id => 'package',     label => 'Package' },
        { id => 'type',        label => 'Type' },
        { id => 'status',      label => 'Status' },
        { id => 'description', label => 'Description' },
        { id => 'env',         label => 'Target Environment' },
    ],
};
use YAML;

sub endevor_list_pkgs : Path('/endevor/list/pkgs') {
    my ( $self, $c ) = @_;
	$c->stash->{template} = '/comp/endevor_pkg_grid.mas';
}

sub endevor_cache_contents : Path('/endevor/cache/contents') {
    my ( $self, $c ) = @_;
    my $cache = $c->cache( backend=>'endevor' );
    if( ref $cache ) {
        $c->res->body( '<pre>' . Dump $cache->get('endevor.packages') );
    }
}

sub reload : Path('/endevor/reload') {
    my ( $self, $c ) = @_;
    $c->forward('/endevor/reset');
    $c->forward('/endevor/packages');
    $c->stash->{title} = _loc 'Endevor';
    $c->stash->{message} = _loc 'Endevor Cache Reset OK';
    $c->stash->{template} = '/comp/run/message.mas';
}

sub reset : Path('/endevor/reset') {
    my ( $self, $c ) = @_;
    my $cache = $c->cache( backend=>'endevor' );
    if( ref $cache ) {
        $cache->remove('endevor.packages');
        $cache->remove('endevor'); #TODO deprecated
    }
    $c->stash->{title} = _loc 'Endevor';
    $c->stash->{message} = _loc 'Endevor Cache Reset OK';
    $c->stash->{template} = '/comp/run/message.mas';
}

sub packages : Path('/endevor/packages') {
    my ( $self, $c ) = @_;
    my $cache = $c->cache( backend=>'endevor' );
    eval {
        my $inf = $c->registry->get('config.endevor.connection')->factory($c);
        alarm $inf->{timeout};
        $SIG{ALRM} = sub {
            die _loc "Timeout Error (timeout="
                . $inf->{timeout}
            . "s) while connected to MVS";
        };
        my $ret;
        my $e = BaselinerX::CA::Endevor->new(
                host  => $inf->{host},
                user  => $inf->{user},
                pw    => $inf->{pw},
                surr  => $inf->{surr},
                class => $inf->{class}
                );
        my %pkgs = $e->pkgs;
        $cache->set('endevor.packages', \%pkgs );
        alarm 0;
    };
    if( my $error = $@ ) {
        alarm 0;
        Catalyst::Exception->throw( $error );
    }
}
 
sub list_pkgs_json : Path('/endevor/list/pkgs_json') {
    my ( $self, $c ) = @_;
    my @rows;
	my $p = $c->request->parameters;
    my ($start, $limit, $query, $dir, $sort, $cnt ) = @{$p}{qw/start limit query dir sort/};
    my $cache = $c->cache( backend=>'endevor');
    my $pkgs_cache = $cache->get('endevor.packages');
    if( ref $pkgs_cache ) {
        foreach (  keys %{ $pkgs_cache || {} } ) {
            my $str = join ',', values( %{ $pkgs_cache->{$_} || {} } );
            next if( $query && !query_array($query, values %{ $pkgs_cache->{$_} || {} } ));
            my $data = {
                package        => $_,
                type           => $pkgs_cache->{$_}->{PKG_TYPE},
                status         => $pkgs_cache->{$_}->{STATUS},
                description    => $pkgs_cache->{$_}->{DESCRIPTION},
                env            => $pkgs_cache->{$_}->{PROM_TGT_ENV},
                backout_status => $pkgs_cache->{$_}->{PKG_BACKOUT_STATUS},
                backout_flag   => $pkgs_cache->{$_}->{BACKOUT_FLG},
            };
            push @rows, $data
                if( ($cnt++>=$start) && ( $limit ? scalar @rows < $limit : 1 ) ) ;
        }
    } else {
        $pkgs_cache ||= {};
        eval {
            my $inf = $c->registry->get('config.endevor.connection')->factory($c);
            alarm $inf->{timeout};
            $SIG{ALRM} = sub {
                die _loc "Timeout Error (timeout="
                    . $inf->{timeout}
                . "s) while connected to MVS";
            };
            my $ret;
            my $e = BaselinerX::CA::Endevor->new(
                    host  => $inf->{host},
                    user  => $inf->{user},
                    pw    => $inf->{pw},
                    surr  => $inf->{surr},
                    class => $inf->{class}
                    );
            my %pkgs = $e->pkgs;
            $cache->set('endevor.packages', \%pkgs );
            for ( keys %pkgs ) {
                my $str = join ',', ;
                next if( $query && !query_array($query, values %{ $pkgs{$_} || {} } ));
                my $data = {
                    package     => $_,
                    type        => $pkgs{$_}{PKG_TYPE},
                    status      => $pkgs{$_}{STATUS},
                    description => $pkgs{$_}{DESCRIPTION},
                    env         => $pkgs{$_}{PROM_TGT_ENV}
                };
                if( ($cnt++>=$start) && ( $limit ? scalar @rows < $limit : 1 ) ) {
                    $pkgs_cache->{$_} = $pkgs{$_};
                    push @rows, $data;
                }
            }
            ##(my $rc = $ret)=~ s{^.*\n\s+EXECUTE.*(\Q$package\E\s+)(\d+)\s*.*$}{$2}sg ;   ##s{^.*END OF EXECUTION LOG - HIGHEST ENDEVOR RC =(.*?)\n.*$}{$1}gs;
            #$ret && (my $rc = $ret)=~ s{^.*Highest return code is (\d+).*$}{$1}sg;
            #  join(',',unpack('c*',$rc))
            #$rc && print "\n\nRETURN CODE = [".$rc."]\n";
            alarm 0;
        };
        if ($@) {
            warn "Timeout Error during list_pkgs_json: $@";
        }
    }
    if( $sort ) {
        @rows = sort { $dir eq 'ASC' ? $a->{$sort} cmp $b->{$sort} : $b->{$sort} cmp $a->{$sort} } @rows;
    }
    $c->stash->{json} = { data => \@rows, totalCount=>scalar @rows };
    $c->forward('View::JSON');
}

sub pkg_data : Path('/endevor/pkg_data') {
    my ( $self, $c ) = @_;
    my $cache = $c->cache( backend=>'endevor' );
    my $p = $cache->get('endevor.packages');
    my $pkg = $c->req->param("package");
    $c->stash->{data}= $p->{$pkg};
    $c->stash->{package}= $pkg;
    $c->stash->{template}       = '/comp/endevor_pkg.mas';
}

=head2 Deprecated
sub list_pkgs : Path('/endevor/list/pkgs') {
    my ( $self, $c ) = @_;
    my $config = $c->registry->get('config.endevor.package');
    $c->stash->{url_store}      = '/endevor/list/pkgs_json';
    $c->stash->{url_add}        = '/endevor/new';
    $c->stash->{url_detail}     = $c->uri_for('/endevor/pkg_data');
    $c->stash->{detail_title}   = 'Package';
    $c->stash->{detail_field}   = 'package';
    $c->stash->{title}          = 'Endevor Packages';
    $c->stash->{columns}        = js_dumper $config->grid_columns;
    $c->stash->{fields}         = js_dumper $config->grid_fields;
    $c->stash->{ordered_fields} = [ $config->column_order ];
    $c->stash->{template}       = '/comp/grid.mas';
}
=cut

1;
