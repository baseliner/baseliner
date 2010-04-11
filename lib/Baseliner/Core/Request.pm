package Baseliner::Core::Request;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Core::Baseline;
use Try::Tiny;

BEGIN {  extends 'Catalyst::Controller' }
register 'action.view.requests' => { name=>'View Requests' };

register 'menu.job.requests' => {
    label    => _loc('Requests'),
    url_comp => '/requests/main',
    actions  => ['action.view.requests'],
    title    => _loc('Requests')
};

1;
