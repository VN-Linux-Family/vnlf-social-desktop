# Release signing

Android releases require a local ignored `android/app/key.properties` or
`android/key.properties` containing storeFile, storePassword, keyAlias and
keyPassword. The referenced keystore stays outside version control. Release
builds fail when signing is missing; debug signing is never a release fallback.

Previously tracked key/property files were removed from the current Git tree,
with local copies preserved. Existing repository history still contains those
files. The owner must replace exposed signing material before distributing a
new production application; do not rewrite shared history or change an existing
application signing identity without an explicit migration decision.
