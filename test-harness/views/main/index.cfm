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
	</cfoutput>