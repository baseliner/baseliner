/***************************************************************************
* IE Margin Fix
* Copyright 2002 by David Schontzler | www.stilleye.com
* Free to use under GNU General Public License as long as this message
*  remains intact.
* Description:  This script will fix the horizontal margin support in IE5/6
***************************************************************************/

if(!Array.prototype.push)
{
	Array.prototype.push =  function()
	{
		var i;
		for(i=0; j=arguments[i]; i++) this[this.length] = j;
		return this.length;
	}
}

IEmarginFix =
{
	run : null,
	
	kill : function()
	{
		clearTimeout("IEmarginFix.run");
	},
	
	init : function()
	{
		var valid = navigator.userAgent.toLowerCase().indexOf('mac') == -1 && document.all && document.getElementsByTagName && document.compatMode != "CSS1Compat";
		if(!valid) return;
		var ss = document.styleSheets;
		var auto, list, s, i, elm, expr, blk;
		auto = new Array();
		list = new Array();
		s = this.getRules();
		
		for(i=0; i<s.length; i++)
			if( this.checkMargin(s[i][1]) )
				auto.push(s[i][0]);
		
		for(i=0; a = auto[i]; i++)
		{
			ss[ss.length-1].addRule(a, "position : relative; left : expression((this.parentNode.offsetWidth - this.offsetWidth) / 2);");
		}
		this.list = auto;
		
		if(window.attachEvent) window.attachEvent("onload", IEmarginFix.checkInline);
	},
	
	checkInline : function()
	{
		var i, a, elm, blk, list = new Array(), auto = IEmarginFix.list;
		for(i=0; a = auto[i]; i++)
		{
			if( a.charAt(0) == '.' )
				list = list.concat( IEmarginFix.getClass(a.substring(1)) );
			else if( a.charAt(0) == '#' )
				list.push( document.all[a.substring(1)] );
			else
				list = list.concat( document.getElementsByTagName(a) );
		}
		
		for(i=0; i<list.length; i++)
		{
			elm = list[i];
			if(elm)
			{
				blk = IEmarginFix.getStyle(elm, "display");
				if(blk != "block" && ( IEmarginFix.ie50 ? !IEmarginFix.ie50check(elm.tagName) : blk != "list-item" ) ) // check for existence and block item
				{
					try {
						elm.style.position = "static";
						elm.style.left = "auto";
					} catch(e) {
					}
				}
			}
		}
	},
	
	checkMargin : function(str)
	{
		return (
			str.match(/margin\s*:\s*auto(;|$)/i)
			|| str.match(/margin\s*:\s*\S+\s+auto(;|$)/i)
			|| ( str.match(/margin-left\s*:\s*auto(;|$)/i) && str.match(/margin-right\s*:\s*auto(;|$)/i) )
			|| str.match(/margin\s*:\s*\S+\s+auto\s+\S+(;|$)/i)
			|| str.match(/margin\s*:\s*\S+\s+auto\s+\S+\s+auto(;|$)/i)
		);
	},
	
	/* these next few methods are basically for IE 5.0's bad interpretation of the "display" property
	(always returning "inline" unless explicitly set, even for block elements! */
	
	ie50 : navigator.appVersion.toLowerCase().indexOf("msie 5.0") != -1,
	
	ie50check : function(tag)
	{
		var i;
		tag = tag.toUpperCase();
		for(i=0; i<this.blockElms.length; i++)
			if(tag == this.blockElms[i])
				return true;
		return false;
	},
	
	blockElms : new Array("ADDRESS", "BLOCKQUOTE", "BODY", "CENTER", "COL", "COLGROUP", "DD", "DIR", "DIV", "DL", "DT", "FIELDSET", "FORM", "FRAME", "HN", "HR", "IFRAME", "LEGEND", "LI", "LISTING", "MARQUEE", "MENU", "OL", "P", "PLAINTEXT", "PRE", "TABLE", "TBODY", "TD", "TFOOT", "TH", "THEAD", "TR", "UL", "XMP"),
	
	/* end IE5.0 detect */
	
	getClass : function(cls)
	{
		var el, r, i;
		el = document.all ? document.all : document.getElementsByTagName('*');
		r = new Array();
		for(i=0; el[i]; i++) if(el[i].className == cls) r.push(el[i]);
		if(r.length!=0) return r;
		else return null;
	},
	
	getRules : function(wh) // grabs all the styles
	{
		if(document.styleSheets && document.styleSheets.length)
		{
			var i, j, k, m, x, y, s = new Array(), is = true;
			for(i=0; i < document.styleSheets.length; i++)
			{
				j = document.styleSheets.item(i);
				if(wh) is = (j.title || j.id) == wh;
				if(is)
				{
					if(j.cssRules) // mozilla
					{
						for(k=0; m = j.cssRules.item(k); k++)
						{
							if(m.styleSheet && m.styleSheet.cssRules.length) // imported sheets
								for(x=0; y = m.styleSheet.cssRules.item(x); x++) s.push([y.selectorText, y.style.cssText]);
							else s.push([m.selectorText, m.style.cssText])
						}
					}
					else if(j.rules) // explorer
					{
						if(j.imports && j.imports.length)
						{
							for(k=0; m = j.imports[k]; k++)
								for(x=0; y = m.rules[x]; x++)
									s.push([y.selectorText, y.style.cssText]);
						}
						for(k=0; m = j.rules[k]; k++)
								s.push([m.selectorText, m.style.cssText]);
					}
				}
				if(wh && is) break;
				else is = true;
			}
		}
		return s || null;
	},
	
	getStyle : function(obj,sty)
	{
		try {
			var sty2 = IEmarginFix.compactStyle(sty);
			var r = obj.style[sty2];
			if(r=='')
			{
				if(document.defaultView) r = document.defaultView.getComputedStyle(obj,'').getPropertyValue(sty);
				else r = obj.currentStyle[sty2];
			}
			if(r) return r; else return null;
		} catch(e) {
			return null;
		}
	},

	compactStyle : function(str)
	{
		var s = str.split('-');	var o = [s[0]];
		for(i=1;(j=s[i]);i++) { o[o.length] = j.charAt(0).toUpperCase(); o[o.length] = j.substring(1) };
		return o.join('');
	}
}

IEmarginFix.init();
