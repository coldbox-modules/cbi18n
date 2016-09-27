<cfcomponent hint="reads resource bundles from database"
			 extends="cbi18n.models.ResourceService"
			 output="false"
			 cache="true"
			 cachetimeout="0"
			 singleton>
	<cfproperty name="controller" inject="coldbox">
	
	<cffunction name="getResourceBundle" access="public" returntype="any" output="false">
		<cfargument name="rbFile"   required="true"   type="any" hint="This must be the path + filename UP to but NOT including the locale. We auto-add the local and .properties to the end.">
		<cfargument name="rbLocale" required="false"  type="any" default="en_US" hint="The locale of the resource bundle">
		<cfscript>
			var resourceBundle =structNew();
			var thisKEY = "";
			var thisMSG = "";
			var keys = "";
			var rbFilePath = arguments.rbFile & iif( len( arguments.rbLocale ), de("_"), de("") ) & arguments.rbLocale & ".properties";
			var rbFullPath = rbFilePath;
			var fis = "";
			var fir = "";
			var rb = "";

			// Try to locate the path using the coldbox plugin utility
			rbFullPath = variables.controller.locateFilePath( rbFilePath );

			// If we don't have a file, check the "database"  ( this is the extent of our overload to the core ResourceService )
			if( !len( rbFullPath ) ){

				var resourceQuery = getCustomResourceQuery();

				var qResource = new query();
				qResource.setDBType( "query" );
				qResource.setAttributes(resourceQuery=resourceQuery);
				qResource.addParam( name="locale", value=arguments.rbLocale, cfsqltype="cf_sql_varchar" );
				var sql = "SELECT name,value FROM resourceQuery WHERE locale = :locale";
				var qResourceBundle = qResource.execute( sql=sql ).getResult();

				for( var row in qResourceBundle ){
					resourceBundle[row.name] = row.value;
				}

			} else {
				//create a file input stream with file location
				fis = createObject( "java", "java.io.FileInputStream" ).init( rbFullPath );
				fir = createObject( "java", "java.io.InputStreamReader" ).init( fis, "UTF-8" )
				//Init RB with file Stream
				rb = createObject( "java", "java.util.PropertyResourceBundle").init( fir );
				try{
					//Get Keys
					keys = rb.getKeys();

					//Loop through property keys and store the values into bundle
					while( keys.hasMoreElements() ){
						thisKEY = keys.nextElement();
						resourceBundle[ thisKEY ] = rb.handleGetObject( thisKEY );
					}

				}
				catch(Any e){
					fis.close();
					$rethrow( e );
				}

				// Close the input stream
				fis.close();	
			}

			return resourceBundle;
		</cfscript>
	</cffunction>


	<cffunction name="getCustomResourceQuery" access="private" output="false" returntype="query" hint="I return a custom resource bundle query to emulate an interation with a DB">
		<cfscript>
			var resourceQuery = queryNew( "locale,name,value" );
			var row1 = queryAddRow( resourceQuery );
			querySetCell( resourceQuery, "locale", "en_US", row1 );
			querySetCell( resourceQuery, "name", "welcome", row1 );
			querySetCell( resourceQuery, "value", "Welcome to my awesome multi-lingual app using a custom Resource Service", row1 );

			var row2 = queryAddRow( resourceQuery );
			querySetCell( resourceQuery, "locale", "en_SV", row2 );
			querySetCell( resourceQuery, "name", "welcome", row2 );
			querySetCell( resourceQuery, "value", "Bienvenido a mi aplicación en varios idiomas impresionante uso de un Servicio de Recursos de encargo", row2 );
		
			return resourceQuery;
		</cfscript>

	</cffunction>

	
</cfcomponent>