	Ext.ns('Baseliner');

    Baseliner.tabInfo = {};
    // Cookies
    Baseliner.cookie = new Ext.state.CookieProvider({
            expires: new Date(new Date().getTime()+(1000*60*60*24*300)) //300 days
    });
    //Ext.state.Manager.setProvider(Baseliner.cookie);
    //Baseliner.cook= Ext.state.Manager.getProvider();

    // Errors
    Baseliner.errorWin = function( p_title, p_html ) {
        var win = new Ext.Window({ layout: 'fit', 
            autoScroll: true, title: p_title,
            height: 600, width: 1000, 
            html: p_html });
        win.show();
    };

    // Generates a pop-in message
    Baseliner.message = function(title, format){
        Baseliner.messageRaw({ title: title, pause: 2 }, format );
    };
    Baseliner.messageRaw = function(params, format){
        var title = params.title;
        var pause = params.pause;
        var msgCt;
        if(!msgCt){
            msgCt = Ext.DomHelper.insertFirst(document.body, {id:'msg-div'}, true);
        }
        msgCt.alignTo(document, 't-t');
        var s = String.format.apply(String, Array.prototype.slice.call(arguments, 1));
        var m = Ext.DomHelper.append(msgCt, {html:createBox(title, s)}, true);
        m.slideIn('t').pause(pause).ghost("t", {remove:true});
    };

    // User stuff
    Baseliner.preferences = function() {
		Ext.Ajax.request({
			url: '/user/preferences',
			success: function(xhr) {
				try {
					var comp = eval(xhr.responseText);
                    var win = new Ext.Window({
                        layout: 'fit', 
                        autoScroll: true,
                        title: "<% _loc('User Preferences') %>",
                        height: 400, width: 500, 
                        items: [ { 
                                xtype: 'panel', 
                                layout: 'fit', 
                                items: comp
                        }]
                    });
                    win.show();
				} catch(err) {
                    //TODO something
				}
			},
			failure: function(xhr) {
                //TODO something
			}
		});

    };

    Baseliner.login = function() {
        Baseliner.doLoginForm = function(){
                                var ff = login_form.getForm();
                                ff.submit({
                                    success: function(form, action) {
                                                    var last_login = form.findField('login').getValue();
                                                    Baseliner.cookie.set( 'last_login', last_login ); 
                                                    document.location.href = document.location.href
                                             },
                                    failure: function(form, action) {
                                                    Ext.Msg.alert('<% _loc('Login Failed') %>', action.result.msg );
                                                    login_form.getForm().findField('login').focus('',100);
                                              }
                                });
                           };
       var login_form = new Ext.FormPanel({
            url: '/login',
            frame: true,
            labelWidth: 100, 
            defaults: { width: 150 },
            buttons: [
                { text: '<% _loc('Login') %>',
                  handler: Baseliner.doLoginForm
                },
                { text: '<% _loc('Reset') %>',
                  handler: function() {
                                login_form.getForm().findField('login').focus('',100);
                                login_form.getForm().reset()
                           }
                }
            ],
            items: [
                {  xtype: 'textfield', name: 'login', fieldLabel: "<% _loc('Username') %>", selectOnFocus: true }, 
                {  xtype: 'textfield', name: 'password', inputType:'password', fieldLabel: "<% _loc('Password') %>" } 
            ]
        });
        var win = new Ext.Window({ layout: 'fit', 
            id: 'login-win',
            autoScroll: true, title: "<% _loc('Login') %>",
            height: 150, width: 300, 
            items: [ login_form ]
            });
        win.show();
        var map = new Ext.KeyMap("login-win", [{
            key : [10, 13],
            scope : win,
            fn : Baseliner.doLoginForm
        }]); 
        var last_login = Baseliner.cookie.get( 'last_login'); 
        if( last_login!=undefined && last_login.length > 0 )  {
            login_form.getForm().findField('login').setValue( last_login );
            login_form.getForm().findField('password').focus('',100);
        } else {
            login_form.getForm().findField('login').focus('',100);
        }
    };

    Baseliner.logout = function() {
		Ext.Ajax.request({
			url: '/logout',
			success: function(xhr) {
                document.location.href=document.location.href;
			},
			failure: function(xhr) {
               Baseliner.errorWin( 'Logout Error', xhr.responseText );
			}
		});
    };

	Baseliner.addNewTabDiv = function( div, ptitle){
			var tab = Ext.getCmp('main-panel').add( div );
			Ext.getCmp('main-panel').setActiveTab(tab); 
	};

	//adds a new object to a tab 
	Baseliner.addNewTabItem = function( comp, title, params ) {
		if( params == undefined ) params = { active: true };
		var tabpanel = Ext.getCmp('main-panel');
		var tab = tabpanel.add(comp);
        if( title == undefined || title=='' )
            title = comp.title;
		tab.setTitle( title );
		if( params.active==undefined ) params.active=true;
		if( params.active ) tabpanel.setActiveTab(comp);
        return tab.getId();
	};

	//adds a new fragment component with html or <script>...</script>
	Baseliner.addNewTab = function(purl, ptitle, params ){
			var tab = Ext.getCmp('main-panel').add({ 
					xtype: 'panel', 
					layout: 'fit', 
					autoLoad: {url: purl, scripts:true }, 
					title: ptitle
			}); 
			Ext.getCmp('main-panel').setActiveTab(tab); 
            Baseliner.tabInfo[id] = { url: purl, title: ptitle, type: 'script' };
	};

	Baseliner.runUrl = function(url) {
		Ext.get('run-panel').load({ url: url, scripts:true }); 
	};

    Baseliner.addNewBrowserWindow = function(url,title) {
        window.open(url,title,'');
    };

    Baseliner.error_parse = function( err, xhr ) {
        var str=""; 
        for(var i in err) {
            str+="<li>" + i + "=" + err[i]; 
        }
        var res = xhr.responseText;
        res.replace(/\</,'&lt;');
        res.replace(/\>/,'&gt;');
        str += "<hr><pre>" + res;
        Baseliner.errorWin("<% _loc('Error Rendering Tab Component') %>", str);
    };

	//adds a new tab from a function() type component
	Baseliner.addNewTabComp = function( comp_url, ptitle, params ){
        Baseliner.ajaxEval( comp_url, { }, function(comp) {
            var id = Baseliner.addNewTabItem( comp, ptitle, params );
            Baseliner.tabInfo[id] = { url: comp_url, title: ptitle, type: 'comp' };
        });
	};

	//grabs any eval stuff and feeds it to foo(comp)
	Baseliner.ajaxEval = function( url, params, foo ){
		Ext.Ajax.request({
			url: url,
            params: params,
			success: function(xhr) {
				try {
					var comp = eval(xhr.responseText);
                    foo(comp);
				} catch(err) {
					if( xhr.responseText.indexOf('dhandler') > -1 ) {
						Ext.Msg.alert("Page not found: ", url + '<br>' + xhr.responseText );
					} else {
                        Baseliner.error_parse( err, xhr );
					}
				}
			},
			failure: function(xhr) {
				var win = new Ext.Window({ layout: 'fit', 
					autoScroll: true, title: ptitle+' create failed', 
					height: 600, width: 600, 
					html: 'Server communication failure:' + xhr.responseText });
				win.show();
			}
		});
	};



    Baseliner.detachCurrentTab = function() {
        var tabpanel = Ext.getCmp('main-panel');
        var panel = tabpanel.getActiveTab();
        var id = panel.getId();
        var info = Baseliner.tabInfo[id];
        if( info!=undefined ) {
            if( info.type == 'comp' ) {
                //var win = window.open( '/show_comp/?url=' +info.url, info.title, '' );
                Ext.Ajax.request({
                    url: info.url,
                    success: function(xhr) {
                        Ext.Ajax.request({
                            url: '/detach',
                            params: { detach_html: xhr.responseText, type: 'comp' },
                            success: function(xhr) {
                                var win = window.open( '', 'Titulo', '' );
                                win.document.write(  xhr.responseText );
                            },
                            failure: function(xhr) {
                               Baseliner.errorWin( 'Logout Error', xhr.responseText );
                            }
                        });
                    },
                    failure: function(xhr) {
                       Baseliner.errorWin( 'Logout Error', xhr.responseText );
                    }
                });
            }
            else if( info.type=='script' ) {
                Ext.Ajax.request({
                    url: info.url,
                    params: { detach_html: p.innerHTML },
                    success: function(xhr) {
                        var win = window.open( '/site/detach.html',  info.title, '' );
                        win.document.write( xhr.responseText );
                    },
                    failure: function(xhr) {
                       Baseliner.errorWin( 'Logout Error', xhr.responseText );
                    }
                });
            }
        } else {
            var p = document.getElementById( id );
            Ext.Ajax.request({
                url: '/detach',
                params: { detach_html: p.innerHTML },
                success: function(xhr) {
                    var win = window.open( '', 'Titulo', '' );
                    win.document.write(  xhr.responseText );
                },
                failure: function(xhr) {
                   Baseliner.errorWin( 'Logout Error', xhr.responseText );
                }
            });
        }

    };
	Baseliner.formSubmit = function( form ) {
			var title = form.title;
			if( title == undefined || title == '' ) title = '<% _loc("Submit") %>';
			form.submit({
				success: function(f,a){ Baseliner.message( title , 'Datos actualizados con exito.'); },
				failure: function(f,a){ 
					// OSCAR: He cambiado los mensajes de error para que soporten validaciones..
					switch (a.failureType) {
			            case Ext.form.Action.CLIENT_INVALID:
			                Ext.Msg.alert("Error", "El formulario contiene errores.").setIcon(Ext.MessageBox.ERROR);
			                break;
			            case Ext.form.Action.CONNECT_FAILURE:
			                Ext.Msg.alert("Error", "Fallo de comunicacion").setIcon(Ext.MessageBox.ERROR);
			                break;
			            case Ext.form.Action.SERVER_INVALID:
			               Ext.Msg.alert("Error", a.result.msg).setIcon(Ext.MessageBox.ERROR);					
					}
				}
			});
	};
	Baseliner.templateLoader = function(){
		var that = {};
		var map = {};
		that.getTemplate = function(url, callback) {
			if (map[url] === undefined) {
				Ext.Ajax.request({
					url: url,
					success: function(xhr){
						var template = new Ext.XTemplate(xhr.responseText);
						template.compile();
						map[url] = template;
						callback(template);
					}
				});
			} else {
				callback(map[url]);
			}
		};
	 
		return that;
	};

	Baseliner.showAjaxComp = function(purl,pparams){
		Ext.Ajax.request({
			url: purl,
			params: pparams,
			success: function(xhr) {
				try {
					comp = eval(xhr.responseText);
					comp.show();
				} catch(err) {
					Baseliner.errorWin("<% _loc('Error Rendering Component') %>", err);
				}
			},
			failure: function(xhr) {
				var win = new Ext.Window({ layout: 'fit', 
					id: 'cal-win',
					autoScroll: true, title: ptitle+' create failed', 
					height: 600, width: 600, 
					html: 'Server communication failure:' + xhr.responseText });
				win.show();
			}
		});
	};


	
	// He añadido este metodo para poder parsear facilmente records desde grids
	// Ejemplo de uso:
	//	var selectedRecord = grid.getSelectionModel().getSelected();
	//	miFormPanel.getForm().loadRecord(selectedRecord);

	Ext.form.Action.LoadRecord = Ext.extend(Ext.form.Action.Load, {
		run : function(){
			this.success({
				success: true,
				data: this.options.record.data
			});
		},
		processResponse : function(response){
			return response;
		}
	});	
	
	Ext.form.Action.ACTION_TYPES['loadRecord'] = Ext.form.Action.LoadRecord;
	Ext.override(Ext.form.BasicForm, {
		loadRecord : function(record){
			this.doAction('loadRecord', {record: record});
			return this;
		}
	});
	
	Ext.override(Ext.form.Hidden, {
		setValue: function(v)
		{
			var o = this.getValue();
			Ext.form.Hidden.superclass.setValue.call(this, v);
			this.fireEvent('change', this, this.getValue(), o);
			return this;
		}
	});

    function createBox(t, s){
        return ['<div class="msg">',
                '<div class="x-box-tl"><div class="x-box-tr"><div class="x-box-tc"></div></div></div>',
                '<div class="x-box-ml"><div class="x-box-mr"><div class="x-box-mc"><h3>', t, '</h3>', s, '</div></div></div>',
                '<div class="x-box-bl"><div class="x-box-br"><div class="x-box-bc"></div></div></div>',
                '</div>'].join('');
    }
