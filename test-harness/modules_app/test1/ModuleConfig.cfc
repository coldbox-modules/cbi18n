<cfcomponent output="false" hint="My App Configuration">
<cfscript>
	// Module Properties
	this.title 				= "My Test Module";
	this.author 			= "Luis Majano";
	this.webURL 			= "http://www.coldbox.org";
	this.description 		= "A funky test module";
	// If true, looks for views in the parent first, if not found, then in the module. Else vice-versa
	this.viewParentLookup 	= true;
	// If true, looks for layouts in the parent first, if not found, then in module. Else vice-versa
	this.layoutParentLookup = true;
	this.entryPoint			= "test1";
	// CFML Mapping for this module, the path will be the module root. If empty, none is registered.
	this.cfmapping			= "test1";

	function configure(){

		// SES Routes
		routes = [
			{ pattern="/", handler="test",action="index" },
			{ pattern="/:handler/:action?" }
		];

		// i18n
		i18n = {
			defaultLocale = "es_SV",
			resourceBundles = {
				"module@test1" = "#moduleMapping#/includes/module"
			}
		};

	}

	function onLoad(){
	}

	function onUnload(){
	}
</cfscript>
</cfcomponent>