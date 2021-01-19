component extends="coldbox.system.testing.BaseTestCase" {

	function setup(){
		super.setup();

		// Mocks
		mockRB = createEmptyMock( "cbi18n.models.ResourceService" );

		mockRB.$( "loadBundle", mockRB );
		mockCookieStorage = getMockBox().createEmptyMock( "cbstorages.models.CookieStorage" );
		mockCookieStorage.$( "set", mockCookieStorage ).$( "get", "en_US" );
		mockController = prepareMock( getController() );

		// mock dynamic creation of cookiestorage
		mockWireBox = createMock( "coldbox.system.ioc.Injector" );
		mockWireBox.$( "getInstance", mockCookieStorage );

		i18n = createMock( "cbi18n.models.i18n" ).init();
		i18n.$property(
				"controller",
				"variables",
				mockController
			)
			.$property(
				"resourceService",
				"variables",
				mockRB
			)
			.$property(
				"storageService",
				"variables",
				mockCookieStorage
			)
			.$property( "cbstorageSettings", "variables", {} )
			.$property( "wirebox", "variables", mockWireBox );

		i18n.$property(
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
		i18n.onDiComplete();
	}

	function testgetSetfwLocale(){
		mockCookieStorage.$( "get" ).$results( "en_US", "es_SV" );
		assertEquals( "en_US", i18n.getFWLocale() );
		i18n.setFWLocale( "es_SV" );
		assertEquals( "es_SV", i18n.getFWLocale() );
	}

	function testisValidLocale(){
		assertTrue( i18n.isValidLocale( "en_US" ) );
		assertFalse( i18n.isValidLocale( "xy" ) );
	}

	function testLocaleMethods(){
		assertEquals( "en_US", i18n.getFWLocale() );
		assertEquals(
			"English (United States)",
			i18n.getFWLocaleDisplay()
		);
		assertEquals( "united states", i18n.getFWCountry() );
		assertEquals( "US", i18n.getFWCountryCode() );
		assertEquals( "USA", i18n.getFWISO3CountryCode() );
		assertEquals( "English", i18n.getFWLanguage() );
		assertEquals( "en", i18n.getFWLanguageCode() );
		assertEquals( "eng", i18n.getFWISO3LanguageCode() );
	}

}
