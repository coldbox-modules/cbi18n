component{

	// Configure ColdBox Application
	function configure(){

		// coldbox directives
		coldbox = {
			//Application Setup
			appName 				= "Module Tester",

			//Development Settings
			reinitPassword			= "",
			handlersIndexAutoReload = true,
			modulesExternalLocation = [],

			//Implicit Events
			defaultEvent			= "",
			requestStartHandler		= "",
			requestEndHandler		= "",
			applicationStartHandler = "",
			applicationEndHandler	= "",
			sessionStartHandler 	= "",
			sessionEndHandler		= "",
			missingTemplateHandler	= "",

			//Error/Exception Handling
			exceptionHandler		= "",
			onInvalidEvent			= "",
			customErrorTemplate 	= "/coldbox/system/includes/BugReport.cfm",

			//Application Aspects
			handlerCaching 			= false,
			eventCaching			= false
		};

		// environment settings, create a detectEnvironment() method to detect it yourself.
		// create a function with the name of the environment so it can be executed if that environment is detected
		// the value of the environment is a list of regex patterns to match the cgi.http_host.
		environments = {
			development = "localhost,127\.0\.0\.1"
		};

		//Register interceptors as an array, we need order
		interceptors = [
		];

		//i18n & Localization
		i18n = {
			defaultResourceBundle = "includes/i18n/main",
			resourceBundles = {
				"support" = "includes/i18n/support"
			},
			defaultLocale = "en_US",
			localeStorage = "cookie",
			unknownTranslation = "**NOT FOUND**",
			logUnknownTranslation = true,
//			customResourceService = "root.models.CustomResourceService"
		};

		//LogBox DSL
		logBox = {
			// Define Appenders
			appenders = {
				files={class="coldbox.system.logging.appenders.RollingFileAppender",
					properties = {
						filename = "tester", filePath="/#appMapping#/logs"
					}
				}
			},
			// Root Logger
			root = { levelmax="DEBUG", appenders="*" },
			// Implicit Level Categories
			info = [ "coldbox.system" ]
		};

	}

	/**
	 * Load the Module you are testing
	 */
	function afterConfigurationLoad( event, interceptData, rc, prc ){
		controller.getModuleService()
			.registerAndActivateModule(
				moduleName 		= request.MODULE_NAME,
				invocationPath 	= "moduleroot"
			);
	}

}