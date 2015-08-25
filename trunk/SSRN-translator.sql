REPLACE INTO translators VALUES ('ac4fe27d-6940-4cf3-b08d-073f80088f2c', '1.0.0b3r1', '', '2007-07-22 11:14:48', '0', '100', '4', 'SSRN', 'Bill McKinney', 'http://papers.ssrn.com/sol3/papers.cfm.+', 
'function detectWeb(doc, url) {
	var namespace = doc.documentElement.namespaceURI;
	var nsResolver = namespace ? function(prefix) {
		if (prefix == ''x'') return namespace; else return null;
	} : null;
	
	var re = /http:\/\/papers\.ssrn\.com\/sol3\/papers\.cfm.+/
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
	newItem.title = doc.title;
	
	var src = doc.body.innerHTML;

	// remove search highlight spans
	src = src.replace(/<\/?span[^>]*>/gi,"");
	
	// ABSTRACT ID
	var abstractId = "";
	var idRegex = /abstract_id=(\d+)/;
	var idMatch= idRegex .exec(doc.location.href);
	if (idMatch) {
		abstractId =  idMatch[1];
	}
	
	// ABSTRACT TEXT
	// Note: just the first paragraph is grabbed
	var abstractText = "Not Found";
	var abstractTextRegex = /Abstract:\s+<\/font><\/strong>[^<]+<br>\s+<font[^>]+>([^<]+)/i;
	var abstractTextMatch = abstractTextRegex.exec(src);
	if (abstractTextMatch) {
		abstractText = abstractTextMatch[1];
	}
	newItem.abstractNote = abstractText;
				
	// DOWNLOAD URL
	// Note: auto attachment of the pdf is disabled since SSRN uses "HTTP/1.x 302 Object Moved" and other tricks to prevent fraudulent downloads
	//var dnldRe = /alt\="Download from Social Science Research Network" href="([^"]+)"/i;
	//var dnldMatch = dnldRe.exec(src);
	
	// SUGGESTED CITATION
	// Note: this parsing is useful since many resources don''t have dates or volumes included in the citation export
	var suggestedCite = "";
	var suggestedCiteRegex= new RegExp(''<b>Suggested Citation<\/b>[^<]+<\/font><blockquote>[^<]+<font[^>]+>(.+)\s*\n(.+)\s*\n(.+)\s*Available'', ''gim'');
	var suggestedCiteMatch = suggestedCiteRegex.exec(src);
	if (suggestedCiteMatch ) {
		
		suggestedCite = "Suggested Citation: " + suggestedCiteMatch[1] + suggestedCiteMatch[2] + suggestedCiteMatch[3] ;
		suggestedCite  = suggestedCite.replace(/\s+/g," ");
		suggestedCite  = suggestedCite.replace(/\t+/g," ");
		suggestedCite = suggestedCite.replace(/\s$/,"");
		
		var volumeRegex = /, Vol\. (\d+)/i;
		var volumeMatch =  volumeRegex.exec(suggestedCite);
		if (volumeMatch) {
			newItem.volume = volumeMatch[1];
		}	
		var dateRegex = /, (\w+)\s+(\d\d\d\d)/;
		var dateMatch = dateRegex.exec(suggestedCite);
		if (dateMatch) {
			newItem.date = dateMatch[2] +" " +dateMatch[1];
		}
		var yearRegex= /,\s+(\d\d\d\d)/;
		var yearMatch= yearRegex.exec(suggestedCite);
		if (yearMatch) {
			newItem.date = yearMatch[1];
		}
		var numRegex = /,\s+No\.\s+(\d+)/i;
		var numMatch= numRegex .exec(suggestedCite);
		if (numMatch) {
			newItem.issue= numMatch[1];
		}
		var pageRegex= /,\s+p\.\s+(\d+)/i;
		var pageMatch = pageRegex.exec(suggestedCite);
		if (pageMatch ) {
			newItem.pages= pageMatch [1] + "-";
		}
		newItem.notes.push({note:suggestedCite});
	}
	
	// CITATION
	// Note: this request requires a logged in user
	// Note: format=1 returns EndNote format
	var citeUrl = "http://papers.ssrn.com/sol3/RefExport.cfm?function=info&abstract_id="+abstractId+"&format=1";
	Zotero.Utilities.HTTP.doGet(citeUrl , function(text) {
		var tmpTxt = text;
		
		var endNote = "";
		var citeRegex = /name="hdnContent" value="([^"]+)/i;
		var citeMatch = citeRegex.exec(tmpTxt);
		if (citeMatch) {
			
			var field = citeMatch[1].split("%");
			for (i=1;i<field.length;i++) {
				
				var re;
				var match;
				
				// PUBLICATION
				re= /^J\s+(.+)/;
				match= re.exec(field[i]);
				if (match) {
					var pub = match[1];
					newItem.publicationTitle= pub;
				}

				// SERIES TITLE
				re= /^0\s+(.+)/;
				match= re.exec(field[i]);
				if (match) {
					newItem.seriesTitle= match[1];
				}			
				// TITLE
				re= /^T\s+(.+)/;
				match= re.exec(field[i]);
				if (match) {
					newItem.title = match[1];
				}
				// DATE
				re= /^D\s+(.+)/;
				match= re.exec(field[i]);
				if (match) {
					newItem.date= match[1];
				}
				// LANGUAGE
				re= /^L\s+(.+)/;
				match= re.exec(field[i]);
				if (match) {
					newItem.language= match[1];
				}
				// DOI
				re= /^R\s+(.+)/;
				match= re.exec(field[i]);
				if (match) {
					newItem.DOI= match[1];
				}
				// URL
				re= /^U\s+(.+)/;
				match= re.exec(field[i]);
				if (match) {
					newItem.url= match[1];
				}
				// AUTHOR
				re= /^A\s+(.+)/;
				match= re.exec(field[i]);
				if (match) {
					var name = match[1].split(",");
					var fname = name[1].replace(/^\s+/,"");
					var lname= name[0].replace(/^\s+/,"");
					if (name.length == 3) {
						fname = fname + ", " + name[2];
					}
					newItem.creators.push({lastName:lname, firstName:fname, creatorType:"author", fieldMode:true});
				}
				
				// KEYWORDS
				re= /^K\s+(.+)/;
				match= re.exec(field[i]);
				if (match) {
					var words = match[1].split(",");
					for (j=0;j<words.length;j++) {
						newItem.tags.push({tag:words[j]});
					}
				}
				
			}// end field split
				
		}// end cite regex match
		
		newItem.complete();
	});	
}

function doWeb(doc, url) {
	var re = /http:\/\/papers\.ssrn\.com\/sol3\/papers\.cfm.+/
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