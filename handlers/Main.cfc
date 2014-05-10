/**
* My Event Handler Hint
*/
component{

	// Index
	any function index( event,rc, prc ){
	}

	// Run on first init
	any function onAppInit( event, rc, prc ){
	}

	any function testi18n( event, rc, prc ){
		return getResource( "helloworld" );
	}

	any function testi18nExtraBundle( event, rc, prc ){
		return getResource( "home@support" );
	}

}