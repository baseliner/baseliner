Ext.ns('Baseliner');

Baseliner.getMessages = function() {
    
    var fields = [ 
			{  name: 'id' },
			{  name: 'id_message' },
			{  name: 'subject' },
			{  name: 'message' },
			{  name: 'sender' },
			{  name: 'active' },
			{  name: 'to' },
			{  name: 'cc' },
			{  name: 'sent' },
			{  name: 'received' },
			{  name: 'type' }
    ];

	var store=new Ext.data.JsonStore({
		root: 'data' , 
		remoteSort: true,
		totalProperty:"totalCount", 
		id: 'id', 
		url: '/message/im_json',
		fields: fields
	});
    
    store.on('load', function(obj, rec, options ) {
        try {
            store.each( function(rec) {
                //alert( rec.type );
                var title;
                var msg = '';
                var sender = rec.data.sender.length > 0 ? "<% _loc('Message from') %> " + rec.data.sender : "<% _loc('Message') %>";
                if( rec.data.message.length > 0 ) {
                    title = rec.data.subject.length > 0 ? rec.data.subject : sender ;
                    msg = rec.data.message;
                } else {
                    title = sender ;
                    msg = rec.data.subject;
                }
                Baseliner.message( title, msg );
            });
        } catch(e) {
            console.log(e);
        }
    });
    store.load();
}

Baseliner.startRunner = function() {

    var runTasks = function(){
        Baseliner.getMessages();
    };

    var task = {
        run: runTasks,
        interval: <% $c->stash->{timer_interval} || 30000 %>
    };

    Baseliner.runner = new Ext.util.TaskRunner();
    Baseliner.runner.start(task);
}
