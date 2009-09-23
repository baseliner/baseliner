use strict;
use warnings;
use Test::More tests => 24;

BEGIN { use_ok 'Catalyst::Test', 'Baseliner' }
BEGIN { use_ok 'Baseliner::Model::Permissions' }

my $c = Baseliner->new();

my $m;

{
    ok( $m = $c->model('Request'), 'got model Approval' );
}

eval {
    $c->model('Permissions')->delete_role( role => 'Dummy' );    #just in case
};

{
    my $action = 'action.dummy.approve';
    my $item = 'package/GBP.328.N-000002 carga inicial';
    my $bl = '*';
    my $user = 'ROG2833Z';

    ok(
        $c->model('Permissions')
          ->grant_role( username => $user, role => 'Dummy', ns=>$item, bl=>$bl ),
        'grant user to role'
    );

    my $action_obj = $c->model('Permissions')->add_action( $action, 'Dummy' );

    ok( ref $action_obj, 'action added to role' );

    my @users = Baseliner->model('Permissions')->list(
            action => $action,
            ns     => $item,
            bl     => $bl,
        );

    ok( ( grep /$user/, @users ), 'user has action' ), 

    ok( ref my $req = $m->request(
        name   => 'Aprobación del pase N.DESA1029210',
        action => $action,
        vars   => {  reason=>'promoción a producción' },
        ns     => $item,
        bl     => $bl, 
    ),
	'create a request');

}
