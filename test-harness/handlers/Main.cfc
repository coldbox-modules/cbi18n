/**
 * My Event Handler Hint
 */
component {

	// Index
	any function index( event, rc, prc ){
		event.setView( "main/index" );
	}

	/**
	 * locale
	 */
	function locale( event, rc, prc ){
		setFWLocale( "es_SV" );
		event.setView( "main/index" );
	}

	// Run on first init
	any function onAppInit( event, rc, prc ){
	}

	any function testi18n( event, rc, prc ){
		return getResource( "helloworld" );
	}

	any function testi18nPartialBundle( event, rc, prc ){
		return getResource( resource = "helloworld", locale = "nl_NL" );
	}

	any function testi18nExtraBundle( event, rc, prc ){
		return getResource( "home@support" );
	}

	any function testi18nCustomResourceService( event, rc, prc ){
		return getResource( "welcome@crs" );
	}
	any function testi18nJsonResourceService( event, rc, prc ){
		return getInstance( "JsonResourceService" ).getResource(
			resource = "sub.intromessage",
			bundle   = "jsonTest"
		);
	}
	any function testi18nNestedJsonResourceService( event, rc, prc ){
		return getInstance( "JsonResourceService" ).getResource(
			resource = "sub.intromessage",
			bundle   = "nestedJsonTest"
		);
	}

}
