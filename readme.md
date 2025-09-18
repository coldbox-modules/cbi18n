[![Total Downloads](https://forgebox.io/api/v1/entry/cbi18n/badges/downloads)](https://forgebox.io/view/cbi18n)
[![Latest Stable Version](https://forgebox.io/api/v1/entry/cbi18n/badges/version)](https://forgebox.io/view/cbi18n)
[![Apache2 License](https://img.shields.io/badge/License-Apache2-blue.svg)](https://forgebox.io/view/cbi18n)

<p align="center">
	<img src="https://www.ortussolutions.com/__media/coldbox-185-logo.png" alt="ColdBox Platform Logo">
</p>

<p align="center">
	Copyright Since 2005 ColdBox Platform by Luis Majano and Ortus Solutions, Corp
	<br>
	<a href="https://www.coldbox.org">www.coldbox.org</a> |
	<a href="https://www.ortussolutions.com">www.ortussolutions.com</a>
</p>

# CBi18n - Internationalization & Localization for ColdBox

Professional internationalization (i18n) and localization support for ColdBox applications. CBi18n provides a comprehensive solution for building multilingual applications with support for both traditional Java `.properties` files and modern JSON resource bundles.

## 🌟 Features

- **Multi-Format Support**: Java `.properties` and JSON resource bundles
- **Dynamic Locale Switching**: Change user locales on-the-fly with persistent storage
- **Hierarchical Modules**: Each ColdBox module can have its own resource bundles
- **Storage Integration**: Leverages CBStorages for locale persistence (session, cookie, cache)
- **Thread-Safe Loading**: Concurrent resource bundle loading with named locks
- **Placeholder Support**: Dynamic value replacement in localized strings
- **Event-Driven**: Emits interceptor events for missing translations
- **Convention-Based**: Minimal configuration with sensible defaults
- **Global Helpers**: Convenient functions available in all ColdBox components

## 💻 Requirements

- **BoxLang**: 1.0+
- **Lucee**: 5.0+
- **Adobe ColdFusion**: 2023+
- **ColdBox Platform**: 6.0+
- **CBStorages**: 3.0+ (automatically installed as dependency)

## ⚡ Quick Start

### 1. Installation

```bash
# Install via CommandBox
box install cbi18n
```

### 2. Basic Configuration

```javascript
// config/ColdBox.cfc
moduleSettings = {
    cbi18n: {
        defaultResourceBundle: "includes/i18n/main",
        defaultLocale: "en_US",
        localeStorage: "cookieStorage@cbstorages",
        unknownTranslation: "**NOT FOUND**"
    }
};
```

### 3. Create Resource Files

```bash
# Create your resource bundle files
# includes/i18n/main_en_US.properties
user.welcome=Welcome {1}!
user.logout=Logout

# includes/i18n/main_es_ES.properties
user.welcome=¡Bienvenido {1}!
user.logout=Cerrar Sesión
```

### 4. Use in Your Application

```javascript
// In handlers, views, layouts
var welcomeMsg = getResource("user.welcome", "", "", ["John"]);
// Or use the shorthand
var logoutText = $r("user.logout");

// Change user's locale dynamically
setFWLocale("es_ES");
```

## 🔧 WireBox Mappings

CBi18n automatically registers the following models in WireBox:

| Service | WireBox ID | Description |
|---------|------------|-------------|
| **i18n Service** | `i18n@cbi18n` | Main service for locale management and resource retrieval |
| **Resource Service** | `resourceService@cbi18n` | Handles resource bundle loading and parsing |

### Custom Resource Service

You can override the default ResourceService by providing a `customResourceService` in your configuration:

```javascript
moduleSettings = {
    cbi18n: {
        customResourceService: "MyCustomResourceService@mymodule"
    }
};
```

For more information, see [Custom Resource Services](https://coldbox-i18n.ortusbooks.com/coding-for-i18n/custom-resource-services).

## ⚙️ Configuration

Configure CBi18n in your `config/ColdBox.cfc` under `moduleSettings`:

```javascript
moduleSettings = {
    cbi18n: {
        // The base path of the default resource bundle to load
        // Path + resource name but excluding _locale.extension
        defaultResourceBundle: "includes/i18n/main",

        // The default locale of the application (Java format: lang_COUNTRY)
        defaultLocale: "en_US",

        // Storage service for user's locale persistence
        // Use any CBStorages service with full WireBox ID
        localeStorage: "cookieStorage@cbstorages",

        // Text displayed when a translation is not found
        unknownTranslation: "**NOT FOUND**",

        // Enable logging of missing translations to LogBox
        logUnknownTranslation: true,

        // Additional resource bundles to load
        resourceBundles: {
            "admin": "modules/admin/includes/i18n/admin",
            "emails": "includes/i18n/emails"
        },

        // Custom ResourceService implementation (optional)
        customResourceService: ""
    }
};
```

### Module-Specific Configuration

Each ColdBox module can have its own resource bundles. Configure them in your `ModuleConfig.cfc`:

```javascript
function configure(){
    cbi18n = {
        defaultLocale: "es_SV",
        resourceBundles: {
            // Alias => path within module
            "module@mymodule": "#moduleMapping#/includes/i18n/module"
        }
    };
}
```

### Storage Options

Leverage any CBStorages service for locale persistence:

- `cookieStorage@cbstorages` - Browser cookies (default)
- `sessionStorage@cbstorages` - Server session
- `cacheStorage@cbstorages` - Distributed cache
- `clientStorage@cbstorages` - Client variables

## 📖 Usage Examples

### Basic Resource Retrieval

```javascript
// Simple resource lookup
var message = getResource("welcome.message");

// With default value
var title = getResource("page.title", "Default Title");

// Using shorthand alias
var error = $r("validation.required");
```

### Dynamic Value Replacement

```javascript
// Resource: user.greeting=Hello {1}, you have {2} messages
var greeting = getResource(
    "user.greeting",
    "",
    "",
    ["John", "5"]
); // Returns: "Hello John, you have 5 messages"
```

### Locale Management

```javascript
// Get current user's locale
var currentLocale = getFWLocale(); // e.g., "en_US"

// Change user's locale (automatically loads resource bundles)
setFWLocale("es_ES");

// Get resource in specific locale
var spanishTitle = getResource("page.title", "", "es_ES");
```

### Working with Multiple Bundles

```javascript
// Get resource from specific bundle
var adminMsg = getResource("dashboard.title", "", "", [], "admin");

// Bundle structure in memory:
// {
//   "default": { "en_US": {...}, "es_ES": {...} },
//   "admin": { "en_US": {...}, "es_ES": {...} }
// }
```

### File Format Examples

#### Java Properties Format

```properties
# main_en_US.properties
user.welcome=Welcome {1}!
user.logout=Logout
error.required=This field is required
```

#### JSON Format

```json
# main_en_US.json
{
  "user": {
    "welcome": "Welcome {1}!",
    "logout": "Logout"
  },
  "error": {
    "required": "This field is required"
  }
}
```

## 🔗 Interceptors

This module announces an `onUnknownTranslation` interception. The `data` announced is a struct with the following format:

```js
{
	resource 	= ...,
	locale 		= ... ,
	bundle  	= ...
}
```

## 🛠️ Global Helper Functions

CBi18n injects the following helper functions into all ColdBox components (handlers, views, layouts, interceptors):

### Locale Management

```javascript
/**
 * Get the user's currently set locale or default locale
 * @return string Current locale (e.g., "en_US")
 */
function getFWLocale()

/**
 * Set the locale for a specific user
 * @locale The locale to set (Java format: en_US)
 * @dontLoadRBFlag Skip loading resource bundle for the locale
 * @return i18n Service instance
 */
function setFWLocale(string locale="", boolean dontloadRBFlag=false)
```

### Resource Retrieval

```javascript
/**
 * Retrieve a resource from a resource bundle with replacements
 * @resource The resource key to retrieve
 * @defaultValue Default value if resource not found
 * @locale Specific locale to use (defaults to user's locale)
 * @values Array/struct/string of replacement values
 * @bundle Bundle alias for multiple resource bundles
 * @return string Localized resource string
 */
function getResource(
    required resource,
    defaultValue,
    locale,
    values,
    bundle
)

// Shorthand alias for getResource()
function $r(...)
```

### Service Access

```javascript
/**
 * Get direct access to the i18n service
 * @return i18n@cbi18n service instance
 */
function i18n()

/**
 * Get direct access to the resource service
 * @return resourceService@cbi18n service instance
 */
function resourceService()
```

## 📚 Documentation & Resources

### Official Documentation

- **Complete Guide**: [https://coldbox-i18n.ortusbooks.com/](https://coldbox-i18n.ortusbooks.com/)
- **API Documentation**: [https://apidocs.ortussolutions.com/#/coldbox-modules/cbi18n/](https://apidocs.ortussolutions.com/#/coldbox-modules/cbi18n/)
- **Quick Reference**: [https://coldbox.ortusbooks.com/the-basics/modules](https://coldbox.ortusbooks.com/the-basics/modules)

### Community & Support

- **Source Code**: [https://github.com/coldbox-modules/cbi18n](https://github.com/coldbox-modules/cbi18n)
- **Issues & Bugs**: [https://github.com/coldbox-modules/cbi18n/issues](https://github.com/coldbox-modules/cbi18n/issues)
- **ForgeBox Package**: [https://forgebox.io/view/cbi18n](https://forgebox.io/view/cbi18n)
- **Community Slack**: [https://boxteam.ortussolutions.com/](https://boxteam.ortussolutions.com/)
- **Professional Support**: [https://www.ortussolutions.com/services](https://www.ortussolutions.com/services)

### Additional Resources

- **Changelog**: [changelog.md](changelog.md)
- **CBStorages Module**: [https://github.com/coldbox-modules/cbstorages](https://github.com/coldbox-modules/cbstorages)
- **Java Locale Reference**: [https://docs.oracle.com/javase/8/docs/api/java/util/Locale.html](https://docs.oracle.com/javase/8/docs/api/java/util/Locale.html)

## 📄 License

Apache License, Version 2.0. See [LICENSE](LICENSE) file for details.

---

## About Ortus Solutions

**CBi18n** is a professional open-source project by **Ortus Solutions**.

- **ColdBox Platform**: [https://www.coldbox.org](https://www.coldbox.org)
- **Ortus Solutions**: [https://www.ortussolutions.com](https://www.ortussolutions.com)

---

**Copyright Since 2005 ColdBox Framework by Luis Majano and Ortus Solutions, Corp**

**[www.coldbox.org](https://www.coldbox.org) | [www.ortussolutions.com](https://www.ortussolutions.com)**

---

### ✝️ HONOR GOES TO GOD ABOVE ALL

Because of His grace, this project exists. If you don't like this, then don't read it, its not for you.

> *"Therefore being justified by faith, we have peace with God through our Lord Jesus Christ: By whom also we have access by faith into this grace wherein we stand, and rejoice in hope of the glory of God. And not only so, but we glory in tribulations also: knowing that tribulation worketh patience; And patience, experience; and experience, hope: And hope maketh not ashamed; because the love of God is shed abroad in our hearts by the Holy Ghost which is given unto us."* **Romans 5:5**

### 🍞 THE DAILY BREAD

> *"I am the way, and the truth, and the life; no one comes to the Father, but by me (JESUS)"* **John 14:1-12**
