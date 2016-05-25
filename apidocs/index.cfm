<cfparam name="url.version" default="0">
<cfparam name="url.path" 	default="#expandPath( "./cbi18n-APIDocs" )#">
<cfscript>
	docName = "cbi18n-APIDocs";
	base 	= expandPath( "/cbi18n" );
	docbox 	= new docbox.DocBox( properties = {
		projectTitle 	= "cbi18n v#url.version#",
		outputDir 		= url.path
	} );
	docbox.generate( source=base, mapping="cbi18n" );
</cfscript>

<!---
<cfzip action="zip" file="#expandPath('.')#/#docname#.zip" source="#expandPath( docName )#" overwrite="true" recurse="yes">
<cffile action="move" source="#expandPath('.')#/#docname#.zip" destination="#url.path#">
--->

<cfoutput>
<h1>Done!</h1>
<a href="#docName#/index.html">Go to Docs!</a>
</cfoutput>

