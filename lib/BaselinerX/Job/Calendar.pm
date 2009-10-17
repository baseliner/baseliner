package BaselinerX::Job::Calendar;
use Baseliner::Plug;
use Baseliner::Utils;

register 'menu.job.calendar' => { label => _loc('Job Calendars'), url_comp=>'/job/calendar_list', title=>_loc('Job Calendars') };

register 'config.job.calendar' => {
	metadata=> [
		{ id=>'name', label => 'Calendar', type=>'text', width=>200 },
		{ id=>'ns', label => 'Namespace', type=>'text', width=>300 },
		{ id=>'ns_desc', label => 'Namespace Description', type=>'text', width=>300 },
	],
};


1;
