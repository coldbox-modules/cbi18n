<!-----------------------------------------------------------------------
********************************************************************************
Copyright 2005-2007 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
www.coldbox.org | www.luismajano.com | www.ortussolutions.com
********************************************************************************

Author 	    :	Luis Majano
----------------------------------------------------------------------->
<cfcomponent extends="coldbox.system.testing.BaseModelTest" model="i18n.model.ResourceService">
<cfscript>

	function setup(){
		super.setup();

		// Mocks
		mockLogger.$("canDebug", false);
		mockController
			.$("getSetting").$args("RBundles").$results( structnew() )
			.$("getSetting").$args("DefaultLocale").$results( "en_US" )
			.$("getSetting").$args("DefaultResourceBundle").$results( "" )
			.$("getSetting").$args("UnknownTranslation").$results( "**TEST**" )
			.$("settingExists", true)
			.$("getAppRootPath", expandPath("/root") );

		model.init( mockController );
		model.$("getFWLocale", "en_US");
		model.loadBundle( rbFile=expandPath("/coldbox/testing/resources/main"), rbAlias="default" );
	}

	function testLoadBundle(){
		model.loadBundle( rbFile = expandPath("/coldbox/testing/resources/main"), rbAlias="testing" );
		var bundles = model.getBundles();
		assertTrue( structkeyExists( bundles, "testing" ) );
	}

	function testgetResourceBundle(){
		bundle = model.getResourceBundle( rbFile = expandPath("/coldbox/testing/resources/main"), rbLocale="es_SV", rbAlias="default" );
		//debug( bundle );
		assertTrue( structCount( bundle ) );
		assertTrue( structKeyExists( bundle, "helloworld" ) );

		bundle = model.getResourceBundle( rbFile = expandPath("/coldbox/testing/resources/main"), rbAlias="default" );
		//debug( bundle );
		assertTrue( structCount( bundle ) );
		assertTrue( structKeyExists( bundle, "helloworld" ) );
	}

	function testInvalidgetResourceBundle(){
		expectException( "ResourceBundle.InvalidBundlePath" );
		model.getResourceBundle( rbFile = "/coldbox/testing/main" );
	}

	function testResourceReplacements(){
		r = model.getResource(resource="testrep", values=[ "luis", "test" ]);
		debug( r );
		assertEquals( "Hello my name is luis and test", r );

		r = model.getResource(resource="testrepByKey", values={name="luis majano", quote="I am amazing!"});
		debug( r );
		assertEquals( "Hello my name is luis majano and I am amazing!", r );
	}

	function testGetResource(){
		r = model.getResource(resource="testrep", values=[ "luis", "test" ]);
		assertEquals( "Hello my name is luis and test", r );

		r = model.getResource( resource = "invalid" );
		assertEquals( "**TEST** key: invalid", r );

		r = model.getResource( resource = "invalid", default="invalid" );
		assertEquals( "invalid", r );

	}

	function testInvalidGetRBString(){
		expectException( "ResourceBundle.FileNotFoundException" );
		r = model.getRBString(rbFile=expandPath( "/coldbox/testing/resources" ), rbKey="");
	}

	function testGetRBString(){
		r = model.getRBString(rbFile=expandPath( "/coldbox/testing/resources/main" ), rbKey="helloworld");
		assertTrue( len( r ) );

		r = model.getRBString(rbFile=expandPath( "/coldbox/testing/resources/main" ), rbKey="invaliddude", default="Found");
		assertEquals( "Found", r );
	}

	function testGetRBKeys(){
		a = model.getRBKeys( rbFile=expandPath( "/coldbox/testing/resources/main" ) );
		assertTrue( arrayLen( a ) );
	}

	function testGetVersion(){
		a = model.getVersion();
		assertEquals( a.pluginVersion, model.getPluginVersion() );
	}

	function testVerifyPattern(){
		r = model.verifyPattern( "At {1,time} on {1,date}, there was {2} on planet {0,number,integer}." );
		assertTrue( r );
	}
</cfscript>
</cfcomponent>