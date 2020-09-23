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
	<hr><h2>Missing IntroMessage in nl_NL will be replaced by default (en_US)</h2>
	<!--- This will show the default locale, because there is no nl or nl_NL resource --->
	#getResource( resource='intromessage', locale="nl_NL" )#
	<br>

</cfoutput> 