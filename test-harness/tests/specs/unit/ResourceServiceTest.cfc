<!-----------------------------------------------------------------------
********************************************************************************
Copyright 2005-2007 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
www.coldbox.org | www.luismajano.com | www.ortussolutions.com
********************************************************************************

Author 	    :	Luis Majano
----------------------------------------------------------------------->
<cfcomponent extends="coldbox.system.testing.BaseTestCase" appMapping="/root">
<cfscript>

	function setup(){
		super.setup();

		// Mocks
		mockController = prepareMock( getController() );
		mockLogger = prepareMock( mockController.getLogBox().getLogger( 'ResourceService' ) ).$("canDebug", false);
		mockController
			.$("getSetting").$args("RBundles").$results( structnew() )
			.$("getSetting").$args("DefaultLocale").$results( "en_US" )
			.$("getSetting").$args("DefaultResourceBundle").$results( "" )
			.$("getSetting").$args("UnknownTranslation").$results( "**TEST**" )
			.$("getSetting").$args("logUnknownTranslation").$results("true")
			.$("getSetting").$args("smartBundleSelection").$results("false")
			.$("settingExists", true)
			.$("getAppRootPath", expandPath("/root") );

		mocki18n = createEmptyMock( "cbi18n.models.i18n" ).$("getFwLocale", "en_US");
		resourceService = createMock( "cbi18n.models.ResourceService" ).init( mockController, mocki18n );
		resourceService.$property( "log", "variables", mockLogger );
		resourceService.$("getFWLocale", "en_US");
		resourceService.loadBundle( rbFile=expandPath("/tests/resources/main"), rbAlias="default" );
	}

	function testLoadBundle(){
		resourceService.loadBundle( rbFile = expandPath("/tests/resources/main"), rbAlias="testing" );
		var bundles = resourceService.getBundles();
		assertTrue( structkeyExists( bundles, "testing" ) );
	}

	function testgetResourceBundle(){
		bundle = resourceService.getResourceBundle( rbFile = expandPath("/tests/resources/main"), rbLocale="es_SV", rbAlias="default" );
		//debug( bundle );
		assertTrue( structCount( bundle ) );
		assertTrue( structKeyExists( bundle, "helloworld" ) );

		bundle = resourceService.getResourceBundle( rbFile = expandPath("/tests/resources/main"), rbAlias="default" );
		//debug( bundle );
		assertTrue( structCount( bundle ) );
		assertTrue( structKeyExists( bundle, "helloworld" ) );
	}

	function testInvalidgetResourceBundle(){
		expectedException();
		resourceService.getResourceBundle( rbFile = "/bogus/testing/main" );
	}

	function testResourceReplacements(){
		r = resourceService.getResource(resource="testrep", values=[ "luis", "test" ]);
		debug( r );
		assertEquals( "Hello my name is luis and test", r );

		r = resourceService.getResource(resource="testrepByKey", values={name="luis majano", quote="I am amazing!"});
		debug( r );
		assertEquals( "Hello my name is luis majano and I am amazing!", r );
	}

	function testGetResource(){
		r = resourceService.getResource(resource="testrep", values=[ "luis", "test" ]);
		assertEquals( "Hello my name is luis and test", r );

		r = resourceService.getResource( resource = "invalid" );
		assertEquals( "**TEST** key: invalid", r );

		r = resourceService.getResource( resource = "invalid", default="invalid" );
		assertEquals( "invalid", r );

	}

	function testInvalidGetRBString(){
		expectedException();
		r = resourceService.getRBString(rbFile=expandPath( "/tests/resources/main" ), rbKey="");
	}

	function testGetRBString(){
		r = resourceService.getRBString(rbFile=expandPath( "/tests/resources/main" ), rbKey="helloworld");
		assertTrue( len( r ) );

		r = resourceService.getRBString(rbFile=expandPath( "/tests/resources/main" ), rbKey="invaliddude", default="Found");
		assertEquals( "Found", r );
	}

	function testGetRBKeys(){
		a = resourceService.getRBKeys( rbFile=expandPath( "/tests/resources/main" ) );
		assertTrue( arrayLen( a ) );
	}

	function testVerifyPattern(){
		r = resourceService.verifyPattern( "At {1,time} on {1,date}, there was {2} on planet {0,number,integer}." );
		assertTrue( r );
	}
</cfscript>
</cfcomponent>