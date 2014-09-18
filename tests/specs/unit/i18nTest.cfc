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
		mockRB =  getMockBox().createEmptyMock( "i18n.models.ResourceService" )
			.$("loadBundle");
		mockController = prepareMock( getController() );
		mockController
			.$("getSetting").$args("LocaleStorage").$results( "session" )
			.$("getSetting").$args("DefaultLocale").$results( "en_US" )
			.$("getSetting").$args("DefaultResourceBundle").$results( "" )
			.$("settingExists", true)
			.$("getSetting").$args("RBundles").$results( {} )
			.$("getSetting").$args( name="resourceBundles", defaultValue=structNew() ).$results( {} );

		i18n = createMock( "i18n.models.i18n" ).init();
		i18n.$property( "controller", "variables", mockController )
			.$property( "resourceService", "variables", mockRB );
		i18n.configure();
	}

	function testgetSetfwLocale(){
		assertEquals( "en_US", i18n.getFWLocale() );
		i18n.setFWLocale( "es_SV" );
		assertEquals( "es_SV", i18n.getFWLocale() );
	}

	function testisValidLocale(){
		assertTrue( i18n.isValidLocale( "en_US" ) );
		assertFalse( i18n.isValidLocale( "ee" ) );
	}

	function testLocaleMethods(){
		assertEquals( "en_US", i18n.getFWLocale() );
		assertEquals( "English (United States)", i18n.getFWLocaleDisplay() );
		assertEquals( "united states", i18n.getFWCountry() );
		assertEquals( "US", i18n.getFWCountryCode() );
		assertEquals( "USA", i18n.getFWISO3CountryCode() );
		assertEquals( "English", i18n.getFWLanguage() );
		assertEquals( "en", i18n.getFWLanguageCode() );
		assertEquals( "eng", i18n.getFWISO3LanguageCode() );
	}
</cfscript>
</cfcomponent>