#!/usr/bin/perl
use strict;
use warnings;

our $VERSION = "1.00";

use Cwd;
use Encode;
use File::Find;
use Getopt::Long;

my $cwd = getcwd();
my $inputFile = '';
my $prefix = '';
my $tempFile = 'cleaned_locale.dtd';
my @toRemove = ();

GetOptions("input=s" => \$inputFile,
		   "prefix=s" => \$prefix,
		   "help" => sub { usage(); exit 0; });

print "\nRemove Locale Entries v$VERSION\n\n";
print "Script Parameters\n";
print " - Input file:   $inputFile\n";
print " - Prefix:       $prefix\n\n";

# Handle any entities on the command line
foreach (@ARGV)
{
	push @toRemove, "${prefix}$_";
}

# Handle any entities in an input file
if ($inputFile)
{
	if (! -f $inputFile)
	{
		print "ERROR: Unable to locate $inputFile!\n";
		exit 1;
	}
	else
	{
		open my $in, '<', $inputFile or die "Cannot open $inputFile: $!";
		while (<$in>)
		{
			chomp;
			s/^\s*//;
			s/\s*$//;
			push @toRemove, "${prefix}$_";
		}
		close $in;
	}
}

print "Entities to be removed:\n";
foreach (@toRemove)
{
	print " - $_\n";
}

print "\nScanning locale folders...\n\n";
find(\&wanted, $cwd);

sub wanted
{
	return if $File::Find::name !~  m!chrome/locale!;
	return if ! m/\.dtd$/;
	
	my $id = $File::Find::dir;
	$id =~ s!^.+/(.+)$!$1!;
	
	printf("%7s", $id);
	
	my @dtds = <*.dtd>;
	foreach my $f (@dtds)
	{
		open my $in, '<:encoding(UTF-8)', $f or die "Cannot open $f: $!";
		open my $out, '>:encoding(UTF-8)', $tempFile or die "Cannot open $tempFile: $!";
		
		my $removed = 0;
		my $skip = 0;
		while (<$in>)
		{
			$skip = 0;
			
			foreach my $match (@toRemove)
			{
				if(m/\Q$match\E/)
				{
					$removed++;
					$skip = 1;
					last;
				}
			}
			
			next if $skip == 1;
			
			print $out $_;
		}
		close $out;
		close $in;
		
		if ($removed > 0)
		{
			printf("  --  Removed %d %s\n", $removed, $removed == 1 ? 'entity' : 'entities');
			unlink $f or die "Unable to remove $f: $!";
			rename $tempFile, $f;
		}
		else
		{
			print "  --  Nothing to do!\n";
		}
	}
}

sub usage
{
print <<USAGE;
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
USAGE
}
