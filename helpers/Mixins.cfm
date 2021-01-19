<cfscript>
/**
 * Get the user's currently set locale or default locale according to settings
 */
function getFWLocale() {
	return i18n().getfwLocale();
}

/**
 * Set the locale for a specific user
 * @locale The locale to set. Must be Java Style Standard: en_US, if empty it will default to the default locale
 * @dontLoadRBFlag Flag to load the resource bundle for the specified locale (If not already loaded)
 *
 * @return i18n Service
 */
function setFWLocale( string locale = "", boolean dontloadRBFlag = false ) {
	return i18n().setfwLocale( argumentCollection = arguments );
}

/**
 * Retrieve a resource from a resource bundle with replacements or auto-loading
 * @resource The resource (key) to retrieve from the main loaded bundle.
 * @defaultValue A default value to send back if the resource (key) not found
 * @locale Pass in which locale to take the resource from. By default it uses the user's current set locale
 * @values An array, struct or simple string of value replacements to use on the resource string
 * @bundle The bundle alias to use to get the resource from when using multiple resource bundles. By default the bundle name used is 'default'
 */
function getResource(
	required resource,
	defaultValue,
	locale,
	values,
	bundle
) {
	// return resource info
	return resourceService().getResource( argumentCollection = arguments );
}

// Alias to getResource
variables.$r = variables.getResource;

/**
 * Get i18n Model
 */
function i18n(){
	if ( NOT structKeyExists( variables, "cboxi18n" ) ) {
		variables.cboxi18n = getInstance( "i18n@cbi18n" );
	}
	return variables.cboxi18n;
}

/**
 * Get the resource service model
 */
function resourceService(){
	// Verify injection
	if ( NOT structKeyExists( variables, "cboxResourceService" ) ) {
		variables.cboxResourceService = getInstance( "resourceService@cbi18n" );
	}
	return variables.cboxResourceService;
}
</cfscript>
