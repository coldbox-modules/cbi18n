/**
 * Copyright Since 2005 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * Inspired by Paul Hastings
 * ---
 * This service allows you to work with java/json resource bundles for localization of strings.
 * It also has several convenience methods when working with replacements of localized strings.
 */
component singleton accessors="true" {

	// DI
	property name="log"                inject="logbox:logger:{this}";
	property name="controller"         inject="coldbox";
	property name="i18n"               inject="provider:i18n@cbi18n";
	property name="settings"           inject="coldbox:moduleSettings:cbi18n";
	property name="interceptorService" inject="coldbox:interceptorService";

	/**
	 * The bundles loaded into the resource service identifiable by key name
	 */
	property name="bundles" type="struct";

	/**
	 * Constructor
	 */
	function init(){
		variables.bundles = {};
		return this;
	}

	/**
	 * Get a list of all loaded bundles
	 *
	 * @return array of all keys of loaded bundles
	 */
	array function getLoadedBundles(){
		return structKeyArray( variables.bundles );
	}

	/**
	 * Tries to load a resource bundle into ColdBox memory if not loaded already
	 *
	 * @rbFile   This must be the path + filename UP to but NOT including the locale. We auto-add .properties or .json to the end alongside the locale
	 * @rbLocale The locale of the bundle to load
	 * @force    Forces the loading of the bundle even if its in memory
	 * @rbAlias  The unique alias name used to store this resource bundle in memory. The default name is the name of the rbFile passed if not passed.
	 */
	ResourceService function loadBundle(
		required string rBFile,
		string rbLocale = "en_US",
		boolean force   = false,
		string rbAlias  = "default"
	){
		// Normalize paths
		arguments.rbFile = replace( arguments.rbFile, "\", "/", "all" );

		// Setup rbAlias if not passed
		if ( !len( arguments.rbAlias ) ) {
			arguments.rbAlias = listLast( arguments.rbFile, "/" );
		}

		// Have we registered the bundle alias before?
		if ( !structKeyExists( variables.bundles, arguments.rbAlias ) ) {
			lock
				name          ="rbregister.#hash( arguments.rbFile & arguments.rbAlias )#"
				type          ="exclusive"
				timeout       ="10"
				throwontimeout="true" {
				if ( !structKeyExists( variables.bundles, arguments.rbAlias ) ) {
					variables.bundles[ arguments.rbAlias ] = {};
				}
			}
		}

		// Verify bundle register locale exists or forced
		if ( !structKeyExists( variables.bundles[ arguments.rbAlias ], arguments.rbLocale ) || arguments.force ) {
			lock
				name          ="rbload.#hash( arguments.rbFile & arguments.rbLocale )#"
				type          ="exclusive"
				timeout       ="10"
				throwontimeout="true" {
				if (
					!structKeyExists( variables.bundles[ arguments.rbAlias ], arguments.rbLocale ) || arguments.force
				) {
					// load a bundle and store it.
					variables.bundles[ arguments.rbAlias ][ arguments.rbLocale ] = getResourceBundle(
						rbFile   = arguments.rbFile,
						rbLocale = arguments.rbLocale
					);
					// logging
					if ( variables.log.canInfo() ) {
						variables.log.info(
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
	 * @resource     The resource (key) to retrieve from the main loaded bundle.
	 * @defaultValue A default value to send back if the resource (key) not found
	 * @locale       Pass in which locale to take the resource from. By default it uses the user's current set locale
	 * @values       An array, struct or simple string of value replacements to use on the resource string
	 * @bundle       The bundle alias to use to get the resource from when using multiple resource bundles. By default the bundle name used is 'default'
	 */
	function getResource(
		required resource,
		defaultValue,
		locale = variables.i18n.getfwLocale(),
		values,
		bundle = "default"
	){
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
				!structKeyExists( variables.bundles, arguments.bundle ) ||
				(
					structKeyExists( variables.bundles, arguments.bundle ) && !structKeyExists(
						variables.bundles[ arguments.bundle ],
						arguments.locale
					)
				)
			) {
				// Try to load the language bundle either by default or config search
				if ( arguments.bundle eq "default" ) {
					rbFile = variables.settings.defaultResourceBundle;
				} else if ( structKeyExists( variables.settings.resourceBundles, arguments.bundle ) ) {
					rbFile = variables.settings.resourceBundles[ arguments.bundle ];
				}
				loadBundle(
					rbFile   = rbFile,
					rbLocale = arguments.locale,
					rbAlias  = arguments.bundle
				);
			}

			// Get the language reference now
			thisBundle = variables.bundles[ arguments.bundle ][ arguments.locale ];
		} catch ( Any e ) {
			throw(
				message = "Error getting language (#arguments.locale#) bundle for resource (#arguments.resource#). Exception Message #e.message#",
				detail  = e.detail & e.tagContext.toString(),
				type    = "ResourceBundle.BundleLoadingException"
			);
		}

		// Check if resource does NOT exists?
		if ( !structKeyExists( thisBundle, arguments.resource ) ) {
			variables.interceptorService.announce(
				"onUnknownTranslation",
				{
					resource : arguments.resource,
					locale   : arguments.locale,
					bundle   : arguments.bundle
				}
			);

			// if logging enable
			if ( variables.settings.logUnknownTranslation ) {
				log.error( variables.settings.unknownTranslation & " key: #arguments.resource#" );
			}

			// argument defaultValue was 'default'. both NOT required in function definition so we can check both
			// first check the new 'defaultValue' param
			if ( structKeyExists( arguments, "defaultValue" ) ) {
				return arguments.defaultValue;
			}
			// if still using the old argument, return this. You will never arrive here when using 'defaultValue'
			if ( structKeyExists( arguments, "default" ) ) {
				return arguments.default;
			}

			// Check unknown translation setting
			if ( len( variables.settings.unknownTranslation ) ) {
				return variables.settings.unknownTranslation & " key: #arguments.resource#";
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
	 * Reads,parses and returns a resource bundle in struct format. It also merges the hierarchical bundles
	 * for country and variant if found.
	 *
	 * @rbFile   This must be the path + filename UP to but NOT including the locale. We auto-add the local and .properties to the end.
	 * @rbLocale The locale of the resource bundle
	 *
	 * @throws ResourceBundle.InvalidBundlePath if bundlePath is not found
	 */
	struct function getResourceBundle( required rbFile, rbLocale = "en_US" ){
		// try to load hierarchical resource rbfile_LANG_COUNTRY_VARIANT, start with default resource, followed by
		// rbFile.[ext], rbFile_LANG.[ext], rbFile_LANG_COUNTRY.[ext], rbFile_LANG_COUNTRY_VARIANT.[ext] (assuming LANG, COUNTRY and VARIANT are present)
		// [ext] = (json|java)
		// All items in resourceBundle will be overwritten by more specific ones.
		var thisRBFile       = arguments.rbFile;
		// add base resource, without language, country or variant
		var smartBundleFiles = [ thisRBFile ];
		// include lang, country and variant (if present)
		// extract and add to bundleArray by splitting rbLocale as list on '_'
		arguments.rbLocale.listEach( function( localePart, index, list ){
			thisRBFile &= "_#arguments.localePart#";
			smartBundleFiles.append( thisRBFile );
		}, "_" );
		// load all resource files for all lang, country and variants
		// and overwrite parent keys when present so you you will always have defaults
		// AND specific resource values for countries and variants without duplicating everything.
		var resourceBundle = {};
		smartBundleFiles.each( function( resourceFile ){
			// auto locate java or json bundle
			var targetPath = discoverResourcePath( arguments.resourceFile );
			// Do we load it up or ignore it
			if ( targetPath.len() ) {
				resourceBundle.append( loadBundleFromDisk( targetPath ), true ); // append and overwrite
			} else if ( variables.log.canDebug() ) {
				variables.log.debug(
					"Ignore loading variant: #arguments.resourceFile#.(json|properties) as it does not exist on disk (path:#targetPath#)"
				);
			}
		} );

		// Did we load up any resource keys? Else, we had issues with the resources requested
		if ( !resourceBundle.count() ) {
			var rbFilePath = "#arguments.rbFile#_#arguments.rbLocale#";
			var rbFullPath = variables.controller.locateFilePath( rbFilePath );
			throw(
				message: "The resource bundle file: #rbFilePath# does not exist. Please check your path",
				type   : "ResourceBundle.InvalidBundlePath",
				detail : "FullPath: #rbFullPath#, Locale: #arguments.rbLocale#"
			);
		}

		return resourceBundle;
	}

	/**
	 * Returns a given key from a specific resource bundle file and locale. NOT FROM MEMORY
	 *
	 * @rbFile       This must be the path + filename UP to but NOT including the locale. We auto-add the local and .properties to the end.
	 * @rbKey        The key to retrieve
	 * @rbLocale     The locale of the bundle. Default is en_US
	 * @defaultValue A default value to send back if resource not found
	 *
	 * @throws ResourceBundle.InvalidBundlePath      if bundlePath is not found
	 * @throws ResourceBundle.RBKeyNotFoundException if rbKey is not found
	 */
	any function getRBString(
		required rbFile,
		required rbKey,
		rbLocale = "en_US",
		defaultValue
	){
		// default locale?
		if ( !len( arguments.rbLocale ) ) {
			arguments.rbLocale = variables.settings.defaultLocale;
		}

		// Discover resource path
		var targetPath = discoverResourcePath( "#arguments.rbFile#_#arguments.rbLocale#" );
		// If Java
		if ( listLast( targetPath, "." ) == "properties" ) {
			// read file
			var fis = getResourceFileInputStream( targetPath );
			var rb  = createObject( "java", "java.util.PropertyResourceBundle" ).init( fis );
			try {
				// Retrieve string
				var rbString = rb.handleGetObject( arguments.rbKey );
			} finally {
				fis.close();
			}
		}
		// If JSON
		else {
			var myJsonResource = loadJsonResource( targetPath );
			if ( myJsonResource.keyExists( arguments.rbKey ) ) {
				var rbString = myJsonResource[ arguments.rbKey ];
			}
		}

		// Check if found?
		if ( !isNull( rbString ) ) {
			return rbString;
		}

		// Check default?
		// argument defaultValue was 'default'. both NOT required in function definition so we can check both
		// first check the new 'defaultValue' param
		if ( !isNull( arguments.defaultValue ) ) {
			return arguments.defaultValue;
		}

		// if still using the old value, return this. You will never arrive here when using 'defaultValue'
		if ( !isNull( arguments.default ) ) {
			return arguments.default;
		}

		// Nothing to return, throw it
		throw(
			message = "Fatal error: resource bundle #arguments.rbFile# does not contain key #arguments.rbKey#",
			type    = "ResourceBundle.RBKeyNotFoundException"
		);
	}

	/**
	 * Returns an array of keys from a specific resource bundle. NOT FROM MEMORY
	 *
	 * @rbFile   This must be the path + filename UP to but NOT including the locale. We auto-add the local and .properties to the end.
	 * @rbLocale The locale to use, if not passed, defaults to default locale.
	 *
	 * @return array of keys from a specific resource bundle
	 *
	 * @throws ResourceBundle.InvalidBundlePath if bundlePath is not found
	 */
	array function getRBKeys( required rbFile, rbLocale = "" ){
		var keys = arrayNew( 1 );

		// default locale?
		if ( NOT len( arguments.rbLocale ) ) {
			arguments.rbLocale = variables.settings.defaultLocale;
		}

		// Discover resource path
		var targetPath = discoverResourcePath( "#arguments.rbFile#_#arguments.rbLocale#" );
		// If Java
		if ( listLast( targetPath, "." ) == "properties" ) {
			// read file
			var fis = getResourceFileInputStream( targetPath );
			var rb  = createObject( "java", "java.util.PropertyResourceBundle" ).init( fis );
			try {
				// Get Keys
				var rbKeys = rb.getKeys();
				// Loop through Keys and get the elements.
				while ( rbKeys.hasMoreElements() ) {
					arrayAppend( keys, rbKeys.nextElement() );
				}
			} finally {
				fis.close();
			}
			return keys;
		} else {
			return loadJsonResource( targetPath ).reduce( function( acc, key, value ){
				acc.append( key );
			}, [] );
		}
	}

	/**
	 * Performs messageFormat like operation on compound rb string. So if you have a string with {1} it will replace it. You can also have multiple and send in an array to do replacements.
	 *
	 * @rbString A localized string with {bnamed|positional} replacements
	 * @values   Array, Struct or single value to format into the rbString
	 *
	 * @return formatted string
	 */
	string function formatRBString( required rbString, required values ){
		var tmpStr = arguments.rbString;

		// Array substitutions by position
		if ( isArray( arguments.values ) ) {
			var valLen = arrayLen( arguments.values );

			for ( var x = 1; x lte valLen; x = x + 1 ) {
				tmpStr = tmpStr.replace( "{#x#}", arguments.values[ x ], "ALL" );
			}

			return tmpStr;
		}
		// Struct substitutions by key
		else if ( isStruct( arguments.values ) ) {
			for ( var thisKey in arguments.values ) {
				tmpStr = tmpStr.replaceNoCase(
					"{#lCase( thisKey )#}",
					arguments.values[ lCase( thisKey ) ],
					"ALL"
				);
			}
			return tmpStr;
		}

		// Single simple substitution
		return arguments.rbString.replace( "{1}", arguments.values, "ALL" );
	}

	/**
	 * performs messageFormat on compound rb string
	 *
	 * @thisPattern pattern to use in formatting
	 * @args        substitution values, simple or array
	 * @thisLocale  locale to use in formatting, defaults to en_US
	 *
	 * @return a formatted string
	 */
	string function messageFormat(
		required string thisPattern,
		required args,
		thisLocale = ""
	){
		var pattern   = createObject( "java", "java.util.regex.Pattern" );
		var regexStr  = "(\{[0-9]{1,},number.*?\})";
		var inputArgs = arguments.args;

		// locale?
		if ( !arguments.thisLocale.len() ) {
			arguments.thisLocale = variables.settings.defaultLocale;
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
	 * @return boolean
	 */
	boolean function verifyPattern( required string pattern ){
		try {
			var test = createObject( "java", "java.text.MessageFormat" ).init( arguments.pattern );
		} catch ( Any e ) {
			return false;
		}
		return true;
	}

	/************************************************************************************/
	/****************************** PRIVATE METHODS *************************************/
	/************************************************************************************/

	/**
	 * Locate the resource on disk and check whether it's a Java or JSON bundle.
	 *
	 * @resourcePath The resource path with no extension included
	 *
	 * @return The located properties or json path or empty path indicating it was not located.
	 */
	private function discoverResourcePath( required resourcePath ){
		var propertiesPath = variables.controller.locateFilePath( arguments.resourcePath & ".properties" );
		var jsonPath       = variables.controller.locateFilePath( arguments.resourcePath & ".json" );
		return propertiesPath.len() ? propertiesPath : jsonPath;
	}

	/**
	 * get Java FileInputStream for resource bundle
	 *
	 * @rbFilePath path + filename for resource, including locale + .properties
	 *
	 * @return java.io.FileInputStream
	 *
	 * @throws ResourceBundle.InvalidBundlePath
	 */
	private function getResourceFileInputStream( required string rbFilePath ){
		// Try to locate the path using the coldbox plugin utility
		var rbFullPath = variables.controller.locateFilePath( rbFilePath );

		// Validate Location
		if ( !len( rbFullPath ) ) {
			throw(
				message = "The resource bundle file: #rbFilePath# does not exist. Please check your path",
				type    = "ResourceBundle.InvalidBundlePath",
				detail  = "FullPath: #rbFullPath#"
			);
		}

		// read file and return
		return createObject( "java", "java.io.FileInputStream" ).init( rbFullPath );
	}

	/**
	 * Load a bundle from disk
	 *
	 * @resourceBundleFullPath full path to a (partial) resourceFile
	 *
	 * @return struct resourcebundle
	 *
	 * @throws ResourceBundle.InvalidBundlePath
	 */
	private struct function loadBundleFromDisk( required string resourceBundleFullPath ){
		if ( listLast( arguments.resourceBundleFullPath, "." ) == "properties" ) {
			return loadJavaResource( arguments.resourceBundleFullPath );
		}
		// Else JSON
		return loadJsonResource( arguments.resourceBundleFullPath );
	}

	/**
	 * loads a java resource file from file
	 *
	 * @resourceBundleFullPath full path to a (partial) resourceFile
	 *
	 * @return struct resourcebundle
	 *
	 * @throws ResourceBundle.InvalidBundlePath
	 */
	private function loadJavaResource( required string resourceBundleFullPath ){
		var resourceBundle = {};
		var thisKey        = "";
		// create a file input stream with file location
		var fis            = getResourceFileInputStream( arguments.resourceBundleFullPath );
		var fir            = createObject( "java", "java.io.InputStreamReader" ).init( fis, "UTF-8" );
		// init rb with file stream
		var rb             = createObject( "java", "java.util.PropertyResourceBundle" ).init( fir );
		try {
			// get keys
			var keys = rb.getKeys();
			// Loop through property keys and store the values into bundle
			while ( keys.hasMoreElements() ) {
				thisKey                   = keys.nextElement();
				resourceBundle[ thisKey ] = rb.handleGetObject( thisKey );
			}
		} finally {
			fis.close();
		}
		return resourceBundle;
	}

	/**
	 * loads a JSON resource file from file
	 *
	 * @resourceBundleFullPath full path to a (partial) resourceFile
	 *
	 * @return struct resourcebundle
	 *
	 * @throws ResourceBundle.InvalidJSONBundlePath
	 */
	private function loadJsonResource( required string resourceBundleFullPath ){
		try {
			return flattenStruct( deserializeJSON( fileRead( arguments.resourceBundleFullPath ) ) );
		} catch ( any e ) {
			throw(
				message = "Invalid JSON resource bundle #arguments.resourceBundleFullPath#",
				type    = "ResourceBundle.InvalidJSONBundlePath"
			)
		}
	}

	/**
	 * flatten a struct, so we can use keys in format 'main.sub1.sub2.resource'.
	 *
	 * @originalStruct
	 * @flattenedStruct necessary for recursion
	 * @prefix_string   necessary for processing, so key kan be prepended with parent name
	 *
	 * @return struct resourcebundle
	 *
	 * @throws ResourceBundle.InvalidBundlePath
	 */
	private function flattenStruct(
		required struct originalStruct,
		struct flattenedStruct = {},
		string prefixString    = ""
	){
		arguments.originalStruct.each( function( key, value ){
			if ( isStruct( value ) ) {
				flattenedStruct = flattenStruct( value, flattenedStruct, "#prefixString##key#." );
			} else {
				structInsert(
					flattenedStruct,
					"#prefixString##key#",
					value,
					false
				);
			}
		} );
		return flattenedStruct;
	}

}
