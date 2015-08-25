REPLACE INTO translators VALUES ('3af43735-36d3-46ae-9ca8-506ff032b0d3', '1.0.0b4.r1', '', '2007-06-19 06:54:41', '1', '100', '4', 'HeinOnline', 'Bill McKinney', 'http:\/\/heinonline\.org\/HOL\/Page\?handle\=hein\.journals\/.+', 
'function detectWeb(doc, url) {
	var namespace = doc.documentElement.namespaceURI;
	var nsResolver = namespace ? function(prefix) {
		if (prefix == ''x'') return namespace; else return null;
	} : null;
	
	var re = /http:\/\/heinonline\.org\/HOL\/Page\?handle\=hein\.journals\/.+/
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
	
	var newItem = new Zotero.Item("journalArticle");
	newItem.url = doc.location.href;
	
	// publicaton
	var tmpTitle = doc.title;
	var titleRe= /Law Journal Library (.+)\s+-\s+HeinOnline\.org/
	var titleMatch = titleRe.exec(tmpTitle);
	if (titleMatch) {
		newItem.publicationTitle = titleMatch[1];
	} else {
		newItem.publicationTitle = doc.title;
	}
	
	// default title
	newItem.title = doc.title;
	
	// get selected page
	var selectedPage = "1";
	var pageNum = "1";
	var p= doc.getElementsByTagName("select");
	if (p.length > 0) {
		for (var i = 0; i < p[4].options.length; i++) {
			if (p[4].options[ i ].selected) {
				selectedPage = p[4].options[i].value;
				pageNum = p[4].options[i].innerHTML;
				newItem.pages = pageNum.replace(/^Page\s+/,"") + "-";
			}
		}
	}


	// get handle
	var handle="";
	var handleRe = /handle=([^\&]+)\&/
	var handleMatch = handleRe.exec(doc.location.href);
	if (handleMatch) {
		handle = handleMatch[1];
	}

	// get collection
	var collection="";
	var collectionRe = /collection=([^\&]+)\&/
	var collectionMatch = collectionRe.exec(doc.location.href);
	if (collectionMatch) {
		collection = collectionMatch[1];
	}	
	
	if (collection != "" & handle != "") {		
		newItem.url = "http://heinonline.org/HOL/Page?collection=" + collection +"&handle=" + handle +"&id=" + doc.getElementById(''pageSelect'').value;
	}
	
	// fetch citation
	var url = "http://heinonline.org/HOL/citation-info?handle="+handle+"&id="+selectedPage+"&rand=12345&collection=journals";
	Zotero.Utilities.HTTP.doGet(url, function(text) {
		
		var tmpTxt = text;
		var citeRe = /(\d+)\s+(.+)\s+(\d+)\s+\(([^\)]+)\)\s+<br>\s+([^;]+)(;\s.+[\S])/
		var citeMatch = citeRe.exec(tmpTxt)
		if (citeMatch) {
			
			newItem.volume = citeMatch[1];
			//newItem.issue= citeMatch[3];
			newItem.date = citeMatch[4];
			newItem.journalAbbreviation = citeMatch[2];
			newItem.title = citeMatch[5];
			
			var tmpAuthors = citeMatch[6];
			var authors = tmpAuthors.split(";");
			for (i=1;i<authors .length;i++) {
				
				var name = authors[i].split(",");
				var fname = name[1].replace(/^\s+/,"");
				var lname= name[0].replace(/^\s+/,"");
				newItem.creators.push({lastName:lname, firstName:fname, creatorType:"author", fieldMode:true});
			}
			newItem.abstract =  citeMatch[0];
		}	
	
		var getSectionUrl = "http://heinonline.org/HOL/ajaxcalls/get-section-id?base=js&handle="+handle+"&id="+selectedPage;
		Zotero.Utilities.HTTP.doGet(getSectionUrl, function(sectionRes) {
		
			var pdfUrl = "http://heinonline.org/HOL/PDF?handle="+handle+"&id="+selectedPage+"&print=section&section="+sectionRes+"&ext=.pdf";
			newItem.attachments.push({url:pdfUrl, title:"PDF version", mimeType:"application/pdf", downloadable:true});
			newItem.notes.push({note:"PDF version: "+pdfUrl});
			newItem.complete();
		});	
	});	
	
	
	// print page: PDF?handle=hein.journals/adelrev11&id=150&print=section&section=16&ext=.pdf"
}

function doWeb(doc, url) {
	var re=  /http:\/\/heinonline\.org\/HOL\/Page\?handle\=hein\.journals\/.+/
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