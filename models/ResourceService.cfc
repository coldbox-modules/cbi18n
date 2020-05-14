/**
 * Copyright Since 2005 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * Inspired by Paul Hastings
 * ---
 * This service reads and parses java resource bundles wit a nice integration for replacements
 */
component singleton accessors="true" {

	// DI
	property name="log"  inject="logbox:logger:{this}";
	property name="i18n" inject="i18n@cbi18n";

	/**
	 * properties
	 */
	property name="DefaultLocale";
	property name="DefaultResourceBundle";
	property name="UnknownTranslation";

	/**
	 * Constructor
	 *
	 * @controller The coldbox controller
	 * @controller.inject coldbox
	 * @i18n cbi18n module
	 * @i18n.inject i18n@cbi18n
	 */
	function init( required controller, required i18n ) {
		// store controller variable
		variables.controller = arguments.controller;
		variables.i18n       = arguments.i18n;

		// check if localization struct exists in memory, else create it.
		if ( !arguments.controller.settingExists( "RBundles" ) ) {
			arguments.controller.setSetting( "RBundles", {} );
		}
		// store bundles
		variables.aBundles              = arguments.controller.getSetting( "RBundles" );
		// setup local instance references
		variables.aBundles              = arguments.controller.getSetting( "RBundles" );
		variables.defaultLocale         = arguments.controller.getSetting( "DefaultLocale" );
		variables.defaultResourceBundle = arguments.controller.getSetting( "DefaultResourceBundle" );
		variables.unknownTranslation    = arguments.controller.getSetting( "UnknownTranslation" );
		variables.resourceBundles       = arguments.controller.getSetting( "ResourceBundles" );
		variables.logUnknownTranslation = arguments.controller.getSetting( "logUnknownTranslation" );

		return this;
	}

	/**
	 * Reference to loaded bundles
	 *
	 * @return struct of bundles
	 */
	struct function getBundles() {
		return variables.aBundles;
	}

	/**
	 * Get a list of all loaded bundles
	 *
	 * @return array of all keys of loaded bundles
	 */
	array function getLoadedBundles() {
		return structKeyArray( variables.aBundles );
	}

	/**
	 * Tries to load a resource bundle into ColdBox memory if not loaded already
	 *
	 * @rbFile This must be the path + filename UP to but NOT including the locale. We auto-add .properties to the end alongside the locale
	 * @rbLocale The locale of the bundle to load
	 * @force Forces the loading of the bundle even if its in memory
	 * @rbAlias The unique alias name used to store this resource bundle in memory. The default name is the name of the rbFile passed if not passed.
	 */
	any function loadBundle(
		required string rBFile,
		string rbLocale = "en_US",
		boolean force   = false,
		string rbAlias  = "default"
	) {
		// Setup rbAlias if not passed
		if ( !structKeyExists( arguments, "rbAlias" ) || !len( arguments.rbAlias ) ) {
			arguments.rbFile  = replace( arguments.rbFile, "\", "/", "all" );
			arguments.rbAlias = listLast( arguments.rbFile, "/" );
		}

		// Verify bundle register name exists
		if ( !structKeyExists( variables.aBundles, arguments.rbAlias ) ) {
			lock
				name          ="rbregister.#hash( arguments.rbFile & arguments.rbAlias )#"
				type          ="exclusive"
				timeout       ="10"
				throwontimeout="true" {
				if ( !structKeyExists( variables.aBundles, arguments.rbAlias ) ) {
					variables.aBundles[ arguments.rbAlias ] = {};
				}
			}
		}

		// Verify bundle register locale exists or forced
		if ( !structKeyExists( variables.aBundles[ arguments.rbAlias ], arguments.rbLocale ) || arguments.force ) {
			lock
				name          ="rbload.#hash( arguments.rbFile & arguments.rbLocale )#"
				type          ="exclusive"
				timeout       ="10"
				throwontimeout="true" {
				if ( !structKeyExists( variables.aBundles[ arguments.rbAlias ], arguments.rbLocale ) || arguments.force ) {
					// load a bundle and store it.
					variables.aBundles[ arguments.rbAlias ][ arguments.rbLocale ] = getResourceBundle(
						rbFile   = arguments.rbFile,
						rbLocale = arguments.rbLocale
					);
					// logging
					if ( log.canDebug() ) {
						log.debug(
							"Loaded bundle: #arguments.rbFile#:#arguments.rbAlias# for locale: #arguments.rbLocale#, forced: #arguments.force#"
						);
					}
				}
			}
		}
		return this;
	}

	/**
	 * Get a resource from a specific loaded bundle and locale
	 *
	 * @resource The resource (key) to retrieve from the main loaded bundle.
	 * @default A default value to send back if the resource (key) not found
	 * @locale Pass in which locale to take the resource from. By default it uses the user's current set locale
	 * @values An array, struct or simple string of value replacements to use on the resource string
	 * @bundle The bundle alias to use to get the resource from when using multiple resource bundles. By default the bundle name used is 'default'
	 */
	function getResource(
		required resource,
		//default, 
		locale = variables.i18n.getfwLocale(), 
		values, 
		bundle = "default"
	) {
		var thisBundle = {};
		var thisLocale = arguments.locale;
		var rbFile     = "";

		// check for resource@bundle convention:
		if ( find( "@", arguments.resource ) ) {
			arguments.bundle   = listLast( arguments.resource, "@" );
			arguments.resource = listFirst( arguments.resource, "@" );
		}

		try {
			// Check if the locale has a language bundle loaded in memory
			if (
				!structKeyExists( variables.aBundles, arguments.bundle ) ||
				(
					structKeyExists( variables.aBundles, arguments.bundle ) && !structKeyExists(
						variables.aBundles[ arguments.bundle ],
						arguments.locale
					)
				)
			) {
				// Try to load the language bundle either by default or config search
				if ( arguments.bundle eq "default" ) {
					rbFile = variables.defaultResourceBundle;
				} else if ( structKeyExists( variables.resourceBundles, arguments.bundle ) ) {
					rbFile = variables.resourceBundles[ arguments.bundle ];
				}
				loadBundle(
					rbFile   = rbFile,
					rbLocale = arguments.locale,
					rbAlias  = arguments.bundle
				);
			}

			// Get the language reference now
			thisBundle = variables.aBundles[ arguments.bundle ][ arguments.locale ];
		} catch ( Any e ) {
			throw(
				message = "Error getting language (#arguments.locale#) bundle for resource (#arguments.resource#). Exception Message #e.message#",
				detail  = e.detail & e.tagContext.toString(),
				type    = "ResourceBundle.BundleLoadingException"
			);
		}

		// Check if resource does NOT exists?
		if ( !structKeyExists( thisBundle, arguments.resource ) ) {
			// if logging enable
			if ( variables.logUnknownTranslation ) {
				log.error( variables.unknownTranslation & " key: #arguments.resource#" );
			}

			// Check default and return if sent
			if ( structKeyExists( arguments, "default" ) ) {
				return arguments.default;
			}

			// Check unknown translation setting
			if ( len( variables.unknownTranslation ) ) {
				return variables.unknownTranslation & " key: #arguments.resource#";
			}

			// Else return nasty unknown string.
			return "_UNKNOWNTRANSLATION_FOR_#arguments.resource#_";
		}

		// Return Resource with value replacements
		if ( structKeyExists( arguments, "values" ) ) {
			return formatRBString( thisBundle[ arguments.resource ], arguments.values );
		}

		// return from bundle
		return thisBundle[ arguments.resource ];
	}
	/************************************************************************************/
	/****************************** UTILITY METHODS *************************************/
	/************************************************************************************/

	/**
	 * Reads,parses and returns a resource bundle in struct format
	 *
	 * @rbFile This must be the path + filename UP to but NOT including the locale. We auto-add the local and .properties to the end.
	 * @rbLocale The locale of the resource bundle
	 */
	struct function getResourceBundle( required rbFile, rbLocale = "en_US" ) {
		var resourceBundle = {};
		var thisKEY        = "";
		var rbFilePath     = arguments.rbFile & iIf(
			len( arguments.rbLocale ),
			de( "_" ),
			de( "" )
		) & arguments.rbLocale & ".properties";
		var rbFullPath = rbFilePath;

		// Try to locate the path using the coldbox plugin utility
		rbFullPath = variables.controller.locateFilePath( rbFilePath );

		// Validate Location
		if ( !len( rbFullPath ) ) {
			throw(
				"The resource bundle file: #rbFilePath# does not exist. Please check your path",
				"FullPath: #rbFullPath#",
				"ResourceBundle.InvalidBundlePath"
			);
		}

		// create a file input stream with file location
		var fis = createObject( "java", "java.io.FileInputStream" ).init( rbFullPath );
		var fir = createObject( "java", "java.io.InputStreamReader" ).init( fis, "UTF-8" );
		// Init RB with file Stream
		var rb  = createObject( "java", "java.util.PropertyResourceBundle" ).init( fir );
		try {
			// Get Keys
			var keys = rb.getKeys();

			// Loop through property keys and store the values into bundle
			while ( keys.hasMoreElements() ) {
				thisKEY                   = keys.nextElement();
				resourceBundle[ thisKEY ] = rb.handleGetObject( thisKEY );
			}
		} catch ( Any e ) {
			fis.close();
			$rethrow( e );
		}

		// Close the input stream
		fis.close();

		return resourceBundle;
	}

	/**
	 * Returns a given key from a specific resource bundle file and locale. NOT FROM MEMORY
	 *
	 * @rbFile This must be the path + filename UP to but NOT including the locale. We auto-add the local and .properties to the end.
	 * @rbKey The key to retrieve
	 * @rbLocale The locale of the bundle. Default is en_US
	 * @default A default value to send back if resource not found
	 *
	 * @throws ResourceBundle.InvalidBundlePath if bundlePath is not found
	 * @throws ResourceBundle.RBKeyNotFoundException if rbKey is not found
	 */
	any function getRBString(
		required rbFile,
		required rbKey,
		rbLocale = "en_US"
		//,default
	) {
		// default locale?
		if ( !len( arguments.rbLocale ) ) {
			arguments.rbLocale = variables.defaultLocale;
		}

		// prepare the file
		var rbFilePath = arguments.rbFile & "_#arguments.rbLocale#.properties";

		// Try to locate the path using the coldbox plugin utility
		var rbFullPath = variables.controller.locateFilePath( rbFilePath );

		// Validate Location
		if ( !len( rbFullPath ) ) {
			throw(
				"The resource bundle file: #rbFilePath# does not exist. Please check your path",
				"FullPath: #rbFullPath#",
				"ResourceBundle.InvalidBundlePath"
			);
		}

		// read file
		var fis = createObject( "java", "java.io.FileInputStream" ).init( rbFullPath );
		var rb  = createObject( "java", "java.util.PropertyResourceBundle" ).init( fis );

		try {
			// Retrieve string
			var rbString = rb.handleGetObject( arguments.rbKey );
		} catch ( Any e ) {
			fis.close();
			$rethrow( e );
		}

		// Close file
		fis.close();

		// Check if found?
		if ( isDefined( "rbString" ) ) {
			return rbString;
		}
		// Check default?
		if ( structKeyExists( arguments, "default" ) ) {
			return arguments.default;
		}

		// Nothing to return, throw it
		throw(
			"Fatal error: resource bundle #arguments.rbFile# does not contain key #arguments.rbKey#",
			"",
			"ResourceBundle.RBKeyNotFoundException"
		);
	}

	/**
	 * Returns an array of keys from a specific resource bundle
	 *
	 * @rbFile This must be the path + filename UP to but NOT including the locale. We auto-add the local and .properties to the end.
	 * @rbLocale The locale to use, if not passed, defaults to default locale.
	 *
	 * @returns array of keys from a specific resource bundle
	 * @throws ResourceBundle.InvalidBundlePath if bundlePath is not found
	 */
	array function getRBKeys( required rbFile, rbLocale= "" ) {
		var keys = arrayNew( 1 );

		// default locale?
		if ( NOT len( arguments.rbLocale ) ) {
			arguments.rbLocale = variables.defaultLocale;
		}

		// prepare the file
		var rbFilePath = arguments.rbFile & "_#arguments.rbLocale#.properties";

		// Try to locate the path using the coldbox plugin utility
		var rbFullPath = variables.controller.locateFilePath( rbFilePath );

		// Validate Location
		if ( !len( rbFullPath ) ) {
			throw(
				"The resource bundle file: #rbFilePath# does not exist. Please check your path",
				"FullPath: #rbFullPath#",
				"ResourceBundle.InvalidBundlePath"
			);
		}

		// read file
		var fis = createObject( "java", "java.io.FileInputStream" ).init( rbFullPath );
		var rb  = createObject( "java", "java.util.PropertyResourceBundle" ).init( fis );

		try {
			// Get Keys
			var rbKeys = rb.getKeys();
			// Loop through Keys and get the elements.
			while ( rbKeys.hasMoreElements() ) {
				arrayAppend( keys, rbKeys.nextElement() );
			}
		} catch ( Any e ) {
			fis.close();
			$rethrow( e );
		}

		// Close it up
		fis.close();

		return keys;
	}

	/**
	 * performs messageFormat like operation on compound rb string. So if you have a string with {1} it will replace it. You can also have multiple and send in an array to do replacements.
	 *
	 * @rbString resourceString
	 * @substituteValues Array, Struct or single value to format.
	 *
	 * @returns formatted string
	 */
	string function formatRBString( required rbString, required substituteValues ) {
		var tmpStr = arguments.rbString;

		// Array substitutions by position
		if ( isArray( arguments.substituteValues ) ) {
			var valLen = arrayLen( arguments.substituteValues );

			for ( var x = 1; x lte valLen; x = x + 1 ) {
				tmpStr = tmpStr.replace(
					"{#x#}",
					arguments.substituteValues[ x ],
					"ALL"
				);
			}

			return tmpStr;
		}
		// Struct substitutions by key
		else if ( isStruct( arguments.substituteValues ) ) {
			for ( var thisKey in arguments.substituteValues ) {
				tmpStr = tmpStr.replaceNoCase(
					"{#lCase( thisKey )#}",
					arguments.substituteValues[ lCase( thisKey ) ],
					"ALL"
				);
			}
			return tmpStr;
		}

		// Single simple substitution
		return arguments.rbString.replace(
			"{1}",
			arguments.substituteValues,
			"ALL"
		);
	}

	/**
	 * performs messageFormat on compound rb string
	 *
	 * @thisPattern pattern to use in formatting
	 * @args substitution values, simple or array
	 * @thisLocale locale to use in formatting, defaults to en_US
	 *
	 * @returns a formatted string
	 */
	string function messageFormat(
		required string thisPattern,
		required args,
		thisLocale = ""
	) {
		var pattern   = createObject( "java", "java.util.regex.Pattern" );
		var regexStr  = "(\{[0-9]{1,},number.*?\})";
		var inputArgs = arguments.args;

		// locale?
		if ( !arguments.thisLocale.len() ) {
			arguments.thisLocale = variables.defaultLocale;
		}

		// Create correct java locale
		var lang    = arguments.thisLocale.listFirst( "_" );
		varcountry  = arguments.thisLocale.listGetAt( 2, "_" );
		var variant = arguments.thisLocale.listLast( "_" );
		var tLocale = createObject( "java", "java.util.Locale" ).init( lang, country, variant );

		// Check if input arguments not an array, then inflate to an array.
		if ( NOT isArray( inputArgs ) ) {
			inputArgs = listToArray( inputArgs );
		}

		// Create the message format
		var thisFormat = createObject( "java", "java.text.MessageFormat" ).init( arguments.thisPattern, tLocale );

		// let's make sure any cf numerics are cast to java datatypes
		var p = pattern.compile( regexStr, pattern.CASE_INSENSITIVE );
		var m = p.matcher( arguments.thisPattern );
		while ( m.find() ) {
			var i          = listFirst( replace( m.group(), "{", "" ) );
			inputArgs[ i ] = javacast( "float", inputArgs[ i ] );
		}

		inputArgs.prepend( "" );
		return thisFormat.format( inputArgs.toArray() );
	}

	/**
	 * Performs verification on MessageFormat pattern
	 *
	 * @pattern format pattern to test
	 *
	 * @returns boolean
	 */
	boolean function verifyPattern( required string pattern ) {
		try {
			var test = createObject( "java", "java.text.MessageFormat" ).init( arguments.pattern );
		} catch ( Any e ) {
			return false;
		}
		return true;
	}

}
