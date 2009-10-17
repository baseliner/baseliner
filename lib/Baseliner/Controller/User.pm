package Baseliner::Controller::User;
use Baseliner::Plug;
use Baseliner::Utils;
BEGIN {  extends 'Catalyst::Controller' }

register 'config.user.global' => {
    preference=>1,
    desc => 'Global Preferences',
    metadata => [
        { id=>'language', label=>'Language', type=>'combo', default=>Baseliner->config->{default_lang}, store=>['es','en']  },
    ]
};
register 'config.user.view' => {
    preference=>1,
    desc => 'View Preferences',
    metadata => [
        { id=>'theme', label=>'Theme', type=>'combo', default=>Baseliner->config->{default_theme}, store=>['gray','blue','slate']  },
    ]
};
use YAML;
sub preferences : Path('/user/preferences') {
    my ($self, $c) = @_;
    my @config = $c->model('Registry')->search_for(key=>'config', preference=>1 );
    $c->stash->{ns} = 'user/'. ( $c->user->username || $c->user->id );
    $c->stash->{bl} = '*';
    $c->stash->{title} = _loc 'User Preferences';
    if( @config ) {
        $c->stash->{config} = [ @config ];
        $c->forward('/config/form_render'); 
    }
}

1;
