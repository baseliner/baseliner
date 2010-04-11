use strict;
use warnings;
use Test::More tests => 34;

BEGIN {
    $ENV{BALI_CMD} =1 ;
    #$ENV{BALI_PLUGINS} = 'I18N,Cache,+CatalystX::Features,ConfigLoader';
    #$ENV{CATALYSTX_NO_FEATURES}=1;        
}


BEGIN { use_ok 'Catalyst::Test', 'Baseliner' }
BEGIN { use_ok 'Baseliner::Model::Permissions' }

my $c = Baseliner->commandline;
Baseliner->app( $c );

{
    ok( $c->model('Permissions'), 'got model Permissions' );
}
eval {
    $c->model('Permissions')->delete_role( role=>'Dummy');  #just in case
};
{
    ok( $c->model('Permissions')->grant_role( username=>'DUMMYUSER', role=>'Dummy' ), 'grant user to role');
}

{
    my $action = $c->model('Permissions')->add_action( 'action.dummy', 'Dummy', bl=>'DESA' );
    ok( ref $action, 'action added to role');
}

{
    eval {
        $c->model('Permissions')->add_action( 'action.dummy', 'Dummy', bl=>'DESA' );
    };

    ok( $@, 'duplicate action to role detected' );
}

{
    ok( $c->model('Permissions')->user_has_action( 'DUMMYUSER', 'action.dummy', bl=>'any' ), 'user has action' );
    ok( $c->model('Permissions')->user_has_action( 'DUMMYUSER', 'action.dummy', ), 'user has action, bl not specified' );
    ok( ! $c->model('Permissions')->user_has_action( 'DUMMYUSER', 'action.dummy', bl=>'*' ), 'user does not have action for all bl' );
    ok( $c->model('Permissions')->user_has_action( 'DUMMYUSER', 'action.dummy', bl=>'DESA' ), 'user has action for DESA' );
    ok( ! $c->model('Permissions')->user_has_action( 'DUMMYUSER', 'action.dummy', bl=>'PROD' ), 'user does not have action for PROD' );
}

{
    ok( ! $c->model('Permissions')->user_has_action( 'HAHAHA', 'action.dummy' ), 'a fake user does not have action' );
}

{
    my @users = $c->model('Permissions')->list(action=> 'action.dummy' );
    ok( grep(/^DUMMYUSER$/, @users ), 'user list');
}

{
    my @actions = $c->model('Permissions')->list( username=>'DUMMYUSER'  );
    ok( grep(/^action\.dummy$/, @actions ), 'actions');
}

{
    ok( $c->model('Permissions')->grant_role( username=>'ANOTHERDUMMYUSER', role=>'Dummy', ), 'grant another user to role in one BL');

    my @users = $c->model('Permissions')->list(action=> 'action.dummy', bl=>'DESA' );
    ok( grep(/^ANOTHERDUMMYUSER$/, @users ), 'another user also has action for BL');

    ok( ! $c->model('Permissions')->user_has_action('ANOTHERDUMMYUSER', 'action.dummy', bl=>'PROD' ), 'another user cannot do something for another baseline' );

    ok( ! $c->model('Permissions')->user_has_action('ANOTHERDUMMYUSER', 'action.dummy', bl=>'*' ), 'another user cannot do something for all baselines' );

    ok( $c->model('Permissions')->user_has_action('ANOTHERDUMMYUSER', 'action.dummy', bl=>'any' ), 'another user has action for any baseline' );
    ok( $c->model('Permissions')->user_has_action('ANOTHERDUMMYUSER', 'action.dummy', ), 'another user has action for any baseline implicit' );

}

{
    ok( $c->model('Permissions')->grant_role( username=>'NSDUMMYUSER', role=>'Dummy', ns=>'application/DUMMYAPP' ), 'grant another user to role');

    my @users = $c->model('Permissions')->list(action=> 'action.dummy', ns=>'application/' );
    ok( grep(/^NSDUMMYUSER$/, @users ), 'ns user has action for the domain');

    {
        my @users = $c->model('Permissions')->list(action=> 'action.dummy', ns=>'/DUMMYAPP' );
        ok( grep(/^NSDUMMYUSER$/, @users ), 'ns user has action itemized');
    }

    {
        my @users = $c->model('Permissions')->list(action=> 'action.xdummy', ns=>'/DUMMYAPP' );
        ok( !grep(/^NSDUMMYUSER$/, @users ), 'ns user does not have action itemized');
    }

    {
        my @users = $c->model('Permissions')->list(action=> 'action.dummy', ns=>'/DUMMYAPP' );
        ok( grep(/^DUMMYUSER$/, @users ), 'main user does not have action itemized');
    }

    {
        ok(  $c->model('Permissions')->user_has_action('NSDUMMYUSER', 'action.dummy', ns=>'/DUMMYAPP' ), 
            'user ns has action' );

        ok(  ! $c->model('Permissions')->user_has_action('NSDUMMYUSER', 'action.dummy', ns=>'/APP' ), 
            'user ns does not have action' );

        ok(  $c->model('Permissions')->user_has_action('DUMMYUSER', 'action.dummy', ns=>'/' ), 
            'user / has action' );
    }
}

{
    ok( $c->model('Permissions')->grant_role( username=>'NSDUMMYUSER', role=>'Dummy', ns=>'package/GBP.328.N-000002_carga_inicial' ), 'grant another user to role');

    my @users = $c->model('Permissions')->list(action=> 'action.dummy', ns=>'application/' );
    ok( grep(/^NSDUMMYUSER$/, @users ), 'ns user has action for the domain');
}

{
    ok( $c->model('Permissions')->deny_role( username=>'ANOTHERDUMMYUSER', role=>'Dummy' ), 'role denied to another user' );

    my @users = $c->model('Permissions')->list(action=> 'action.dummy', bl=>'DESA' );
    ok( ! grep(/^ANOTHERDUMMYUSER$/, @users ), 'another user does not have the action anymore');
}

{
    ok( $c->model('Permissions')->delete_role( role=>'Dummy' ), 'role deleted');
}
{
    ok( ! $c->model('Permissions')->user_has_action( 'DUMMYUSER', 'action.dummy' ), 'dependent data deleted');
}

{
    my @users = $c->model('Permissions')->list(action=> 'action.job.approve', ns=>'/GBP.0000', bl=>'DESA' );
    warn "USERS=" . join  ',',@users;
}
