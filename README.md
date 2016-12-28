# foursquare-stats

A simple Perl and R solution to draw line graphs of your [foursquare](http://www.foursquare.com) check-ins over the years.

![Example plot](https://raw.githubusercontent.com/stephwen/foursquare-stats/master/example/plot2.png)

Pre-requisites
=============
* Perl
* R
	* ggplot2
	* directlabels
	* plyr
	* reshape2

Installation/Usage
==================
```bash
$ git clone https://github.com/stephwen/foursquare-stats.git
$ cd foursquare-stats
$ perl parseFeed.pl <your foursquare rss feed>
```

What it is and how it works
===========================
I wanted to have a nice visualization of how my foursquare check-ins in different countries have evolved since I started using the service (in 2010).

Obviously, one check-in does not equal one day spent in said country, but it's still interesting to see the different trends.

The data source I used is the personal RSS feed which you can download here: https://foursquare.com/feeds/

It contains the latitude and longitude as well as the date for each of your check-ins. To link a country to a latitude/longitude pair, I could have used the Google Maps Reverse Geocoding API, but the free version is limited in terms of number of requests, so instead I went to [geonames.org](http://geonames.org) and I downloaded a list of 15 000 cities with their geographical coordinates. (this file: http://download.geonames.org/export/dump/cities15000.zip)
For each of my check-ins, I consider that the country where the check-in was done is the country of the closest city from this list.
Usually, this method will give accurate results, except if you've checked in at a place near a border, where the nearest city was on the other side of the border. 

All the data parsing is done with **Perl** in the script *parseRss.pl*.

To plot the data, I'm using **R**, **ggplot2** and **directlabels**. The R script *drawPlots.R* also uses **plyr** and **reshape2**.

Interestingly, I found one check-in with erroneous coordinates. I was at a place in Belgium, and the RSS lists a place in China. I don't know how this error occurred. 

The Perl script
--------------------

At first, I fill an array of hashes. Each hash contains the coordinates and the country code of a city.
```perl
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
```
Then I parse the RSS feed downloaded from foursquare.

```perl
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
```

You'll notice that I don't bother to use an RSS parsing module, I just use 2 regular expressions to catch the coordinates and the dates of each check-in. 
This is obviously a quick and dirty solution, but unless you've checked in at a place called "41.454785 -12.18484" or "Sat, 24 Apr 10", it's enough.
Then, for each of those coordinates, I look for the closest city. I use the euclidean distance.
I use a hash called *%visitedPlaces*, so that if I checked in a the same place more than once, the script doesn't have to re-do the whole looking through-the-cities-list-to-find-the-closest-one process
I store the number of check-ins in a hash of hash called *%visitsByYearByCountry*. The first key is the year when the check-in took place, and the second key is the country where it took place. The value of the hash of hash is the total number of check-ins for that specific year in that specific country.

And basically that's it. After that I just output my hash of hash as a TSV file.



The R script
----------------

I just transform the data and I plot thanks to *ggplot2*. I'm using [directlabels](http://directlabels.r-forge.r-project.org/), which is great to add labels next to the lines of a graph.
I thought about log-transforming the y-axis, since one country has a very large number of check-ins as compared to the others, but instead I chose to just draw 2 plots.
You'll see that some of the x- and y limits are hardcoded in the calls to the ggplot function, so these should be adjusted.

