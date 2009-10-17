package Baseliner::Controller::About;
use strict;
use warnings;
use parent 'Catalyst::Controller';
use Baseliner::Plug;
use Baseliner::Utils;

register 'menu.admin.about' => { label => _loc('About...'), url => '/about/show', title=>_loc('About Baseliner'), index=>999 };

sub dehash {
    my $v = shift;
    my $ret ='';
    if( ref($v) eq 'HASH' ) {
        $ret.='<ul>';
        for( sort keys %{ $v || {} } ) {
           $ret .= "<li>$_: " . dehash( $v->{$_} ) . '</li>'; 
        }
        $ret.='</ul>';
    } elsif( ref($v) eq 'ARRAY' ) {
        for( sort @{ $v || [] } ) {
           $ret .= "<li>".dehash($_) . '</li>';
        }
    } else {
        $ret = $v; 
    }
    return $ret;
}

use Sys::Hostname;
sub show : Local {
    my ( $self, $c ) = @_;
    my @about = map { { name=>$_, value=>$c->config->{About}->{$_} } } keys %{ $c->config->{About} || {} };
    push @about, { name=>'Perl Version', value=>$] };
    push @about, { name=>'Hostname', value=>hostname };
    push @about, { name=>'Process ID', value=>$$ };
    push @about, { name=>'Server Time', value=>_now };
    #push @about, { name=>'Path', value=>join '<li>',split /;|:/,$ENV{PATH} };
    push @about, { name=>'OS', value=>$^O };
    #push @about, { name=>'Library Path', value=>join '<li>',split /;|:/,$ENV{LIBPATH} || '-' };
    #$body = dehash( $c->config );
    $c->stash->{about} = [ @about ];
    $c->stash->{template} = '/site/about.html';
}
1;
