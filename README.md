#Firefox Extension Utilities

This collection of scripts is a handy toolkit for Firefox extension developers.
I created them out of frustration for doing repetitive tasks during extension
development, and they have since made my life much easier. Hopefully someone
else will find them just as useful. I hope to add to this toolkit as I develop
scripts worth sharing.

The following scripts are currently available:

## compareLocales.pl

Compares all of the locales it finds against a "master" locale (`en-US` by default)
and reports the number of exact duplicate entries for each. This is useful for
figuring out which locales have not been updated.

## entityToProperty.pl

Converts a given list of locale entities into corresponding properties. Handy
for migrating existing entity localizations into a `.properties` file.

## findOrphanedEntities.pl

This script looks for entities from DTD files that aren't used anywhere in
corresponding XUL files. Handy for locating strings that have been deprecated.

## removeLocaleEntries.pl

This script removes a given list of entries from all of the locale folders it
finds in the current working directory and below. Useful for cleaning up strings
that are no longer needed.

# Script Usage Statements

Here is the expanded usage information for each of these scripts. Note that you
should always look at the usage information for each script (with `--help`) to
ensure what the script expects. This README file is likely to be out of date.

## compareLocales.pl

    Script Usage:
      compareLocales.pl [Options] [Locale_Root_Directory]
    
    This script is used to compare the locales for Firefox extensions, providing
    data on how many strings are untranslated between the "master" (or root)
    locale, and all others that the script finds. Useful for determining which
    specific locales are not keeping up with updates. Strings that are 1 character
    in length are ignored from the comparison.
    
    LIMITATIONS
    At the moment, this script only works on DTD files, not .properties files
    
    [Locale_Root_Directory]
      If provided, specifies the absolute location of the 'locale' folder (defaults
      to the current working directory if not provided)
      
    [Options]
      --master LOCALE-NAME
      Sets the master locale folder to compare against; defaults to 'en-US'
      
      --verbose
      Displays the duplicate entries that are found for each locale

## entityToProperty.pl

    Script Usage:
    entityToProperty.pl --input FILENAME --target FILENAME
    
    Description:
    This script converts specific, localized DTD entities into corresponding
    values in a .properties file. Useful for easily moving DTD strings into a
    .properties file for use in JavaScript. Note that the .properties file must
    already exist (this script will not create a new file).
    
    --input FILENAME
    Specifies the filename that contains the mapping. See the section on mapping
    entities below for more information.

    --target FILENAME
    Specifies the name of the .properties file into which the new property
    entries should be placed.

    Mapping Entities:
    The input file should include a mapping of entities to properties, and should
    be formatted as shown below:

      some.entity.id => SomeJavascriptVariable

    For example:

      gblite.confirm.title => GBL_HistoryConfirmTitle

    This example would make the following transformation:

      <!ENTITY gblite.confirm.title "Some string here">    <-- From some_file.dtd
      GBL_HistoryConfirmTitle=Some string here             <-- To target.properties

    Example Usage:
      entityToProperty.pl --input map.txt --target myExtension.properties
      
## findOrphanedEntities.pl

    Script Usage:
      findOrphanedEntities.pl [Options]
      
    This script is used to find entities in Firefox extension locale files that are
    not used anywhere in the project. Handy for determining what entities can be
    dropped going forward.
    
    LIMITATIONS
    At the moment, this script only works on DTD files, not .properties files
    
    [Options]
      --master LOCALE-NAME
      Specifies the name of the master locale to compare against; defaults to 'en-US'

## removeLocaleEntries.pl

    Script Usage:
      removeLocaleEntries.pl [Options] [Entities]
      
    Description:
      This script is used to remove specified entities from all locales in a Firefox
      extension's locale folder structure, making it very easy to remove deprecated
      strings from a project.
      
    [Entities]
      A space separated list of entity IDs to be removed from the various locale
      files.
      
    [Options]
      --prefix SOME_STRING
      If specified, prepends SOME_STRING to each entity ID that needs to be removed,
      saving you from having to type the same prefix a number of times.
      
      --input FILENAME
      Specifies the input filename from which to read entity IDs to remove
      
    Example:
      removeLocaleEntries.pl --prefix gblite.confirm. title label.yes ak.yes
  
      The above example will remove the following entities from each DTD file found
      in the project:
        * <!ENTITY gblite.confirm.title "...">
        * <!ENTITY gblite.confirm.label.yes "...">
        * <!ENTITY gblite.confirm.ak.yes "...">

