#!/usr/bin/perl
use strict;
use warnings;

our $VERSION = "1.01";

use Cwd;
use Encode;
use File::Find;
use Getopt::Long;

my $masterLocale = 'en-US';
my $verbose = 0;
GetOptions("master=s" => \$masterLocale,
		   "verbose" => \$verbose,
		   "help" => sub { usage(); exit 0; });

my $target = shift;
if (!$target)
{
	$target = getcwd();
}
else
{
	# If the user specified a target directory, change to it
	chdir $target or die "Unable to change to $target: $!";
}

if (! -d $masterLocale)
{
	# We didn't find the master locale, so look for a chrome/locale folder
	if(-d "$target/chrome/locale")
	{
		$target .= "/chrome/locale";
		chdir $target or die "Unable to change to $target: $!";
	}
	elsif(-d "$target/locale")
	{
		$target .= "/locale";
		chdir $target or die "Unable to change to $target: $!";
	}
	else
	{
		print "ERROR: Unable to locate master locale folder ($masterLocale): $!";
		exit 1;
	}
}

print "\nLocale Comparison v$VERSION\n\n";
print "Parameters:\n";
print " - Master locale:    $masterLocale\n";
print " - Verbose output:   $verbose\n";
print " - Target directory: $target\n";

chdir $masterLocale;

my %masterEntities;
my %stats;

my @masterFiles = <*.dtd>;
print "\nReading files from master locale...\n";
foreach my $file (@masterFiles)
{
	print " - $file ";
	open my $in, '<', $file;
	while (<$in>)
	{
		if(m/<!ENTITY ([^ \t]+) "([^"]+)">/)
		{
			$masterEntities{$1} = $2;
		}
		# my ($id, $value) = (m/<!ENTITY ([^ \t]+) "([^"]+)">/);
		# if (defined $id && defined $value)
		# {
		# 	$masterEntities{$id} = $value;
		# }
	}
	close $in;
	print "(" . scalar(keys %masterEntities) . " entries)\n";
}

chdir $target;

binmode STDOUT, ':utf8';

print "\nScanning other locales...\n";
find(\&wanted, $target);

print "\nLocale   Matches   % Match   Missing   % Missing\n";
print "------------------------------------------------\n";
printf("%6s   %7d   {Master Locale}\n\n", $masterLocale, scalar(keys %masterEntities));

foreach my $key (sort keys %stats)
{
	my $shortKey = $key;
	$shortKey =~ s!^.+/(.+)$!$1!;
	printf("%6s   %7d   %6.1f%%   %7d   %8.1f%%\n", $shortKey, $stats{$key}{'matches'},
	       ($stats{$key}{'matches'} / scalar(keys %masterEntities)) * 100,
	       $stats{$key}{'missing'}, ($stats{$key}{'missing'} / scalar(keys %masterEntities)) * 100);
}

exit 0;

sub wanted
{
	return if $File::Find::dir =~ m/$masterLocale/;
	return if ! m/\.dtd$/;
	
	my $id = $File::Find::dir;
	$id =~ s!^.+/(.+)$!$1!;
	print "\n$id\n" if $verbose;
	my @dtds = <*.dtd>;
	foreach my $f (@dtds)
	{
		my %locale = ();
		my $matches = 0;
		my $missing = 0;
		
		open my $in, '<:encoding(UTF-8)', $f or die "Cannot open $f: $!";
		while (<$in>)
		{
			next if m/^\s*$/; # Skip blank lines

			my ($id, $value) = m/<!ENTITY ([^ \t]+) "([^"]+)">/;
			$locale{$id} = $value;
			if ($masterEntities{$id} eq $value && length $value > 1)
			{
				print " - Duplicate ($id - \"$masterEntities{$id}\")\n" if $verbose;
				$matches++;
			}
		}
		close $in;

		foreach (sort keys %masterEntities)
		{
			if(! exists $locale{$_})
			{
				print " - Missing ($_ - \"$masterEntities{$_}\")\n" if $verbose;
				$missing++;
			}
		}
		
		$stats{$File::Find::dir}{'matches'} = $matches;
		$stats{$File::Find::dir}{'missing'} = $missing;
	}
}

sub usage
{
print <<USAGE;
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
  --master
  Sets the master locale folder to compare against; defaults to 'en-US'
  
  --verbose
  Displays the duplicate entries that are found for each locale
USAGE
}
