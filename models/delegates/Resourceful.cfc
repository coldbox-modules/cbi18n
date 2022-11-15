/**
 * Copyright Since 2005 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * This delegate adds resource capabilities to models
 */
component singleton {

	// Delegations
	property
		name    ="resourceService"
		inject  ="resourceService@cbi18n"
		delegate="getResource";

}
