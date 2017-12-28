#!/usr/bin/perl

use strict;
use warnings;
use v5.10; 
use File::Basename;

my $in;
my $out;
my @cities;
my %visitedPlaces;		# HoH, k1: lat, k2: long, value: country code for that geoloc
my %visitsByYearByCountry;	# HoH, k1: year, k2: country code, value: nb of visits in that country for that year
my %visitsByCountry;
my %countries;

my $path = dirname($0);
my $citiesFile = "$path/latLongCC15000.txt";	# 3 column file based on http://download.geonames.org/export/dump/cities15000.zip
my $countryNameFile = "$path/CC_countryName.txt"; # 2 columns file based on http://download.geonames.org/export/dump/countryInfo.txt
my $fourSqFile = shift;
my $outTableFile = "$path/checkinsByCountryByYear.tsv";

my $usage = "Usage: perl $0 <rss file with your check-ins>\n";

if (not defined $fourSqFile || -f $fourSqFile) { die($usage); }

say "Loading cities coordinates.......";

open($in, "<", $citiesFile) || die("Unable to open file $citiesFile\n");
while (my $line = <$in>) {
	chomp($line);
	my ($lat, $long, $country) = split(/ /, $line);
	my $hashRef = {};
	$hashRef->{'lat'} = $lat; 
	$hashRef->{'long'} = $long; 
	$hashRef->{'CC'} = $country; 
	push(@cities, $hashRef);
}
close($in);

open($in, "<", $countryNameFile) || die("Unable to open file $countryNameFile\n");
while (my $line = <$in>) {
	chomp($line);
	my ($cc, $countryName) = split(/\t/, $line);
	$countries{$cc} = $countryName;
}
close($in);

my $closestCoords;

say "Loading foursquare check-ins.....";

open($in, "<", $fourSqFile) || die("Unable to open file $fourSqFile\n");
while (my $line = <$in>) {
	my @lines = split("<item>", $line);
	foreach my $line (@lines) {
		my ($coords) = $line =~ /(\-?\d+\.\d+ \-?\d+\.\d+)/;
		my ($date) = $line =~ /(\w\w\w, \w\w \w\w\w \d\d)/;
		if ($coords && $date) { 
			my ($lat, $long) = split(/ /, $coords);
			next if $long == "120.1465399973193";	# weird 4sq bug
			my $country;
			if ($visitedPlaces{$lat}{$long}) { $country = $visitedPlaces{$lat}{$long}; } else {
				my $distance = 655536;
				my $closestCountry = "";
				for my $city (@cities) {
					my $thisDistance = ($lat-$city->{'lat'})**2+($long-$city->{'long'})**2;
					if ($thisDistance < $distance) { 
						$distance = $thisDistance;
						$closestCountry = $city->{'CC'};
						$closestCoords = $city->{'lat'}." ".$city->{'long'};
					}
				}
				$visitedPlaces{$lat}{$long} = $closestCountry;
				$country = $closestCountry;
				if ($country eq "VA") { $country = "IT"; }	# replacing Vatican with Italy
			}
			my (undef, undef, undef, $year) = split(/ /, $date);
			$year = "20$year";
			$visitsByYearByCountry{$year}{$country}++;
			$visitsByCountry{$country}++;
		}
	}
}
close($in);

open($out, ">", $outTableFile) || die("Unable to open out file $outTableFile\n");

for my $CC (sort { $visitsByCountry{$b} <=> $visitsByCountry{$a} } keys %visitsByCountry) {
	print $out "\t".$countries{$CC};
}
print $out "\n";
for my $year (sort keys %visitsByYearByCountry) {
	print $out $year;
	for my $country (sort { $visitsByCountry{$b} <=> $visitsByCountry{$a} } keys %visitsByCountry) {
		if (!$visitsByYearByCountry{$year}{$country}) { $visitsByYearByCountry{$year}{$country} = "0"; }
		print $out "\t".$visitsByYearByCountry{$year}{$country};
	}
	print $out "\n";
}
close($out);

if (!-f $outTableFile) { die("Error producing file $outTableFile\n"); }
say "Launching R to draw the plots....";
system("Rscript drawPlots.R checkinsByCountryByYear.tsv");
say "Creating GIFs....................";
system("convert -delay 120 plot1_*.png plot1.gif");
system("convert -delay 120 plot2_*.png plot2.gif");
system("rm plot1_*.png");
system("rm plot2_*.png");
say ("Done!");

