# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

----

## [3.2.0] => 2022-NOV-16

### Added

* Updated to use latest cb7 `announce()`

----

## [3.1.0] => 2022-NOV-15

### Added

* New ColdBox 7 delegate: `Resourceful@cbi18n`

----

## [3.0.0] => 2022-OCT-10

### Added

* New module template updates

### Changed

* Dropped 2016 Support

----

## [2.2.0] => 2022-JAN-11

### Added

* Migration to github actions
* CFFormatting

### Fixed

* Currently each time ColdBox framework gets reinited (?fwreinit=1) or server restarted, user-selected locale gets reset to the default locale.

----

## [2.1.0] => 2021-JAN-20

### Fixed

* Missing `cbStorages` dependency on the `box.json` causes failures upon installation

### Added

* Added a shortcut compatiblity layer so v1 apps don't crash on choosing `localeStorage`. Basically, we map the incoming locale storage from the old approach: `session,client,cookie,request` to the `cbStorages` equivalent

----
## [2.0.0] => 2021-JAN-19

### Added

* ACF2016, ACF2018 Support
* Complete migration to script thanks to @wpdebruin
* Fallback mechanism for resource selection from base, to language, to country variants thanks to @wpdebruin
* Migration to leverage cbStorages for locale storage thanks to @wpdebruin
* Interceptor for missing translations `onUnknownTranslation` thanks to @wpdebruin
* `CookieStorage` is now used as the default for storing locales
* Support for flat or embedded JSON resource bundles as well as Java resource bundles via extension detection `properties` `json` thanks to @wpdebruin
* New `i18n()` mixin helper to get easy access to i18n methods
* New `resoureService()` mixin helper to get easy access to the resource service model
* The extension of the file (`.properties, .json`) is what determines the resource type to use
* Github autopublishing of changelogs
* New CI procedures based on new ColdBox modules
* More formatting goodness and watchers


### Removed

* Old approach to top level `i18n` settings. You know will use the normal `moduleSettings` with a `cbi18n` key for settings
* On modules, you will use also the `cbi18n` top level key for configuration for each module
* ACF11, Lucee 4.5 Support
* `DefaultLocale` in storage now renamed to `CurrentLocale`
* `dontloadRBFlag` removed as it was never used anymore.

### Fixed

* Lots of fixes on localization methods using old Java classes that didn't exist anymore
* Lots of fixes on streamlining the java classes used for localization

----

## [1.5.0]

* `Improvement` : Updated to new template style
* `Improvement` : ColdBox 5 updates
* `Improvement` : Moved i18n listener to afterAspectsLoad to avoid module loading collisions
* `Bug` : Invalid `instance` scope usage in models

----

## [1.4.0]

* Few docuementation fixes
* Fix implementation of `getTZoffset()` thanks to Seb Duggan
* CCM-47 Case sensitivity resolved for resource service thanks to @wpdebruin
* Updated TestBox version

----

## [1.3.2]

* Unified workbench
* Encapsulation of module bundle resources

----

## [1.3.1]

* Varscoping fixes
* Travis updates

----

## [1.3.0]

* Implements the ability to add a custom Resource Service for distributed i18n
* Fixes issues with non-ISO characters in properties files

----

## [1.2.0]

* New configuration setting for logging when no translation is found `logUnknownTranslation`
* Adding Travis CI support

----

## [1.1.0]

* Updated build process
* Updated docs and instructions

----

## [1.0.2]

* Fixes on `getRBKeys()` and `getRBString()` to load correct file paths.

----

## [1.0.1]

* production ignore lists
* Unloading of helpers

----

## [1.0.0]

* Create first module version
