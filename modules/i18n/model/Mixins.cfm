<!--- Discover fw Locale --->
<cffunction name="getfwLocale" access="public" output="false" returnType="any" hint="Get the user's currently set locale or default locale">
	<cfscript>
		if(NOT structKeyExists( variables,"cbox18n" ) ){
			variables.cbox18n = getInstance( "i18n@i18n" );
		}
		return variables.cbox18n.getfwLocale();
	</cfscript>
</cffunction>

<!--- set the fw locale for a user --->
<cffunction name="setfwLocale" access="public" output="false" returnType="any" hint="Set the default locale to use in the framework for a specific user. Utility Method">
	<cfargument name="locale"     		type="any"  required="false"  hint="The locale to change and set. Must be Java Style: en_US">
	<cfargument name="dontloadRBFlag" 	type="any" 	required="false"  hint="Flag to load the resource bundle for the specified locale (If not already loaded) or just change the framework's locale. Boolean" colddoc:generic="Boolean">
	<cfscript>
		if(NOT structKeyExists( variables,"cbox18n" ) ){
			variables.cbox18n = getInstance( "i18n@i18n" );
		}
		return variables.cbox18n.setfwLocale( argumentCollection=arguments );
	</cfscript>
</cffunction>

<!--- Get a Resource --->
<cffunction name="getResource" access="public" output="false" returnType="any" hint="Facade to i18n.getResource. Returns a string.">
	<cfargument name="resource" type="any" required="true"  hint="The resource (key) to retrieve from the main loaded bundle.">
	<cfargument name="default"  type="any" required="false" hint="A default value to send back if the resource (key) not found" >
	<cfargument name="locale"   type="any" required="false" hint="Pass in which locale to take the resource from. By default it uses the user's current set locale" >
	<cfargument name="values" 	type="any" required="false" hint="An array, struct or simple string of value replacements to use on the resource string"/>
	<cfargument name="bundle" 	type="any" required="false"	hint="The bundle alias to use to get the resource from when using multiple resource bundles. By default the bundle name used is 'default'">
	<cfscript>
		// check for resource@bundle convention:
		if( find( "@", arguments.resource ) ){
			arguments.bundle 	= listLast( arguments.resource, "@" );
			arguments.resource 	= listFirst( arguments.resource, "@" );
		}
		// Verify injection
		if( NOT structKeyExists( variables, "cboxResourceService" ) ){
			variables.cboxResourceService = getInstance( "resourceService@i18n" );
		}
		// return resource info
		return variables.cboxResourceService.getResource( argumentCollection=arguments );
	</cfscript>
</cffunction>

<!--- Get a Resource --->
<cffunction name="$r" access="public" output="false" returnType="any" hint="Facade to i18n.getResource. Returns a string.">
	<cfargument name="resource" type="any" required="true"  hint="The resource (key) to retrieve from the main loaded bundle.">
	<cfargument name="default"  type="any" required="false" hint="A default value to send back if the resource (key) not found" >
	<cfargument name="locale"   type="any" required="false" hint="Pass in which locale to take the resource from. By default it uses the user's current set locale" >
	<cfargument name="values" 	type="any" required="false" hint="An array, struct or simple string of value replacements to use on the resource string"/>
	<cfargument name="bundle" 	type="any" required="false"	hint="The bundle alias to use to get the resource from when using multiple resource bundles. By default the bundle name used is 'default'">
	<cfscript>
		return this.getResource( argumentCollection=arguments );
	</cfscript>
</cffunction>