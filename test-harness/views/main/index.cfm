<cfoutput>
	<h1>i18n</h1>

	<hr><h2>homebutton</h2>
	#getResource( resource='homebutton' )#
	<br>

	<hr><h2>bogus</h2>
	#getResource( resource="bogus", defaultValue="BogusNotFound" )#
	<br>

	<hr><h2>homebutton</h2>
	#getResource( resource='homebutton', locale="es_SV" )#
	<br>

	<hr><h2>helptext</h2>
	#getResource( resource="helptext", bundle="support" )#
	<br>
	<hr><h2>homebutton</h2>
	<!--- This will show the nl locale, NOT the (non existing) nl_NL --->
	#getResource( resource='homebutton', locale="nl_NL" )#
	<br>
	<!--- This will show a JSON resoure --->
	<hr><h2>JSON resource (flat)</h2>
	#getInstance('JsonResourceService').getResource( resource="sub.intromessage", bundle="jsonTest" )#
	<br>
	<!--- This will show a nestedJSON resoure --->
	<hr><h2>JSON resource (nested)</h2></h2>
	#getInstance('JsonResourceService').getResource( resource="sub.intromessage", bundle="nestedJsonTest" )#
	<br>

</cfoutput> 