component extends="coldbox.system.testing.BaseTestCase" {

	function setup(){
		super.setup();

		// Mocks
		mockController = prepareMock( getController() );
		mockLogger     = prepareMock( mockController.getLogBox().getLogger( "ResourceService" ) ).$(
			"canDebug",
			false
		);
		mockInterceptorService = prepareMock( getController().getInterceptorService() );
		mockController.$( "settingExists", true ).$( "getAppRootPath", expandPath( "/root" ) );
		mocki18n        = createEmptyMock( "cbi18n.models.i18n" ).$( "getFwLocale", "en_US" );
		resourceService = createMock( "cbi18n.models.ResourceService" ).init();
		resourceService.$property( "log", "variables", mockLogger );
		resourceService.$property( "controller", "variables", mockController );
		resourceService.$property(
			"interceptorService",
			"variables",
			mockInterceptorService
		);
		resourceService.$property( "i18n", "variables", mocki18n );
		resourceService.$property(
			"settings",
			"variables",
			{
				defaultResourceBundle : "includes/i18n/main",
				resourceBundles       : { "support" : "includes/i18n/support" },
				defaultLocale         : "en_US",
				localeStorage         : "cookieStorage@cbstorages",
				unknownTranslation    : "**TEST**",
				logUnknownTranslation : true
			}
		);
		resourceService.$( "getFWLocale", "en_US" );
		resourceService.loadBundle( rbFile = expandPath( "/tests/resources/main" ), rbAlias = "default" );
	}

	function testLoadBundle(){
		resourceService.loadBundle( rbFile = expandPath( "/tests/resources/main" ), rbAlias = "testing" );
		var bundles = resourceService.getBundles();
		assertTrue( structKeyExists( bundles, "testing" ) );
	}

	function testgetResourceBundle(){
		bundle = resourceService.getResourceBundle(
			rbFile   = expandPath( "/tests/resources/main" ),
			rbLocale = "es_SV",
			rbAlias  = "default"
		);
		// debug( bundle );
		assertTrue( structCount( bundle ) );
		assertTrue( structKeyExists( bundle, "helloworld" ) );

		bundle = resourceService.getResourceBundle(
			rbFile  = expandPath( "/tests/resources/main" ),
			rbAlias = "default"
		);
		// debug( bundle );
		assertTrue( structCount( bundle ) );
		assertTrue( structKeyExists( bundle, "helloworld" ) );
	}

	function testInvalidgetResourceBundle(){
		expectedException();
		resourceService.getResourceBundle( rbFile = "/bogus/testing/main" );
	}

	function testResourceReplacements(){
		r = resourceService.getResource( resource = "testrep", values = [ "luis", "test" ] );
		debug( r );
		assertEquals( "Hello my name is luis and test", r );

		r = resourceService.getResource(
			resource = "testrepByKey",
			values   = { name : "luis majano", quote : "I am amazing!" }
		);
		debug( r );
		assertEquals( "Hello my name is luis majano and I am amazing!", r );
	}

	function testGetResource(){
		r = resourceService.getResource( resource = "testrep", values = [ "luis", "test" ] );
		assertEquals( "Hello my name is luis and test", r );

		r = resourceService.getResource( resource = "invalid" );
		assertEquals( "**TEST** key: invalid", r );

		r = resourceService.getResource( resource = "invalid", defaultValue = "invalid" );
		assertEquals( "invalid", r );
	}

	function testInvalidGetRBString(){
		expectedException();
		r = resourceService.getRBString( rbFile = expandPath( "/tests/resources/main" ), rbKey = "" );
	}

	function testGetRBString(){
		r = resourceService.getRBString( rbFile = expandPath( "/tests/resources/main" ), rbKey = "helloworld" );
		assertTrue( len( r ) );

		r = resourceService.getRBString(
			rbFile       = expandPath( "/tests/resources/main" ),
			rbKey        = "invaliddude",
			defaultValue = "Found"
		);
		assertEquals( "Found", r );
	}

	function testGetRBKeys(){
		a = resourceService.getRBKeys( rbFile = expandPath( "/tests/resources/main" ) );
		assertTrue( arrayLen( a ) );
	}

	function testVerifyPattern(){
		r = resourceService.verifyPattern( "At {1,time} on {1,date}, there was {2} on planet {0,number,integer}." );
		assertTrue( r );
	}

}
