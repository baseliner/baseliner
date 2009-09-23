package BaselinerX::Job;
use Baseliner::Plug;
use Baseliner::Utils;
use DateTime;
use YAML;

BEGIN { 
    ## Oracle needs this
    $ENV{'NLS_DATE_FORMAT'} = 'YYYY-MM-DD HH24:MI:SS';
}

register 'config.job.daemon' => {
	metadata=> [
		{  id=>'frequency', label=>'Job Server Frequency', type=>'int', default=>10 },
	]
};

register 'config.job' => {
	metadata=> [
		{ id=>'jobid', label => 'Job ID', type=>'text', width=>200 },
		{ id=>'name', label => 'Job Name', type=>'text', width=>180 },
		{ id=>'starttime', label => 'StartDate', type=>'text', },
		{ id=>'maxstarttime', label => 'MaxStartDate', type=>'text', },
		{ id=>'endtime', label => 'EndDate', type=>'text' },
		{ id=>'status', label => 'Status', type=>'text', default=>'READY' },
		{ id=>'mask', label => 'Job Naming Mask', type=>'text', default=>'%s.%s-%08d' },
		{ id=>'runner', label => 'Registry Entry to run', type=>'text', default=>'service.job.runner.simple.chain' },
		{ id=>'comment', label => 'Comment', type=>'text' },
        { id=>'step', label => 'Which phase of the job, pre, post or run', default => 'RUN' },
	],
	relationships => [ { id=>'natures', label => 'Technologies', type=>'list', config=> 'config.tech' },
		{ id=>'releases', label => 'Releases', type=>'list', config=> 'config.release' },
		{ id=>'apps', label => 'Applications', type=>'list', config=> 'config.app' },
		{ id=>'rfcs', label => 'RFCs', type=>'list', config=>'config.rfc' },
	],
};

register 'action.job.create' => { name=>'Create New Jobs' };
register 'menu.job' => { label => _loc('Jobs') };
register 'menu.job.create' => { label => _loc('Create a new Job'), url=>'/job/create', title=>_loc('New Job'), actions=>['action.job.create'] };
#register 'menu.job.list' => { label => 'List Current Jobs', url=>'/maqueta/list.mas', title=>'Job Monitor' };
#register 'menu.job.exec' => { label => 'Exec Current Jobs', url_run=>'/maqueta/list.mas', title=>'Job Monitor' };
#register 'menu.job.hist' => { label => 'Historical Data', handler => 'function(){ Ext.Msg.alert("Hello"); }' };
register 'menu.job.list' => { label => 'Monitor', url_comp => '/job/monitor', title=>'Monitor' };
#register 'menu.job.hist.all' => { label => 'List all Jobs', url=>'/core/registry', title=>'Registry'  };

register 'service.job.new' => {
	name => 'Schedule a new job',
	config => 'config.job',
	handler => sub {
        my ($self, $c, $config) = @_;
        $c->model('Jobs')->create_job( $config );
    }
};



1;
