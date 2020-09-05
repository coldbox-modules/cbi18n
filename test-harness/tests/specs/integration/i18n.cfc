/*******************************************************************************
*	Integration Test as BDD (CF10+ or Railo 4.1 Plus)
*
*	Extends the integration class: coldbox.system.testing.BaseTestCase
*
*	so you can test your ColdBox application headlessly. The 'appMapping' points by default to
*	the '/root' mapping created in the test folder Application.cfc.  Please note that this
*	Application.cfc must mimic the real one in your root, including ORM settings if needed.
*
*	The 'execute()' method is used to execute a ColdBox event, with the following arguments
*	* event : the name of the event
*	* private : if the event is private or not
*	* prePostExempt : if the event needs to be exempt of pre post interceptors
*	* eventArguments : The struct of args to pass to the event
*	* renderResults : Render back the results of the event
*******************************************************************************/
component extends="coldbox.system.testing.BaseTestCase" appMapping="/root"{

	/*********************************** LIFE CYCLE Methods ***********************************/

	function beforeAll(){
		super.beforeAll();
		// do your own stuff here
	}

	function afterAll(){
		// do your own stuff here
		super.afterAll();
	}

/*********************************** BDD SUITES ***********************************/

	function run(){

		describe( "i18n module", function(){

			beforeEach(function( currentSpec ){
				// Setup as a new ColdBox request, VERY IMPORTANT. ELSE EVERYTHING LOOKS LIKE THE SAME REQUEST.
				setup();
			});

			it( "can load resources with different options", function(){
				var event 	= execute( event="main.index", renderResults=true );
				var results = event.getValue( "cbox_rendered_content" );
				// Verify all cases on the content
				expect(	results )
					.toInclude( "Home" )
					.toInclude( "BogusNotFound" )
					.toInclude( "Casa")
					.toInclude( "Help Me from Support" )					
					.toInclude( "Thuis" )
					.toInclude( "This is my introduction message." );
			});

			it( "can load resource in the parent", function(){
				//var event = execute( event="test1:test.i18n", renderResults=true );
				//expect(	event.getValue( "cbox_rendered_content" ) ).toInclude( "Welcome to my awesome multi-lingual module" );
				var event = execute( event="main.testi18n", renderResults=true );
				expect(	event.getValue( "cbox_rendered_content" ) ).toInclude( "Hello World" );
			});

			it( "can load resource in the parent from another bundle", function(){
				var event = execute( event="main.testi18nExtraBundle", renderResults=true );
				expect(	event.getValue( "cbox_rendered_content" ) ).toInclude( "Home" );
			});

			it( "can load from modules", function(){
				var event = execute( route="test1/test/i18n", renderResults=true );
				expect(	event.getValue( "cbox_rendered_content" ) ).toInclude( "Welcome to my awesome multi-lingual module" );
			});

			it( "can load resource in the parent from a language bundle without country", function(){
				var event = execute( event="main.testi18nPartialBundle", renderResults=true );
				expect(	event.getValue( "cbox_rendered_content" ) ).toInclude( "Hallo Wereld" );
			});

			it( "can load resource in the parent from a default resource when missing in actual bundle", function(){
				var event = execute( event="main.testi18nMissingResourceInBundle", renderResults=true );
				expect(	event.getValue( "cbox_rendered_content" ) ).toInclude( "Welcome to ColdBox" );
			});

//			it( "can implement a custom resource service", function(){
//				var event = execute( event="main.testi18nCustomResourceService", renderResults=true );
//				expect(	event.getValue( "cbox_rendered_content" ) ).toInclude( "Welcome to my awesome multi-lingual app using a custom Resource Service" );
//			});

		});

	}

}