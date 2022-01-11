/**
 * ********************************************************************************
 * Copyright Since 2005 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * *******************************************************************************
 */
component {

	// Module Properties
	this.title             = "cbi18n";
	this.author            = "Luis Majano";
	this.webURL            = "https://www.ortussolutions.com";
	this.description       = "Gives i18n and localization capabilities to applications";
	this.version           = "@build.version@+@build.number@";
	// Model Namespace
	this.modelNamespace    = "cbi18n";
	// CF Mapping
	this.cfmapping         = "cbi18n";
	// Helpers
	this.applicationHelper = [ "helpers/Mixins.cfm" ];
	// Dependencies
	this.dependencies      = [ "cbstorages" ];

	/**
	 * Configure Module
	 */
	function configure(){
		settings = {
			// The default resource to load and aliased as `default`
			"defaultResourceBundle" : "",
			// The locale to use when none defined
			"defaultLocale"         : "en_US",
			// The default storage for the locale
			"localeStorage"         : "cookieStorage@cbstorages",
			// What to emit to via the resource methods if a translation is not found
			"unknownTranslation"    : "",
			// If true, we will log to LogBox the missing translations
			"logUnknownTranslation" : false,
			// Boolean marker indicating if the module has loaded resources and the i18n model needs to load, mostly used internally
			"using_i18N"            : false,
			// A-la-carte resources to load by name
			"resourceBundles"       : {},
			// You can override the ResourceService with your own, just add the WireBox ID
			"customResourceService" : ""
		};

		// Emitted Events
		interceptorSettings = { customInterceptionPoints : "onUnknownTranslation" };
	}

	/**
	 * Fired when the module is registered and activated.
	 */
	function onLoad(){
		// Remap Resource Service if settings allow it
		if ( variables.settings.customResourceService.len() ) {
			binder
				.map( alias: "resourceService@cbi18n", force: true )
				.to( variables.settings.customResourceService );
		}
	}

	/**
	 * Fired when the module is unregistered and unloaded
	 */
	function onUnload(){
	}

	/**
	 * Listen when modules are activated to load their i18n capabilities
	 */
	function afterAspectsLoad( event, interceptData ){
		var modules           = controller.getSetting( "modules" );
		var moduleService     = controller.getModuleService();
		var moduleConfigCache = moduleService.getModuleConfigCache();

		modules.each( function( thisModule ){
			// get module config object
			var oConfig        = moduleConfigCache[ arguments.thisModule ];
			// Get module settings and see if it uses cbi18n
			var moduleSettings = oConfig.getPropertyMixin( "cbi18n", "variables", {} );
			if ( structCount( moduleSettings ) ) {
				var flagi18n = false;
				// set defaults
				modules[ arguments.thisModule ].cbi18n = {
					defaultResourceBundle : "",
					defaultLocale         : "",
					localeStorage         : "cookieStorage@cbstorages",
					unknownTranslation    : "",
					logUnknownTranslation : false,
					resourceBundles       : {},
					customResourceService : ""
				};
				// append incoming settings
				structAppend(
					modules[ arguments.thisModule ].cbi18n,
					moduleSettings,
					true
				);
				// process settings, only set if not there yet.
				var keys = "defaultResourceBundle,unknownTranslation,defaultLocale,localeStorage";
				keys.listEach( function( element, index, list ){
					if ( modules[ thisModule ][ "cbi18n" ][ element ].len() && !settings[ element ].len() ) {
						settings[ element ] = modules[ thisModule ][ "cbi18n" ][ element ];
						flagi18n            = true;
					}
				} );

				if ( structCount( modules[ arguments.thisModule ].cbi18n.resourceBundles ) ) {
					settings.resourceBundles.append( modules[ arguments.thisModule ].cbi18n.resourceBundles, true );
					flagi18n = true;
				}
				if ( flagi18n ) {
					settings.using_i18N = true;
				}
			};
		} );

		// startup the i18n engine if using it, else ignore.
		if ( settings.using_i18N ) {
			wirebox.getInstance( "i18n@cbi18n" );
		};
	};

}
