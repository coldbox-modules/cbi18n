/**
 * Copyright Since 2005 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * Internationalization and localization support for ColdBox
 */
component singleton accessors="true" {

	// DI
	property name="resourceService" inject="resourceService@cbi18n";
	property name="controller"      inject="coldbox";
	property name="wirebox"         inject="wirebox";
	property name="settings"        inject="coldbox:moduleSettings:cbi18n";

	/**
	 * The wirebox id of the storage provider
	 */
	property name="localeStorage";
	/**
	 * The default locale configured for the application
	 */
	property name="defaultLocale";
	/**
	 * The default resource bundle for the application, if any
	 */
	property name="defaultResourceBundle";

	/**
	 * Constructor
	 */
	i18n function init(){
		// Internal Java Objects
		variables.aDateFormat = createObject( "java", "java.text.DateFormat" );
		variables.aLocale     = createObject( "java", "java.util.Locale" );
		variables.timeZone    = createObject( "java", "java.util.TimeZone" );
		variables.aCalendar   = createObject( "java", "java.util.GregorianCalendar" ).init( buildLocale() );

		return this;
	}

	/**
	 * Reads,parses,saves the locale and resource bundles defined in the config.
	 *
	 * @throws i18N.DefaultSettingsInvalidException
	 */
	void function onDIComplete(){
		// Default instance settings
		variables.localeStorage         = variables.settings.localeStorage;
		variables.defaultResourceBundle = variables.settings.defaultResourceBundle;
		variables.defaultLocale         = variables.settings.defaultLocale;

		// v1 Shim for localestorage, remove by v3
		switch ( variables.localeStorage ) {
			case "session": {
				variables.localeStorage = "sessionStorage@cbstorages";
				break;
			}
			case "client": {
				variables.localeStorage = "clientStorage@cbstorages";
				break;
			}
			case "cookie": {
				variables.localeStorage = "cookieStorage@cbstorages";
				break;
			}
			case "request": {
				variables.localeStorage = "requestStorage@cbstorages";
				break;
			}
		}

		// instantiate storage service for locale storage
		try {
			variables.storageService = variables.wirebox.getInstance( variables.localeStorage );
		} catch ( any e ) {
			var message = variables.localeStorage.len()
			 ? "The LocaleStorage setting #variables.localeStorage# is invalid."
			 : "The LocaleStorage setting cannot be found. Please make sure you create the i18n elements";
			throw(
				message     : e.message,
				type        : "i18N.DefaultSettingsInvalidException",
				extendedInfo: "Please check the cbstorages documentation, LocaleStorage should be in the format of a valid storage object 'someStorage@cbstorages', e.g cookieStorage@cbstorages, cacheStorage@cbstorages etcetera."
			);
		}
		// set locale setup on configuration file
		setFWLocale( getFwLocale() );

		// Verify if we have a default resource bundle, if we do, load it.
		if ( variables.defaultResourceBundle.len() ) {
			variables.resourceService.loadBundle(
				rbFile  : variables.defaultResourceBundle,
				rbLocale: getFwLocale(),
				rbAlias : "default"
			);
		}

		// are we loading multiple resource bundles? If so, load them up
		variables.settings.resourceBundles.each( function( bundleKey, thisBundle ){
			variables.resourceService.loadBundle(
				rbFile  : thisBundle,
				rbLocale: getFwLocale(),
				rbAlias : lCase( bundleKey )
			);
		} );
	}

	/************************************************************************************/
	/****************************** CHOSEN LOCAL METHODS ********************************/
	/************************************************************************************/

	/**
	 * Get the user's locale
	 *
	 * @return The users locale string if set, else, the default locale
	 */
	string function getFwLocale(){
		// return locale, default already set in onDIComplete
		return variables.storageService.get( "currentLocale", variables.settings.defaultLocale );
	}

	/**
	 * Set the default locale to use in the framework for a specific user.
	 *
	 * @locale The locale to change and set. Must be Java Style: en_US. If none passed, then we default to default locale from configuration settings
	 */
	i18n function setFwLocale( string locale = "" ){
		if ( !arguments.locale.len() ) {
			arguments.locale = variables.defaultLocale;
		}
		variables.storageService.set( "currentLocale", arguments.locale );
		return this;
	}

	/**
	 * Returns a name for the locale that is appropriate for display to the user. Eg: English (United States)
	 */
	string function getFWLocaleDisplay(){
		return buildLocale( getfwLocale() ).getDisplayName();
	}

	/**
	 * returns a human readable country name for the chosen application locale. Eg: United States
	 */
	string function getFWCountry(){
		return buildLocale( getfwLocale() ).getDisplayCountry();
	}

	/**
	 * returns 2-letter ISO country name for the chosen application locale. Eg: us
	 *
	 */
	string function getFWCountryCode(){
		return buildLocale( getfwLocale() ).getCountry();
	}

	/**
	 * returns 3-letter ISO country name for the chosen application locale. Eg: USA
	 */
	string function getFWISO3CountryCode(){
		return buildLocale( getfwLocale() ).getISO3Country();
	}

	/**
	 * Returns a human readable name for the locale's language. Eg: English
	 */
	string function getFWLanguage(){
		return buildLocale( getfwLocale() ).getDisplayLanguage();
	}

	/**
	 * Returns the two digit code for the locale's language. Eg: en
	 */
	string function getFWLanguageCode(){
		return buildLocale( getfwLocale() ).getLanguage();
	}

	/**
	 * Returns the ISO 3 code for the locale's language. Eg: eng
	 */
	string function getFWISO3LanguageCode(){
		return buildLocale( getfwLocale() ).getISO3Language();
	}

	/**
	 * Validate a locale
	 *
	 * @thisLocale Locale to validate
	 */
	boolean function isValidLocale( required string thisLocale ){
		return ( listFind( arrayToList( getLocales() ), arguments.thisLocale ) ) ? true : false;
	}

	/**
	 * returns array of locales
	 */
	array function getLocales(){
		return variables.aLocale.getAvailableLocales();
	}

	/**
	 * returns list of locale names, UNICODE direction char (LRE/RLE) added as required
	 */
	string function getLocaleNames(){
		var theseLocales = "";
		var thisName     = "";
		for ( var orgLocale in getLocales() ) {
			if ( listLen( orgLocale, "_" ) == 2 ) {
				if ( left( orgLocale, 2 ) == "ar" || left( orgLocale, 2 ) == "iw" ) {
					thisName = chr( 8235 ) & orgLocale.getDisplayName( orgLocale ) & chr( 8234 );
				} else {
					thisName = orgLocale.getDisplayName( orgLocale );
				}
				theseLocales = theseLocales.listAppend( thisName );
			};
		};
		return theseLocales;
	}

	/**
	 * returns array of 2 letter ISO languages
	 */
	array function getIsoLanguages(){
		return variables.aLocale.getIsoLanguages();
	}

	/**
	 * returns array of 2 letter ISO countries
	 */
	array function getIsoCountries(){
		return variables.aLocale.getISOCountries();
	}

	/**
	 * determines if given locale is BIDI. core java uses 'iw' for hebrew, leaving 'he' just in case this is a version thing
	 */
	boolean function isBidi(){
		return listFind( "ar,iw,fa,ps,he", left( buildLocale( getfwLocale() ).toString(), 2 ) ) ? true : false;
	}

	/**
	 * returns currency symbol for this locale
	 *
	 * @localized return international (USD, THB, etc.) or localized ($,etc.) symbol
	 */
	string function getCurrencySymbol( boolean localized = true ){
		// var aCurrency = createObject( "java", "com.ibm.icu.util.Currency" );
		var aCurrency = createObject( "java", "java.util.Currency" );
		if ( arguments.localized ) {
		}
		return ( arguments.localized ) ? aCurrency
			.getInstance( buildLocale( getfwLocale() ) )
			.getSymbol( buildLocale( getfwLocale() ) ) : aCurrency
			.getInstance( buildLocale( getfwLocale() ) )
			.getCurrencyCode();
	}

	/**
	 * returns structure holding decimal format symbols for this locale
	 *
	 * @return struct holding decimal format symbols for this locale
	 */
	struct function getDecimalSymbols(){
		var dfSymbols = createObject( "java", "java.text.DecimalFormatSymbols" ).init(
			buildLocale( getfwLocale() )
		);
		var symbols                       = structNew();
		// symbols.plusSign=dfSymbols.getPlusSign().toString();
		symbols.Percent                   = dfSymbols.getPercent().toString();
		symbols.minusSign                 = dfSymbols.getMinusSign().toString();
		symbols.currencySymbol            = dfSymbols.getCurrencySymbol().toString();
		symbols.internationCurrencySymbol = dfSymbols.getInternationalCurrencySymbol().toString();
		symbols.monetaryDecimalSeparator  = dfSymbols.getMonetaryDecimalSeparator().toString();
		symbols.exponentSeparator         = dfSymbols.getExponentSeparator().toString();
		symbols.perMille                  = dfSymbols.getPerMill().toString();
		symbols.decimalSeparator          = dfSymbols.getDecimalSeparator().toString();
		symbols.groupingSeparator         = dfSymbols.getGroupingSeparator().toString();
		symbols.zeroDigit                 = dfSymbols.getZeroDigit().toString();
		return symbols;
	}

	/**
	 * DateTime format
	 *
	 * @thisOffset     java epoch offset
	 * @thisDateFormat FULL=0, LONG=1, MEDIUM=2, SHORT=3
	 * @thisTimeFormat FULL=0, LONG=1, MEDIUM=2, SHORT=3
	 * @tz             timezone
	 */
	string function dateTimeFormat(
		required numeric thisOffset,
		numeric thisDateFormat = 1,
		numeric thisTimeFormat = 1,
		tz                     = variables.timeZone.getDefault().getID()
	){
		var tDateFormat    = javacast( "int", arguments.thisDateFormat );
		var tTimeFormat    = javacast( "int", arguments.thisTimeFormat );
		var tDateFormatter = variables.aDateFormat.getDateTimeInstance(
			tDateFormat,
			tTimeFormat,
			buildLocale( getfwLocale() )
		);
		var tTZ = variables.timeZone.getTimezone( arguments.tz );
		tDateFormatter.setTimezone( tTZ );
		return tDateFormatter.format( arguments.thisOffset );
	}

	/**
	 * Date format
	 *
	 * @thisOffset     java epoch offset
	 * @thisDateFormat FULL=0, LONG=1, MEDIUM=2, SHORT=3
	 * @tz             timezone
	 */
	string function dateFormat(
		required numeric thisOffset,
		numeric thisDateFormat = 1,
		tz                     = variables.timeZone.getDefault().getID()
	){
		var tDateFormat    = javacast( "int", arguments.thisDateFormat );
		var tDateFormatter = variables.aDateFormat.getDateInstance( tDateFormat, buildLocale( getfwLocale() ) );
		var tTZ            = variables.timeZone.getTimezone( arguments.tz );
		tDateFormatter.setTimezone( tTZ );
		return tDateFormatter.format( arguments.thisOffset );
	}

	/**
	 * Time Format
	 *
	 * @thisOffset     java epoch offset
	 * @thisTimeFormat FULL=0, LONG=1, MEDIUM=2, SHORT=3
	 * @tz             timezone
	 */
	string function timeFormat(
		required numeric thisOffset,
		numeric thisTimeFormat = 1,
		tz                     = variables.timeZone.getDefault().getID()
	){
		var tTimeFormat    = javacast( "int", arguments.thisTimeFormat );
		var tTimeFormatter = variables.aDateFormat.getTimeInstance( tTimeFormat, buildLocale( getfwLocale() ) );
		var tTZ            = variables.timeZone.getTimezone( arguments.tz );
		tTimeFormatter.setTimezone( tTZ );
		return tTimeFormatter.format( arguments.thisOffset );
	}

	/**
	 * locale version of dateFormat. Needs object instantiation. That is your job not mine.
	 *
	 * @date 
	 * @style FULL=0, LONG=1, MEDIUM=2, SHORT=3
	 */
	function dateLocaleFormat( required date date, string style = "LONG" ){
		// hack to trap & fix varchar mystery goop coming out of mysql datetimes
		var aCalendar = createObject( "java", "java.util.GregorianCalendar" ).init( buildLocale() );
		try {
			return variables.aDateFormat
				.getDateInstance( variables.aDateFormat[ arguments.style ], buildLocale( getfwLocale() ) )
				.format( arguments.date );
		} catch ( Any e ) {
			aCalendar.setTime( arguments.date );
			return variables.aDateFormat
				.getDateInstance( variables.aDateFormat[ arguments.style ], buildLocale( getfwLocale() ) )
				.format( aCalendar.getTime() );
		}
	}

	/**
	 * locale version of timeFormat. Needs object instantiation. That is your job not mine.
	 *
	 * @date 
	 * @style FULL=0, LONG=1, MEDIUM=2, SHORT=3
	 */
	function timeLocaleFormat( required date date, string style = "SHORT" ){
		// hack to trap & fix varchar mystery goop coming out of mysql datetimes
		var aCalendar = createObject( "java", "java.util.GregorianCalendar" ).init( buildLocale() );
		try {
			return variables.aDateFormat
				.getTimeInstance( variables.aDateFormat[ arguments.style ], buildLocale( getfwLocale() ) )
				.format( arguments.date );
		} catch ( Any e ) {
			aCalendar.setTime( arguments.date );
			return variables.aDateFormat
				.getTimeInstance( variables.aDateFormat[ arguments.style ], buildLocale( getfwLocale() ) )
				.format( aCalendar.getTime() );
		}
	}

	/**
	 * locale date/time format. Needs object instantiation. That is your job not mine.
	 *
	 * @date     
	 * @dateStyle FULL=0, LONG=1, MEDIUM=2, SHORT=3
	 * @timeStyle FULL=0, LONG=1, MEDIUM=2, SHORT=3
	 */
	function datetimeLocaleFormat(
		required date date,
		string dateStyle = "SHORT",
		string timeStyle = "SHORT"
	){
		var aCalendar = createObject( "java", "java.util.GregorianCalendar" ).init( buildLocale() );
		try {
			return variables.aDateFormat
				.getDateTimeInstance(
					variables.aDateFormat[ arguments.dateStyle ],
					variables.aDateFormat[ arguments.timeStyle ],
					buildLocale( getfwLocale() )
				)
				.format( arguments.date );
		} catch ( Any e ) {
			aCalendar.setTime( arguments.date );
			return variables.aDateFormat
				.getDateTimeInstance(
					variables.aDateFormat[ arguments.dateStyle ],
					variables.aDateFormat[ arguments.timeStyle ],
					buildLocale( getfwLocale() )
				)
				.format( aCalendar.getTime() );
		}
	}

	/**
	 * parses localized date string to datetime object or returns blank if it can't parse
	 *
	 * @thisDate
	 */
	numeric function dateParse( required string thisDate ){
		var isOk           = false;
		var parsedDate     = "";
		var tDateFormatter = "";
		/* holy cow batman, can't parse dates in an elegant way. bash! pow! socko! */

		var dateStyles = [ 0, 1, 2, 3 ];
		dateStyles.each( function( thisDateStyle ){
			isOk           = true;
			tDateFormatter = variables.aDateFormat.getDateInstance(
				javacast( "int", thisDateStyle ),
				buildLocale( getfwLocale() )
			);
			try {
				parsedDate = tDateFormatter.parse( thisDate );
			} catch ( any e ) {
				isOK = false;
			}
			if ( isOK ) {
				break;
			}
		} );
		return parsedDate.getTime();
	}

	/**
	 * parses localized datetime string to datetime object or returns blank if it can't parse
	 *
	 * @thisDate
	 */
	numeric function dateTimeParse( required string thisDate ){
		var isOk           = false;
		var dStyle         = 0;
		var tStyle         = 0;
		var parsedDate     = "";
		var tDateFormatter = "";
		/* holy cow batman, can't parse dates in an elegant way. bash! pow! socko! */
		var dateStyles = [ 0, 1, 2, 3 ];
		var timeStyles = [ 0, 1, 2, 3 ];
		dateStyles.each( function( thisDateStyle ){
			dStyle = javacast( "int", thisDateStyle );
			timeStyles.each( function( thisTimeStyle ){
				tStyle         = javacast( "int", thisTimeStyle );
				isOK           = true;
				tDateFormatter = variables.aDateFormat.getDateTimeInstance(
					dStyle,
					tStyle,
					buildLocale( getfwLocale() )
				);
				try {
					parsedDate = tDateFormatter.parse( thisDate );
				} catch ( any e ) {
					isOK = false;
				}
				if ( isOK ) {
					break;
				}
			} );
		} );
		return parsedDate.getTime();
	}

	/**
	 * returns locale date/time pattern
	 *
	 * @thisDateFormat FULL=0, LONG=1, MEDIUM=2, SHORT=3
	 * @thisTimeFormat FULL=0, LONG=1, MEDIUM=2, SHORT=3
	 */
	string function getDateTimePattern( numeric thisDateFormat = 1, numeric thisTimeFormat = 3 ){
		var tDateFormat    = javacast( "int", arguments.thisDateFormat );
		var tTimeFormat    = javacast( "int", arguments.thisTimeFormat );
		var tDateFormatter = variables.aDateFormat.getDateTimeInstance(
			tDateFormat,
			tTimeFormat,
			buildLocale( getfwLocale() )
		);
		return tDateFormatter.toPattern();
	}

	/**
	 * formats a date/time to given pattern
	 *
	 * @thisOffset 
	 * @thisPattern
	 * @tz         
	 */
	string function formatDateTime(
		required numeric thisOffset,
		required string thisPattern,
		tz = variables.timeZone.getDefault().getID()
	){
		var tDateFormatter = variables.aDateFormat.getDateTimeInstance(
			variables.aDateFormat.LONG,
			variables.aDateFormat.LONG,
			buildLocale( getfwLocale() )
		);
		tDateFormatter.applyPattern( arguments.thisPattern );
		return tDateFormatter.format( arguments.thisOffset );
	}

	/**
	 * Determines the first DOW.
	 */
	string function weekStarts(){
		return variables.aCalendar.getFirstDayOfWeek();
	}

	/**
	 * Returns localized year, probably only useful for BE calendars like in thailand, etc.
	 *
	 * @thisYear
	 */
	string function getLocalizedYear( required numeric thisYear ){
		var thisDF = createObject( "java", "java.text.SimpleDateFormat" ).init(
			"yyyy",
			buildLocale( getfwLocale() )
		);
		return thisDF.format( createDate( arguments.thisYear, 1, 1 ) );
	}

	/**
	 * Returns localized month.
	 *
	 * @month
	 */
	string function getLocalizedMonth( required numeric month ){
		var thisDF = createObject( "java", "java.text.SimpleDateFormat" ).init(
			"MMMM",
			buildLocale( getfwLocale() )
		);
		return thisDF.format( createDate( 1999, arguments.month, 1 ) );
	}

	/**
	 * Facade to getShortWeedDays. For compatability
	 */
	function getLocalizedDays(){
		return getShortWeekDays();
	}

	/**
	 * returns short day names for this calendar
	 *
	 * @calendarOrder
	 */
	array function getShortWeekDays( boolean calendarOrder = true ){
		var theseDateSymbols = createObject( "java", "java.text.DateFormatSymbols" ).init(
			buildLocale( getFWLocale() )
		);
		// array of days, sunday =1 saturday =7
		var localeDays = listToArray( arrayToList( theseDateSymbols.getShortWeekDays() ) );
		if ( !arguments.calendarOrder ) {
			return localeDays;
		} else {
			switch ( weekStarts( buildLocale( getFWLocale() ) ) ) {
				case 1:
					return localeDays;
				case 2:
					// move sunday to last
					localeDays.append( localeDays[ 1 ] );
					localeDays.deleteAt( 1 );
					return localeDays;
				case 7:
					// move saturday to first
					localeDays.prepend( localeDays[ 7 ] );
					localeDays.deleteAt( 8 );
					return localeDays;
			}
		}
	}

	/**
	 * returns year from epoch offset
	 *
	 * @thisOffset java epoch offset
	 * @tz        
	 */
	numeric function getYear( required numeric thisOffset, tz = variables.timeZone.getDefault().getID() ){
		var thisTZ    = variables.timeZone.getTimeZone( arguments.tZ );
		var aCalendar = createObject( "java", "java.util.GregorianCalendar" ).init( buildLocale() );
		aCalendar.setTimeInMillis( arguments.thisOffset );
		aCalendar.setTimeZone( thisTZ );
		return aCalendar.get( aCalendar.YEAR );
	}

	/**
	 * returns month from epoch offset
	 *
	 * @thisOffset java epoch offset
	 * @tz        
	 */
	numeric function getMonth( required numeric thisOffset, tz = variables.timeZone.getDefault().getID() ){
		var thisTZ    = variables.timeZone.getTimeZone( arguments.tZ );
		var aCalendar = createObject( "java", "java.util.GregorianCalendar" ).init( buildLocale() );
		aCalendar.setTimeInMillis( arguments.thisOffset );
		aCalendar.setTimeZone( thisTZ );
		return aCalendar.get( aCalendar.MONTH ) + 1; // --- java months start at 0
	}

	/**
	 * returns day from epoch offset
	 *
	 * @thisOffset java epoch offset
	 * @tz        
	 */
	numeric function getDay( required numeric thisOffset, tz = variables.timeZone.getDefault().getID() ){
		var thisTZ    = variables.timeZone.getTimeZone( arguments.tZ );
		var aCalendar = createObject( "java", "java.util.GregorianCalendar" ).init( buildLocale() );
		aCalendar.setTimeInMillis( arguments.thisOffset );
		aCalendar.setTimeZone( thisTZ );
		return aCalendar.get( aCalendar.DATE );
	}

	/**
	 * returns hour of day, 24 hr format, from epoch offset
	 *
	 * @thisOffset java epoch offset
	 * @tz        
	 */
	numeric function getHour( required numeric thisOffset, tz = variables.timeZone.getDefault().getID() ){
		var thisTZ    = variables.timeZone.getTimeZone( arguments.tZ );
		var aCalendar = createObject( "java", "java.util.GregorianCalendar" ).init( buildLocale() );
		aCalendar.setTimeInMillis( arguments.thisOffset );
		aCalendar.setTimeZone( thisTZ );
		return aCalendar.get( aCalendar.HOUR_OF_DAY );
	}

	/**
	 * returns minute from epoch offset
	 *
	 * @thisOffset java epoch offset
	 * @tz        
	 */
	numeric function getMinute( required numeric thisOffset, tz = variables.timeZone.getDefault().getID() ){
		var thisTZ    = variables.timeZone.getTimeZone( arguments.tZ );
		var aCalendar = createObject( "java", "java.util.GregorianCalendar" ).init( buildLocale() );
		aCalendar.setTimeInMillis( arguments.thisOffset );
		aCalendar.setTimeZone( thisTZ );
		return aCalendar.get( aCalendar.MINUTE );
	}

	/**
	 * returns second from epoch offset
	 *
	 * @thisOffset java epoch offset
	 * @tz        
	 */
	numeric function getSecond( required numeric thisOffset, tz = variables.timeZone.getDefault().getID() ){
		var thisTZ    = variables.timeZone.getTimeZone( arguments.tZ );
		var aCalendar = createObject( "java", "java.util.GregorianCalendar" ).init( buildLocale() );
		aCalendar.setTimeInMillis( arguments.thisOffset );
		aCalendar.setTimeZone( thisTZ );
		return aCalendar.get( aCalendar.SECOND );
	}

	/**
	 * converts datetime to java epoch offset
	 *
	 * @thisDate datetime to convert to java epoch
	 */
	numeric function toEpoch( required date thisDate ){
		return arguments.thisDate.getTime();
	}

	/**
	 * converts java epoch offset to datetime
	 *
	 * @thisOffset java epoch offset to convert to datetime
	 */
	date function fromEpoch( required numeric thisOffset ){
		var aCalendar = createObject( "java", "java.util.GregorianCalendar" ).init( buildLocale() );
		aCalendar.setTimeInMillis( arguments.thisOffset );
		return aCalendar.getTime();
	}

	/**
	 * returns an array of timezones available on this server
	 */
	array function getAvailableTZ(){
		return variables.timeZone.getAvailableIDs();
	}

	/**
	 * determines if a given timezone uses DST
	 *
	 * @tz
	 */
	boolean function usesDST( tz = variables.timeZone.getDefault().getID() ){
		return variables.timeZone.getTimeZone( arguments.tz ).useDaylightTime();
	}

	/**
	 * returns rawoffset in hours
	 *
	 * @tz
	 */
	numeric function getRawOffset( tz = variables.timeZone.getDefault().getID() ){
		var thisTZ = variables.timeZone.getTimeZone( arguments.tZ );
		return thisTZ.getRawOffset() / 3600000;
	}

	/**
	 * returns DST savings in hours
	 *
	 * @tz
	 */
	numeric function getDST( thisTZ = variables.timeZone.getDefault().getID() ){
		var tZ = variables.timeZone.getTimeZone( arguments.thisTZ );
		return tZ.getDSTSavings() / 3600000;
	}

	/**
	 * returns a list of timezones available on this server for a given raw offset
	 *
	 * @thisOffset
	 */
	array function getTZByOffset( required numeric thisOffset ){
		var rawOffset = javacast( "long", arguments.thisOffset * 3600000 );
		return variables.timeZone.getAvailableIDs( rawOffset );
	}

	/**
	 * returns server TZ
	 */
	function getServerTZ(){
		var serverTZ = variables.timeZone.getDefault();
		return serverTZ.getDisplayName( true, variables.timeZone.LONG );
	}

	/**
	 * determines if a given date in a given timezone is in DST
	 *
	 * @thisOffset
	 * @tzToTest  
	 */
	boolean function inDST( requred numeric thisOffset, tzToTest = variables.timeZone.getDefault().getID() ){
		var thisTZ    = variables.timeZone.getTimeZone( arguments.tzToTest );
		var aCalendar = createObject( "java", "java.util.GregorianCalendar" ).init( buildLocale() );
		aCalendar.setTimeInMillis( arguments.thisOffset );
		aCalendar.setTimezone( thisTZ );
		return thisTZ.inDaylightTime( aCalendar.getTime() );
	}

	/**
	 * returns the offset in hours for the given datetime in the specified timezone
	 *
	 * @thisDate
	 * @thisTz  
	 */
	function getTZOffset( required date thisDate, thisTZ = variables.timeZone.getDefault().getID() ){
		var tZ = variables.timeZone.getTimeZone( arguments.thisTZ );
		return tZ.getOffset( arguments.thisDate ) / 3600000;
	}

	/**
	 * DateAdd
	 *
	 * @thisOffset  
	 * @thisDatePart
	 * @dateUnits   
	 * @thisTZ      
	 */
	numeric function dateAdd(
		required numeric thisOffset,
		required string thisDatePart,
		required numeric dateUnits,
		thisTZ = variables.timeZone.getDefault().getID()
	){
		var dPart     = "";
		var tZ        = variables.timeZone.getTimeZone( arguments.thisTZ );
		var aCalendar = createObject( "java", "java.util.GregorianCalendar" ).init( buildLocale() );
		switch ( arguments.thisDatepart ) {
			case "y":
			case "yr":
			case "yyyy":
			case "year":
				dPart = aCalendar.YEAR;
				break;
			case "m":
			case "month":
				dPart = aCalendar.MONTH;
				break;
			case "w":
			case "week":
				dPart = aCalendar.WEEK_OF_MONTH;
				break;
			case "d":
			case "day":
				dPart = aCalendar.DATE;
				break;
			case "h":
			case "hr":
			case "hour":
				dPart = aCalendar.HOUR;
				break;
			case "n":
			case "minute":
				dPart = aCalendar.MINUTE;
				break;
			case "s":
			case "second":
				dPart = aCalendar.SECOND;
				break;
		}
		aCalendar.setTimeInMillis( arguments.thisOffset );
		aCalendar.setTimezone( tZ );
		aCalendar.add( dPart, javacast( "int", arguments.dateUnits ) );
		return aCalendar.getTimeInMillis();
	}

	/**
	 * DateDiff
	 *
	 * @thisOffset  
	 * @thatOffset  
	 * @thisDatePart
	 * @thisTZ      
	 */
	numeric function dateDiff(
		required numeric thisOffset,
		required numeric thatOffset,
		required string thisDatePart,
		thisTZ = variables.timeZone.getDefault().getID()
	){
		var dPart     = "";
		var elapsed   = 0;
		var before    = createObject( "java", "java.util.GregorianCalendar" );
		var after     = createObject( "java", "java.util.GregorianCalendar" );
		var tZ        = variables.timeZone.getTimeZone( arguments.thisTZ );
		var e         = 0;
		var s         = 0;
		var direction = 1;
		// lets shortcut first
		if ( arguments.thisOffset EQ arguments.thatOffset ) return 0;
		else {
			// setup calendars to test
			// which offset came first
			if ( arguments.thisOffset LT arguments.thatOffset ) {
				before.setTimeInMillis( arguments.thisOffset );
				after.setTimeInMillis( arguments.thatOffset );
				before.setTimezone( tZ );
				after.setTimezone( tZ );
			} else {
				before.setTimeInMillis( arguments.thatOffset );
				after.setTimeInMillis( arguments.thisOffset );
				before.setTimezone( tZ );
				after.setTimezone( tZ );
				direction = -1;
			}

			switch ( arguments.thisDatepart ) {
				case "y":
				case "yr":
				case "yyyy":
				case "year":
					dPart = variables.aCalendar.YEAR;
					before.clear( variables.aCalendar.DATE );
					after.clear( variables.aCalendar.DATE );
					before.clear( variables.aCalendar.MONTH );
					after.clear( variables.aCalendar.MONTH );
					break;
				case "m":
				case "month":
					dPart = variables.aCalendar.MONTH;
					before.clear( variables.aCalendar.DATE );
					after.clear( variables.aCalendar.DATE );
					break;
				case "w":
				case "week":
					dPart = variables.aCalendar.WEEK_OF_YEAR;
					before.clear( variables.aCalendar.DATE );
					after.clear( variables.aCalendar.DATE );
					break;
				case "d":
				case "day":
					// very much a special case
					e = after.getTimeInMillis() + after.getTimeZone().getOffset( after.getTimeInMillis() );
					s = before.getTimeInMillis() + before.getTimeZone().getOffset( before.getTimeInMillis() );
					return int( ( e - s ) / 86400000 ) * direction;
					break;
				case "h":
				case "hr":
				case "hour":
					e = after.getTimeInMillis() + after.getTimeZone().getOffset( after.getTimeInMillis() );
					s = before.getTimeInMillis() + before.getTimeZone().getOffset( before.getTimeInMillis() );
					return int( ( e - s ) / 3600000 ) * direction;
					break;
				case "n":
				case "minute":
					e = after.getTimeInMillis() + after.getTimeZone().getOffset( after.getTimeInMillis() );
					s = before.getTimeInMillis() + before.getTimeZone().getOffset( before.getTimeInMillis() );
					return int( ( e - s ) / 60000 ) * direction;
					break;
				case "s":
				case "second":
					e = after.getTimeInMillis() + after.getTimeZone().getOffset( after.getTimeInMillis() );
					s = before.getTimeInMillis() + before.getTimeZone().getOffset( before.getTimeInMillis() );
					return int( ( e - s ) / 1000 ) * direction;
					break;
			}
			// datepart switch

			while ( before.before( after ) ) {
				before.add( dPart, 1 );
				elapsed = elapsed + 1;
			}
			// count dateparts
			return elapsed * direction;
		}
		// if start & end times are the same
	}

	/**
	 * returns a sorted query of locales (locale,country,language,dspName,localname. 'localname' will contain the locale's name in its native characters). Suitable for use in creating select lists.
	 */
	query function getLocaleQuery(){
		var qryLocale = queryNew( "locale,country,language,dspName,localname" );
		for ( var localeItem in getLocales() ) {
			qryLocale.addRow( {
				"locale"    : localeItem.toString(),
				"localname" : ( left( localeItem, 2 ) == "ar" || left( localeItem, 2 ) == "iw" ) ? chr( 8235 ) & localeItem.getDisplayName(
					localeItem
				) & chr( 8234 ) : localeItem.getDisplayName( localeItem ),
				"dspName"  : localeItem.getDisplayName(),
				"language" : localeItem.getDisplayLanguage(),
				"country"  : localeItem.getDisplayCountry()
			} );
		};
		return qryLocale.sort( function( rowA, rowB ){
			if ( compare( rowA.locale, rowB.locale ) == 0 ) {
				// if locale=equal, further sort on langugage
				return compare( rowA.language, rowB.language );
			} else {
				return compare( rowA.dspName, rowB.dspName );
			}
		} );
	}

	/**
	 * returns a sorted query of timezones, optionally filters for only unique display names (fields:id,offset,dspName,longname,shortname,usesDST). Suitable for use in creating select lists.
	 *
	 * @returnUnique
	 */
	query function getTZQuery( required boolean returnUnique ){
		var aTZID         = getAvailableTZ();
		var stNames       = {};
		var qryTZ         = queryNew( "id,offset,dspName,longname,shortname,usesDST" );
		var fReturnUnique = arguments.returUnique; // not necessary but no arguments issues in each()
		var tmpName       = "";
		aTZID.each( function( timeZone ){
			tmpName = getTZDisplayName( timeZone );
			if ( !fReturnUnique || ( fReturnUnique && !structKeyExists( stNames, tmpname ) ) ) {
				qryTZ.addRow( 1 );
				qryTZ.setCell( "id", timeZone );
				qryTZ.setCell( "offset", getRawOffset( timeZone ) );
				qryTZ.setCell( "dspName", tmpName );
				qryTZ.setCell( "longname", getTZDisplayName( timeZone, "long" ) );
				qryTZ.setCell( "shortname", getTZDisplayName( timeZone, "short" ) );
				qryTZ.setCell( "usesDST", usesDST( timeZone ) );
			}
		} );
		return qryTZ.sort( function( rowA, rowB ){
			if ( compare( rowA.offset, rowB.offset ) == 0 ) {
				// if locale=equal, further sort on langugage
				return compare( rowA.dspname, rowB.dspname );
			} else {
				return compare( rowA.offset, rowB.offset );
			}
		} );
	}

	/**
	 * returns the display name of the timezone requested in either long, short, or default style
	 *
	 * @thisTZ 
	 * @dspType
	 */
	string function getTZDisplayName( thisTZ = variables.timeZone.getDefault().getID(), string dspType = "" ){
		var tZ = variables.timeZone.getTimeZone( arguments.thisTZ );
		switch ( arguments.dspType ) {
			case "long":
				return tZ.getDisplayName( javacast( "boolean", false ), javacast( "int", 1 ) );
				// break;
			case "short":
				return tZ.getDisplayName( javacast( "boolean", false ), javacast( "int", 0 ) );
				// break;
			default:
				return tZ.getDisplayName();
		}
	}
	/************************************************************************************/
	/****************************** PRIVATE METHODS *************************************/
	/************************************************************************************/


	/**
	 * creates valid core java locale from java style locale ID
	 *
	 * @thisLocale
	 *
	 * @return valid Java locale
	 *
	 * @throws i18n.InvalidLocaleException if locale is not valid
	 */
	private function buildLocale( string thisLocale = "en_US" ){
		var l       = listFirst( arguments.thisLocale, "_" );
		var c       = "";
		var v       = "";
		var aLocale = createObject( "java", "java.util.Locale" );
		var tLocale = aLocale.getDefault(); // if we fail fallback on server default

		// Check locale
		if ( not isValidLocale( arguments.thisLocale ) ) {
			throw(
				message: "Specified locale must be of the form language_COUNTRY_VARIANT where language, country and variant are 2 characters each, ISO 3166 standard.",
				detail : "The locale tested is: #arguments.thisLocale#",
				type   : "i18n.InvalidLocaleException"
			);
		}

		switch ( listLen( arguments.thisLocale, "_" ) ) {
			case 1:
				tLocale = aLocale.init( l );
				break;
			case 2:
				c       = listLast( arguments.thisLocale, "_" );
				tLocale = aLocale.init( l, c );
				break;
			case 3:
				c       = listGetAt( arguments.thisLocale, 2, "_" );
				v       = listLast( arguments.thisLocale, "_" );
				tLocale = aLocale.init( l, c, v );
				break;
		}
		return tLocale;
	}

}
