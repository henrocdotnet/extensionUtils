#Firefox Extension Utils

This collection of scripts are a handy toolkit for Firefox extension developers.
I created them out of the frustration of having to handle repetitive tasks, and
they have since made my life much easier. Hopefully someone else will find them
just as useful. I hope to add to this toolkit as I develop scripts worth sharing.

The following scripts are currently available:

## compareLocales.pl

Compares all of the locales it finds against a "master" locale (`en-US` by default)
and reports the number of exact duplicate entries for each. This is useful for
figuring out which locales have not been updated.

## entityToProperty.pl

Converts a given list of locale entities into corresponding properties. Handy
for migrating existing entity localizations into a `.properties` file.

## removeLocaleEntries.pl

This script removes a given list of entries from all of the locale folders it
finds in the current working directory and below. Useful for cleaning up strings
that are no longer needed.
