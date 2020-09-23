component extends="coldbox.system.ioc.config.Binder"{
	
	/**
	* Configure WireBox, that's it!
	*/
	function configure(){
		
		// The WireBox configuration structure DSL
		wireBox = {
			// Scope registration, automatically register a wirebox injector instance on any CF scope
			// By default it registeres itself on application scope
			scopeRegistration = {
				enabled = true,
				scope   = "application", // server, cluster, session, application
				key		= "wireBox"
			},

			// DSL Namespace registrations
			customDSL = {
				// namespace = "mapping name"
			},
			
			// Custom Storage Scopes
			customScopes = {
				// annotationName = "mapping name"
			},
			
			// Package scan locations
			scanLocations = [],
			
			// Stop Recursions
			stopRecursions = [],
			
			// Parent Injector to assign to the configured injector, this must be an object reference
			parentInjector = "",
			
			// Register all event listeners here, they are created in the specified order
			listeners = [
				// { class="", name="", properties={} }
			]			
		};
		
		// Map Bindings below

		// extra instance for ResourceService, but now based on JSON resources.
		map("JsonResourceService").to("cbi18n.models.ResourceService")
			.initWith( settings={
				defaultResourceBundle = "",
				resourceBundles = {
					"jsonTest" = "includes/i18n/jsonTest",
					"nestedJsonTest" = "includes/i18n/nestedJsonTest"
				},
				defaultLocale = "en_US",
				localeStorage = "cookieStorage@cbstorages",
				unknownTranslation = "**NOT FOUND**",
				logUnknownTranslation = true,
				resourceType="json"
			});
	}	
}