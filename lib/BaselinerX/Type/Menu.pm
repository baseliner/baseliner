package BaselinerX::Type::Menu;
use Baseliner::Plug;
with 'Baseliner::Core::Registrable';

register_class 'menu' => __PACKAGE__;

has 'id'=> (is=>'rw', isa=>'Str', default=>'');
has 'name' => ( is=> 'rw', isa=> 'Str' );
has 'label' => ( is=> 'rw', isa=> 'Str' );
has 'index' => ( is=> 'rw', isa=> 'Int', default=>100 );  ## menu ordering 
has 'url' => ( is=> 'rw', isa=> 'Str' );
has 'url_comp' => ( is=> 'rw', isa=> 'Str' );
has 'url_run' => ( is=> 'rw', isa=> 'Str' );
has 'url_js' => ( is=> 'rw', isa=> 'Str' );
has 'url_browser_window' => ( is=> 'rw', isa=> 'Str' );
has 'title' => ( is=> 'rw', isa=> 'Str' );
has 'level' => ( is=> 'rw', isa=> 'Int' );
has 'handler' => ( is=> 'rw', isa=> 'Str' );

use JavaScript::Dumper;
sub ext_menu_json {
	my ($self, %p)=@_;
	js_dumper($self->ext_menu(%p));
}

sub ext_menu {
	my ($self, %p)=@_;
	my $ret={ xtype=> 'tbbutton', text=> $self->{label} };
	my @children;
	for( sort { $a->index <=> $b->index } $self->get_children(%p) ) {
		push @children ,$_->ext_menu;
	}
    my $title = $self->{title} || $self->{label};
	if( defined $self->{url} ) {
		$ret->{handler}=\"function(){ Baseliner.addNewTab('$self->{url}', '$title'); }";
	}
	elsif( defined $self->{url_run} ) {
		$ret->{handler}=\"function(){ Baseliner.runUrl('$self->{url_run}'); }";
	}
	elsif( defined $self->{url_browser_window} ) {
		$ret->{handler}=\"function(){ Baseliner.addNewBrowserWindow('$self->{url_browser_window}', '$title'); }";
	}
	elsif( defined $self->{url_comp} ) {
		$ret->{handler}=\"function(){  Baseliner.addNewTabComp('$self->{url_comp}', '$title'); }";
	}
	elsif( defined $self->{handler} ) {
		$ret->{handler}=\"$self->{handler}";
	}
    elsif( ! @children ) {
        $ret->{handler}=\"function() { Ext.Msg.alert('Error', 'No action defined'); } "; 
    }
	$ret->{menu} = \@children if(@children);
	return $ret;
}
1;
