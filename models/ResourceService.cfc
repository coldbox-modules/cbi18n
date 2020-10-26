/**
 * Copyright Since 2005 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * Inspired by Paul Hastings
 * ---
 * This service reads and parses java resource bundles wit a nice integration for replacements
 */
component singleton accessors="true" {

	// DI
	property name="log"        inject="logbox:logger:{this}";
	property name="controller" inject="coldbox";
	property name="i18n"       inject="provider:i18n@cbi18n";
	property name="settings"   inject="coldbox:moduleSettings:cbi18n";

	/**
	 * properties
	 */

	/**
	 * Constructor
	 */
	function init(){
		return this;
	}

	/**
	 * executes after wirebox injections to complete initialization
	 *
	 * @throws cbi18n.InvalidConfiguration
	 */
	function onDiComplete(){
		// store bundles in memory
		variables.aBundles = {};
		// resource type = java vs JSON
		if (
			!listFindNoCase(
				"json,java",
				variables.settings.resourceType
			)
		) {
			throw(
				message = "Invalid resourceType, valid entries are (java|json)",
				type    = "cbi18n.InvalidConfiguration"
			)
		}
		variables.settings.resourceType = lCase( variables.settings.resourceType );
	}

	/**
	 * Reference to loaded bundles
	 *
	 * @return struct of bundles
	 */
	struct function getBundles(){
		return variables.aBundles;
	}

	/**
	 * Get a list of all loaded bundles
	 *
	 * @return array of all keys of loaded bundles
	 */
	array function getLoadedBundles(){
		return structKeyArray( variables.aBundles );
	}

	/**
	 * Tries to load a resource bundle into ColdBox memory if not loaded already
	 *
	 * @rbFile This must be the path + filename UP to but NOT including the locale. We auto-add .properties or .json to the end alongside the locale
	 * @rbLocale The locale of the bundle to load
	 * @force Forces the loading of the bundle even if its in memory
	 * @rbAlias The unique alias name used to store this resource bundle in memory. The default name is the name of the rbFile passed if not passed.
	 */
	any function loadBundle(
		required string rBFile,
		string rbLocale = "en_US",
		boolean force   = false,
		string rbAlias  = "default"
	){
		// Setup rbAlias if not passed
		if ( !structKeyExists( arguments, "rbAlias" ) || !len( arguments.rbAlias ) ) {
			arguments.rbFile  = replace( arguments.rbFile, "\", "/", "all" );
			arguments.rbAlias = listLast( arguments.rbFile, "/" );
		}

		// Verify bundle register name exists
		if (
			!structKeyExists(
				variables.aBundles,
				arguments.rbAlias
			)
		) {
			lock
				name          ="rbregister.#hash( arguments.rbFile & arguments.rbAlias )#"
				type          ="exclusive"
				timeout       ="10"
				throwontimeout="true" {
				if (
					!structKeyExists(
						variables.aBundles,
						arguments.rbAlias
					)
				) {
					variables.aBundles[ arguments.rbAlias ] = {};
				}
			}
		}

		// Verify bundle register locale exists or forced
		if (
			!structKeyExists(
				variables.aBundles[ arguments.rbAlias ],
				arguments.rbLocale
			) || arguments.force
		) {
			lock
				name          ="rbload.#hash( arguments.rbFile & arguments.rbLocale )#"
				type          ="exclusive"
				timeout       ="10"
				throwontimeout="true" {
				if (
					!structKeyExists(
						variables.aBundles[ arguments.rbAlias ],
						arguments.rbLocale
					) || arguments.force
				) {
					// load a bundle and store it.
					variables.aBundles[ arguments.rbAlias ][ arguments.rbLocale ] = getResourceBundle(
						rbFile   = arguments.rbFile,
						rbLocale = arguments.rbLocale
					);
					// logging
					if ( log.canInfo() ) {
						log.info(
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
	 * @defaultValue A default value to send back if the resource (key) not found
	 * @locale Pass in which locale to take the resource from. By default it uses the user's current set locale
	 * @values An array, struct or simple string of value replacements to use on the resource string
	 * @bundle The bundle alias to use to get the resource from when using multiple resource bundles. By default the bundle name used is 'default'
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
					rbFile = variables.settings.defaultResourceBundle;
				} else if (
					structKeyExists(
						variables.settings.resourceBundles,
						arguments.bundle
					)
				) {
					rbFile = variables.settings.resourceBundles[ arguments.bundle ];
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
			return formatRBString(
				thisBundle[ arguments.resource ],
				arguments.values
			);
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
	 *
	 * @throws ResourceBundle.InvalidBundlePath if bundlePath is not found
	 */
	struct function getResourceBundle( required rbFile, rbLocale = "en_US" ){
		// try to load hierarchical resource rbfile_LANG_COUNTRY_VARIANT, start with default resource, followed by
		// rbFile.[ext], rbFile_LANG.[ext], rbFile_LANG_COUNTRY.[ext], rbFile_LANG_COUNTRY_VARIANT.[ext] (assuming LANG, COUNTRY and VARIANT are present)
		// [ext] = (json|java)
		// All items in resourceBundle will be overwritten by more specific ones.

		// define extension based on resourceType, .properties for java, else .json (for json)
		var extension = ( variables.settings.resourceType == "java" ) ? ".properties" : ".json";

		// Create all file options from locale
		var myRbFile         = arguments.rbFile;
		// add base resource, without language, country or variant
		var smartBundleFiles = [ "#myRbFile##extension#" ];
		// include lang, country and variant (if present)
		// extract and add to bundleArray by splitting rbLocale as list on '_'
		arguments.rbLocale.listEach( function( localePart, index, list ){
			myRbFile &= "_#localePart#";
			smartBundleFiles.append( "#myRbFile##extension#" );
		}, "_" );
		// load all resource files for all lang, country and variants
		// and overwrite parent keys when present so you you will always have defaults
		// AND specific resource values for countries and variants without duplicating everything.
		var resourceBundle      = structNew();
		var isValidBundleLoaded = false;
		smartBundleFiles.each( function( resourceFile ){
			var resourceBundleFullPath = variables.controller.locateFilePath( resourceFile );
			if ( resourceBundleFullPath.len() ) {
				resourceBundle.append(
					_loadSubBundle( resourceBundleFullPath ),
					true
				); // append and overwrite
				isValidBundleLoaded = true; // at least one bundle loaded so no errors
			};
		} );

		// Validate resource is loaded or error.
		if ( !isValidBundleLoaded ) {
			var rbFilePath = "#arguments.rbFile#_#arguments.rbLocale##extension#";
			var rbFullPath = variables.controller.locateFilePath( rbFilePath );
			throw(
				message = "The resource bundle file: #rbFilePath# does not exist. Please check your path",
				type    = "ResourceBundle.InvalidBundlePath",
				detail  = "FullPath: #rbFullPath#"
			);
		}

		return resourceBundle;
	}

	/**
	 * Returns a given key from a specific resource bundle file and locale. NOT FROM MEMORY
	 *
	 * @rbFile This must be the path + filename UP to but NOT including the locale. We auto-add the local and .properties to the end.
	 * @rbKey The key to retrieve
	 * @rbLocale The locale of the bundle. Default is en_US
	 * @defaultValue A default value to send back if resource not found
	 *
	 * @throws ResourceBundle.InvalidBundlePath if bundlePath is not found
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

		if ( variables.settings.ResourceType == "java" ) {
			// read file
			var fis = getResourceFileInputStream( "#arguments.rbFile#_#arguments.rbLocale#.properties" );
			var rb  = createObject(
				"java",
				"java.util.PropertyResourceBundle"
			).init( fis );
			try {
				// Retrieve string
				var rbString = rb.handleGetObject( arguments.rbKey );
			} finally {
				fis.close();
			}
		} else {
			var myJsonResource = _loadJsonSubBundle( "#arguments.rbFile#_#arguments.rbLocale#.json" );
			if ( myJsonResource.KeyExists( arguments.rbKey ) ) {
				var rbString = myJsonResource[ arguments.rbKey ];
			}
		}
		// Check if found?
		if ( isDefined( "rbString" ) ) {
			return rbString;
		}
		// Check default?
		// argument defaultValue was 'default'. both NOT required in function definition so we can check both
		// first check the new 'defaultValue' param
		if ( structKeyExists( arguments, "defaultValue" ) ) {
			return arguments.defaultValue;
		}
		// if still using the old value, return this. You will never arrive here when using 'defaultValue'
		if ( structKeyExists( arguments, "default" ) ) {
			return arguments.default;
		}

		// Nothing to return, throw it
		throw(
			message = "Fatal error: resource bundle #arguments.rbFile# does not contain key #arguments.rbKey#",
			type    = "ResourceBundle.RBKeyNotFoundException"
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
	array function getRBKeys( required rbFile, rbLocale = "" ){
		var keys = arrayNew( 1 );

		// default locale?
		if ( NOT len( arguments.rbLocale ) ) {
			arguments.rbLocale = variables.settings.defaultLocale;
		}

		if ( variables.settings.ResourceType == "java" ) {
			// read file
			var fis = getResourceFileInputStream( "#arguments.rbFile#_#arguments.rbLocale#.properties" );
			var rb  = createObject(
				"java",
				"java.util.PropertyResourceBundle"
			).init( fis );

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
			var myResource = _loadJsonSubBundle( "#arguments.rbFile#_#arguments.rbLocale#.json" );
			return myResource.reduce( function( acc, key, value ){
				acc.append( key );
			}, [] );
		}
	}

	/**
	 * performs messageFormat like operation on compound rb string. So if you have a string with {1} it will replace it. You can also have multiple and send in an array to do replacements.
	 *
	 * @rbString resourceString
	 * @substituteValues Array, Struct or single value to format.
	 *
	 * @returns formatted string
	 */
	string function formatRBString(
		required rbString,
		required substituteValues
	){
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
	 * @returns boolean
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
	 * get Java FileInputStream for resource bundle
	 *
	 * @rbFilePath path + filename for resource, including locale + .properties
	 *
	 * @return java.io.FileInputStream
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
	 * loads a java or JSON resource file from file
	 *
	 * @resourceBundleFullPath full path to a (partial) resourceFile
	 *
	 * @return struct resourcebundle
	 * @throws ResourceBundle.InvalidBundlePath
	 */
	private function _loadSubBundle( required string resourceBundleFullPath ){
		if ( variables.settings.resourceType == "java" ) {
			return _loadJavaSubBundle( resourceBundleFullPath );
		} else {
			// load JSON (sub)bundle
			return _loadJsonSubBundle( resourceBundleFullPath );
		}
	}

	/**
	 * loads a java resource file from file
	 *
	 * @resourceBundleFullPath full path to a (partial) resourceFile
	 *
	 * @return struct resourcebundle
	 * @throws ResourceBundle.InvalidBundlePath
	 */
	private function _loadJavaSubBundle( required string resourceBundleFullPath ){
		var resourceBundle = {};
		var thisKey        = "";
		// create a file input stream with file location
		var fis            = getResourceFileInputStream( resourceBundleFullPath );
		var fir            = createObject( "java", "java.io.InputStreamReader" ).init( fis, "UTF-8" );
		// init rb with file stream
		var rb             = createObject(
			"java",
			"java.util.PropertyResourceBundle"
		).init( fir );
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
	 * @throws ResourceBundle.InvalidJSONBundlePath
	 */
	private function _loadJsonSubBundle( required string resourceBundleFullPath ){
		try {
			return _flattenStruct( deserializeJSON( fileRead( resourceBundleFullPath ) ) );
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
	 * @prefix_string necessary for processing, so key kan be prepended with parent name
	 *
	 *
	 * @return struct resourcebundle
	 * @throws ResourceBundle.InvalidBundlePath
	 */
	private function _flattenStruct(
		required struct originalStruct,
		struct flattenedStruct = {},
		string prefixString    = ""
	){
		arguments.originalStruct.each( function( key, value ){
			if ( isStruct( value ) ) {
				flattenedStruct = _flattenStruct(
					value,
					flattenedStruct,
					"#prefixString##key#."
				);
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
