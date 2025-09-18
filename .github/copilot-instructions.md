# Copilot Instructions for cbi18n Module

## Project Overview

cbi18n provides internationalization (i18n) and localization support for ColdBox applications. It supports both traditional Java `.properties` files and modern JSON resource bundles, with dynamic locale switching and persistent user locale storage.

## Architecture & Core Patterns

### Two-Service Architecture
- **i18n Service** (`models/i18n.cfc`): Main facade providing locale management, resource retrieval, and user-facing API
- **ResourceService** (`models/ResourceService.cfc`): Handles resource bundle loading, parsing, and storage management
- **Dependency**: Requires `cbstorages` module for persistent locale storage across requests

### Resource Bundle Management
- **Bundle Structure**: `{alias: {locale: {key: value}}}` - nested structure by bundle alias, then locale, then resource keys
- **File Formats**: Supports both `.properties` (Java) and `.json` files with automatic format detection
- **Naming Convention**: Files named as `basename_locale.ext` (e.g., `main_en_US.properties`, `main_es_ES.json`)
- **Loading Strategy**: Lazy loading with double-lock checking for thread safety

### Locale Storage Integration
- **Storage Abstraction**: Uses cbstorages for locale persistence (`cookieStorage@cbstorages` by default)
- **Backwards Compatibility**: v1 storage names (`session`, `cookie`) auto-converted to v2 format
- **Discovery Order**: User stored locale → Default configured locale → `en_US` fallback

## Critical Developer Workflows

### Module Configuration Pattern
```javascript
// In config/ColdBox.cfc or ModuleConfig.cfc
moduleSettings = {
    cbi18n: {
        defaultResourceBundle: "includes/i18n/main",    // Base path without locale suffix
        defaultLocale: "en_US",                         // Java locale format
        localeStorage: "cookieStorage@cbstorages",      // Any cbstorages service
        unknownTranslation: "**NOT FOUND**",            // Missing key display
        resourceBundles: {                              // Additional bundles
            "support": "includes/i18n/support",
            "admin": "modules/admin/includes/i18n/admin"
        }
    }
}
```

### Resource Bundle Loading Lifecycle
1. **Module Load**: `afterAspectsLoad()` scans all modules for `cbi18n` settings
2. **Service Init**: `onDIComplete()` loads default bundle and additional bundles
3. **Dynamic Loading**: `loadBundle()` called automatically when accessing missing locale/bundle combinations
4. **Thread Safety**: Named locks prevent concurrent loading of same bundle/locale

### Testing Patterns
- **Mock Structure**: Always mock `resourceService`, `storageService`, and `controller`
- **Setup**: Call `setup()` and `i18n.onDiComplete()` in test setup to initialize properly
- **Storage Mocking**: Mock cbstorages service methods (`get`, `set`) for locale persistence

## Key Implementation Details

### Resource Retrieval Algorithm
1. Check if bundle/locale combination exists in memory
2. If missing, attempt to load from filesystem with `loadBundle()`
3. Look for exact locale match first, then language-only fallback
4. Return configured `unknownTranslation` if not found
5. Emit `onUnknownTranslation` interceptor event for logging/handling

### Mixin Helper Injection
- **Location**: `helpers/Mixins.cfm` injected as `applicationHelper`
- **Global Functions**: `getFWLocale()`, `setFWLocale()`, `getResource()`, `$r()`, `i18n()`, `resourceService()`
- **Lazy Loading**: Functions use `getInstance()` pattern to avoid circular dependencies

### File Format Detection & Parsing
```javascript
// ResourceService auto-detects format and parses accordingly
if (fileExists(rbFile & "_" & rbLocale & ".json")) {
    // Parse JSON format
} else if (fileExists(rbFile & "_" & rbLocale & ".properties")) {
    // Parse Java properties format
}
```

## Integration Points

### ColdBox Framework Integration
- **Interceptor Events**: Emits `onUnknownTranslation` with `{resource, locale, bundle}` data
- **Module Dependencies**: Hard dependency on `cbstorages` declared in `ModuleConfig.cfc`
- **Settings Inheritance**: Child modules can override parent i18n settings

### Storage Service Interaction
- **Initialization**: Resolves storage service via WireBox ID during `onDIComplete()`
- **Error Handling**: Throws `i18N.DefaultSettingsInvalidException` for invalid storage configurations
- **Locale Persistence**: User locale stored/retrieved using configured storage service

### Multi-Module Support
- **Bundle Aliasing**: Each module can register its own resource bundles with unique aliases
- **Settings Cascade**: Module-specific settings override global defaults
- **Lazy Initialization**: Only creates i18n service if modules actually use i18n features

## Development Commands

```bash
# Standard module development
box task run build/Build.cfc
box testbox run bundles=test-harness/tests

# Format code
box run-script format

# Multi-engine testing
box run-script start:lucee
box run-script start:adobe
box run-script start:boxlang
```

## Common Patterns

### Resource Bundle Organization
- **Hierarchical Keys**: Use dot notation (`user.profile.name`, `error.validation.required`)
- **Placeholder Support**: Resources support `{1}`, `{2}` style replacements
- **Bundle Aliases**: Organize by feature/module (`default`, `admin`, `api`, `emails`)

### Locale Management
- **Java Format**: Always use `lang_COUNTRY` format (`en_US`, `es_ES`, `fr_CA`)
- **Fallback Strategy**: Missing locale falls back to language-only, then default locale
- **Dynamic Switching**: `setFWLocale()` immediately switches user's locale and loads resources