package Baseliner::Controller::Namespace;
use Baseliner::Plug;
use Baseliner::Utils;
BEGIN {  extends 'Catalyst::Controller' }
use YAML;

register 'menu.admin.core.ns' => { label => _loc('List all Namespaces'), url=>'/core/namespaces', title=>_loc('Namespaces')  };

=head2 list

List all namespaces.

Caching, when necessary, should occur in the provider handler. 

Returns a stashed Core::Namespace object list.

=cut
sub list : Private {
	my ($self,$c)=@_;
    my $p = $c->stash->{ns_query};
	$c->stash->{ns_list} = [ $c->model('Namespaces')->namespaces($p) ];
}

=head2 load_namespaces

Returns an array of an array of the kind [ namespace, namespace_text ] list.

Check /namespace/list for parameters.

=cut
sub load_namespaces : Private {
	my ($self,$c)=@_;
    $c->forward( '/namespace/list' );
    my @ns_arr = ();
    foreach my $n ( @{ $c->stash->{ns_list} || [] } ) {
        my $arr = [ $n->ns, $n->ns_text, $n->ns_type ];
        push @ns_arr, $arr;
    }
    $c->stash->{namespaces} = \@ns_arr;
}

sub json : Local {
	my ($self,$c)=@_;
    my $p = $c->stash->{ns_query};
	my @ns = $c->model('Namespaces')->namespaces($p);
    my @ns_hash = map { my %h; @h{keys %{$_}}=values %{$_}; \%h } @ns; 
	$c->stash->{json} = { 
        totalCount=> scalar @ns,
        data => [ @ns_hash ],
     };	
	$c->forward('View::JSON');
}

# Namespace Tree 
#TODO this should be opened on request by level
sub ns_list : Path('/core/namespaces') {
	my ($self,$c)=@_;
	my @ns_list = $c->model('Namespaces')->namespaces();
	my $res='<pre>';
	for my $n ( @ns_list ) {
		$res.= Dump $n
	}
	$c->res->body($res);
}

sub ns_tree_push {
    my $tree = shift;
    my $node = shift;
    return $tree unless $node;
    unless(@_) {
        $tree->{$node} = 1;
    } else {
        $tree->{$node}={} unless ref $tree->{$node};
        ns_tree_push( $tree->{$node}, @_ );
    }
    return $tree;
}
our $idd=0;
sub ns_tree_fold {
    my $tree=shift;
    my @ret=();
    for( sort keys %{ $tree || {} } ) {
        if( ref $tree->{$_} ) {
            push @ret, {  id=>$idd++, leaf=>\0, text=>$_, children=> [ ns_tree_fold( $tree->{$_}) ] };
        } else {
            push @ret, {  id=>$idd++, leaf=>\1, text=>$_ };
        }
    }
    return @ret;
}

sub ns_tree : Path('/ns/tree') {
	my ($self,$c)=@_;
	my @ns_list = $c->model('Namespaces')->namespaces();
    my $tree={};
	for my $n ( @ns_list ) {
        my $ns=$n->{ns};
        my @s = split /\//, $ns;
        shift @s if( $s[0] eq '' );
        next unless @s;
        #$s[0]=qw{/} unless $s[0];
        $tree = ns_tree_push($tree, @s); 
    }
    my @ret=();
    @ret = ns_tree_fold( $tree );
    
    $c->stash->{json} = \@ret;
    #$c->stash->{json} = [ map { { id=>1, leaf=>\0, text=>$_->{ns} } } @ns_list ];
    ## [ { id=>1, text=>'hola', leaf=>\0 }, ];
    $c->forward("View::JSON");
}

sub tree : Local {
	my ($self,$c)=@_;
    my $node = $c->request->parameters->{node};
    my @ret; 
    my $ns = $c->model('Namespaces')->get( $node );
    if( $ns ) {
        foreach my $child ( $ns->children_class ) {  # the ns folders like application, 'package'
            push @ret, {  id=>$child->id, text=>$child->item, leaf=>\0 };
        }
        foreach my $child ( $ns->children ) {
            push @ret, {  id=>$child->id, text=>$child->item, leaf=>\1 };
        }
    }
    $c->stash->{json} = \@ret;
    $c->forward("View::JSON");
}

1;

