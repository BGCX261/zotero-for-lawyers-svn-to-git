REPLACE INTO translators VALUES ('a24aad16-0986-4e43-bc76-93a524fa5de9', '1.0.0b3r1', '', '2007-07-22 11:16:45', '0', '100', '4', 'Thomas - Bills and Resolutions', 'Bill McKinney', 'http://thomas.loc.gov/cgi-bin/b?d?query/D', 
'function detectWeb(doc, url) {
	var namespace = doc.documentElement.namespaceURI;
	var nsResolver = namespace ? function(prefix) {
		if (prefix == ''x'') return namespace; else return null;
	} : null;
	
	var re = /http:\/\/thomas\.loc\.gov\/cgi\-bin\/b?d?query\/D.+/
	if(re.test(url)) {
		return "book";
	} else {
		var aTags = doc.getElementsByTagName("a");
		for(var i=0; i<aTags.length; i++) {
			if(articleRegexp.test(aTags[i].href)) {
				return "multiple";
			}
		}
	}
}', 
'function scrape(doc) {

	var namespace = doc.documentElement.namespaceURI;
	var nsResolver = namespace ? function(prefix) {
		if (prefix == ''x'') return namespace; else return null;
	} : null;
	
	var src = doc.body.innerHTML;
	var newItem = new Zotero.Item("bill");
	
	//http://frwebgate.access.gpo.gov/cgi-bin/getdoc.cgi?dbname=108_cong_bills&docid=f:s970is.txt.pdf"
	var pdfRe = /http\:\/\/frwebgate\.access\.gpo\.gov[^\"]+/
	var pdfMatch = pdfRe.exec(src);
	if (pdfMatch) {
		newItem.url = pdfMatch[0];
		newItem.url = newItem.url.replace(/&amp;/g,''&'');
				
	} else {
		newItem.url = doc.location.href;
	}
	
	newItem.language = "en-us";
	newItem.rights = "Pursuant to Title 17 Section 105 of the United States Code, this file is not subject to copyright protection and is in the public domain.";
	//newItem.title = doc.title;
	
	var url = "";
	
	
	
	var session = "";
	var sessionRe = /\d+\w\w\s+session/i
	var sessionMatch = sessionRe.exec(src);
	if (sessionMatch) {
		session = sessionMatch[0];
	}
	var congress = "";
	var congressRe = /\d+\w\w\s+congress/i
	var congressMatch = congressRe.exec(src);
	if (congressMatch) {
		congress = congressMatch[0];
	}
	var sVal = "";
	if (congress != "") {
		sVal = sVal + congress;
	}
	if (session != "" ) {
		if (congress != "") {
			sVal = sVal + ", ";
		}
		sVal = sVal + session;
	}
	if (sVal != "") {
		newItem.session = congress + ", " + session;
	}
	
	var summaryRe = /\/cgi-bin\/bdquery\/z\?d(\d+):([^0-9]+)\.(\d+):/
	var summaryMatch = summaryRe.exec(src);
	if (summaryMatch) {
		
		var body = summaryMatch [2];
		if (body == "s") {
			newItem.legislativeBody = "Senate";
		} else {
			newItem.legislativeBody = "House of Representatives";
		}
		var billNum = summaryMatch[3];
		billNum = billNum.replace(/^0+/,"");
		newItem.billNumber = billNum;
	
		var summaryUrl = "http://thomas.loc.gov" + summaryMatch[0];
		newItem.attachments.push({title:"Summary", mimeType:"text/html", url:summaryUrl, snapshot:true});
	
		Zotero.Utilities.HTTP.doGet(summaryUrl , function(text) {
			var tmpTxt = text;
			
			//var titleRe= /Title\:\<\/B\>([^<]+)/
			//var titleMatch= titleRe.exec(tmpTxt);
			//if (titleMatch) {
			//	var tmpTitle = titleMatch[1];
			//	tmpTitle = tmpTitle.replace(/^\s+/,"");
			//	tmpTitle = tmpTitle.replace(/\s+$/,"");
			//	newItem.abstract = tmpTitle;
			//} else {
			//	newItem.title = "not found";
			//}
			
					
			var dateRe = /\(introduced\s+(\d+)\/(\d+)\/(\d+)/i
			var dateMatch = dateRe.exec(tmpTxt);
			if (dateMatch) {
				newItem.date = dateMatch[3] + "-" + dateMatch[1] + "-" + dateMatch[2];
			}
			
			var sponsorRe= /<B>Sponsor: <\/B><a[^>]+>([^<]+)</
			var sponsorMatch= sponsorRe.exec(tmpTxt);
			if (sponsorMatch) {
				var sponsorTmp= sponsorMatch[1];
				var name = sponsorTmp.split(",");
				var fname = name[1].replace(/^\s+/,"");
				var lname= name[0].replace(/^\s+/,"");
				lname = lname.replace(/Sen\s+/,"");
				lname = lname.replace(/Rep\s+/,"");
				newItem.creators.push({lastName:lname, firstName:fname, creatorType:"sponsor", fieldMode:true});
			} else {
				newItem.title = "not found";
			}

			var titlesUrl = "";
			var titlesUrlRe = /\/cgi\-bin\/bdquery\/z\?d[^@]+@@@T/
			var titlesUrlMatch = titlesUrlRe.exec(tmpTxt);
			if (titlesUrlMatch) {
				titlesUrl  = "http://thomas.loc.gov" + titlesUrlMatch[0];
				
					Zotero.Utilities.HTTP.doGet(titlesUrl, function(t) {
						var titleText= t;
						//newItem.extra = titleText;
						
						var shortRe = /<li>SHORT TITLE\(S\) AS INTRODUCED:\s+<br>([^<]+)/i
						var shortMatch = shortRe.exec(titleText);
						if (shortMatch) {
							newItem.title = shortMatch[1];
							newItem.shortTitle = shortMatch[1];
						}
						var officialRe = /<li>(OFFICIAL TITLE AS INTRODUCED:\s+)<br>([^<]+)/i
						var officialMatch = officialRe.exec(titleText);
						if (officialMatch) {
							newItem.abstractNote = officialMatch[1].replace(/\s+$/," ") + officialMatch[2].replace(/\s+$/,"");
						}
						newItem.complete();

					});
			} 
		

			
			
		});

	} else {
		// no summary link found
		newItem.complete();
	}
	
}

function doWeb(doc, url) {
	var re=  /http:\/\/thomas\.loc\.gov\/cgi\-bin\/b?d?query\/D.+/
	if(re.test(url)) {
		scrape(doc);
	} else {
		
		var items = Zotero.Utilities.getItemArray(doc, doc, re);
		items = Zotero.selectItems(items);
		
		if(!items) {
			return true;
		}
		
		var urls = new Array();
		for(var i in items) {
			urls.push(i);
		}
		
		Zotero.Utilities.processDocuments(urls, scrape, function() { Zotero.done(); });
		Zotero.wait();
	}
}');