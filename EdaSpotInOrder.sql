/*
This is a data analysis project using SQL that takes a look into Spotify's Top 100 Streamed Songs of 2018.

This SQL project has two main components to it. The first being data cleaning and the second being exploratory data analysis.
The beginning starts off with me cleaning/updating/transforming the data & changing data types. 
The was followed by me doing more aggregational & functional queries in order to create insights from this dataset.
*/

Lets begin.

/*I started with updating/changing the ID column. Each entry in the table had a distinct 21 character alphanumeric 
name as its "ID". For the sake of updating these records, I could see how these specific ID's could be helpful in a security sense.
However, to avoid confusion and make it easier to keep track of the entries in this table, I 
replaced this column with specific ID numbers for each entry.*/

ALTER TABLE topspotifyeighteen ADD COLUMN songid SERIAL PRIMARY KEY;

ALTER TABLE topspotifyeighteen
DROP COLUMN id


--Cleaning data with question marks
--From here I began to clean the data, starting with the question marks I came across, an instant red flag.
  
--Searching for any value with a question mark

SELECT songid, name, artists
FROM topspotifyeighteen
WHERE name LIKE '%?%'
	OR artists LIKE '%?%'
	

--Updating every value that had a question mark
--I researched the correct names of artists and songs & updated the values accordingly

UPDATE topspotifyeighteen
SET name = 'Te Bote - Remix'
WHERE songid = '22';
UPDATE topspotifyeighteen
SET name = 'Déjala Que Vuelva (feat. Manuel Turizo)'
WHERE songid = '67';
UPDATE topspotifyeighteen
SET name = 'Corazón (feat. Nego do Borel)'
WHERE songid = '86';
UPDATE topspotifyeighteen
SET name = 'Echame La Culpa'
WHERE songid = '35';
UPDATE topspotifyeighteen
SET artists = 'Tiesto'
WHERE songid = '46';
UPDATE topspotifyeighteen
SET name = 'Perfect Duet (Ed Sheeran & Beyonce)'
WHERE songid = '85';
UPDATE topspotifyeighteen
SET name = 'Siguelo Bailando'
WHERE songid = '88'


--Cleaning incorrect tempos
--I had to research each song on a case by case basis to make sure each tempo had the correct value

UPDATE topspotifyeighteen
SET tempo = tempo/2
WHERE tempo > 130


--Rounding the tempos

UPDATE topspotifyeighteen
SET tempo = ROUND(tempo)


--Going through and looking at the next set of tempos that were wrong

SELECT songid, name, artists, tempo
FROM TOPSPOTIFYEIGHTEEN
ORDER BY tempo desc


--Updating tempos for specific artists who's tempos were incorrect

UPDATE topspotifyeighteen
SET tempo = tempo/2
WHERE tempo > 116 AND artists IN ('XXXTENTACION', '6ix9ine', 'Post Malone', 'Lil Baby')


--Converting the time of duration
--Converting ms to seconds 

UPDATE topspotifyeighteen
SET duration_ms = duration_ms * .001;
--Seconds to minutes conversion
UPDATE topspotifyeighteen
SET duration_ms = duration_ms/60
--Rounding to nearest hundredth
UPDATE topspotifyeighteen
SET duration_ms = ROUND(duration_ms, 1)
--Changing the column name because we have converted the values to minutes now
ALTER TABLE topspotifyeighteen
RENAME COLUMN duration_ms to duration_mins


-- Changing danceability, energy, and speechiness into whole numbers so it is in a format that was easier to read and compare for later

UPDATE topspotifyeighteen
SET danceability = ROUND(danceability * 100)
UPDATE topspotifyeighteen
SET energy = ROUND(energy * 100)
UPDATE topspotifyeighteen
SET speechiness = ROUND(speechiness * 100)


--Fixed all values to have parenthesis when listing features for consistency

UPDATE topspotifyeighteen
SET name = 'Finesse Remix (feat. Cardi B)'
WHERE songid = '47'











--THIS MARKS THE END OF THE DATA CLEANING PROCESS












--This next section is where the exploratory data analysis begins



--Artists that had the most song entries on this list, filtered for artists who had at least 2 entries

SELECT artists, COUNT(artists)
FROM topspotifyeighteen
GROUP BY artists
HAVING COUNT(artists) >= 2
ORDER BY COUNT(artists) DESC


--Looking at all of the featured artists of this dataset

SELECT name
FROM topspotifyeighteen
WHERE name LIKE '%feat%'
	OR name LIKE '%with%'
	

--Using a substring to seperate featured artists from the song title

SELECT name, SUBSTRING(name FROM POSITION('(' IN name)) AS featuredartists
FROM
	(SELECT name
	FROM topspotifyeighteen
	WHERE name LIKE '%feat%'
		OR name LIKE '%with%') AS ftartists
		

--Using a SUBSTR formula to take away parenthesis so you can see just the featured artists then storing it into a CTE

WITH CTE_featuredartists AS
(SELECT SUBSTRING(name FROM POSITION('(' IN name)) AS features
FROM
	(SELECT name
	FROM topspotifyeighteen
	WHERE name LIKE '%feat%'
		OR name LIKE '%with%') AS ftartists)
SELECT SUBSTRING(features FROM POSITION(' ' IN features) FOR POSITION(')' IN features) - POSITION(' ' IN features)) AS substringofcte
FROM CTE_featuredartists


--Creating a temptable to see a list of all featured artists from the original dataset

CREATE TEMP TABLE temp_featuredartists (features varchar)


--Inserted the previous CTE into temp table

INSERT INTO temp_featuredartists
WITH CTE_featuredartists AS
(SELECT SUBSTRING(name FROM POSITION('(' IN name)) AS features
FROM
	(SELECT name
	FROM topspotifyeighteen
	WHERE name LIKE '%feat%'
		OR name LIKE '%with%') AS ftartists)
SELECT SUBSTRING(features FROM POSITION(' ' IN features) FOR POSITION(')' IN features) - POSITION(' ' IN features)) AS substringofcte
FROM CTE_featuredartists


--Using the TEMP Table to count all features to see who was the most featured artist of the year, 
--However, this doesnt take into account an artist who may have been a part of a song with multiple featured artists

SELECT features, COUNT(features)
FROM temp_featuredartists
GROUP BY features
ORDER BY COUNT(features) DESC



--Looking deeper at artists who came up more than once in the above query but were counted only once because of formatting
SELECT COUNT(features), features
FROM temp_featuredartists
WHERE features LIKE '%Khalid%'
	OR features LIKE '%Selena%'
	OR features LIKE '%Cardi B%'
	OR features LIKE '%Halsey%'
GROUP BY features


--Taking a look at the average tempo
SELECT AVG(tempo)
FROM topspotifyeighteen


--Using a CASE statement to put each tempo into a range and see what tempo range was the most popular of the year 2018

SELECT temporanges, COUNT(temporanges)
FROM
(SELECT 
CASE 
	WHEN tempo between 60 AND 69 THEN '60s'
	WHEN tempo between 70 AND 79 THEN '70s'
	WHEN tempo between 80 AND 89 THEN '80s'
	WHEN tempo between 90 AND 99 THEN '90s'
	WHEN tempo between 100 AND 109 THEN '100s'
	WHEN tempo between 110 AND 119 THEN '110s'
	WHEN tempo between 120 AND 129 THEN '120s'
	WHEN tempo between 130 AND 139 THEN '130s'
END AS temporanges
FROM topspotifyeighteen) AS temprngsubq
GROUP BY temporanges
ORDER BY COUNT(temporanges) DESC


--Showing the specific songs of the most popular tempo range
SELECT songid, *
FROM topspotifyeighteen
WHERE tempo BETWEEN 90 AND 99


--Using a windows function to see the average danceability rating of the most popular tempo range

SELECT *, AVG(danceability) OVER (PARTITION BY ninetystempo)
FROM
	(SELECT tempo, danceability, 
	CASE
		WHEN tempo between 90 AND 99 THEN '90s'
	END AS ninetystempo
	FROM topspotifyeighteen
	WHERE tempo BETWEEN 90 AND 99) subq
	

--Looking at the most popular specific tempo of the most popular tempo range 

SELECT tempo, COUNT(tempo)
FROM topspotifyeighteen
WHERE tempo BETWEEN 90 AND 99
GROUP BY tempo
ORDER BY COUNT(tempo) DESC


--Looking at key thats most popular

SELECT key, COUNT(key)
FROM topspotifyeighteen
GROUP BY key
ORDER BY COUNT(key) DESC



/*As I got into  more aggregate functions below looking at averages in comparison to artists and such, I would filter for artists
with more than two entries to avoid an unrealistic skew in the data. One artist could have a very high rating for one of these attributes but
would only have that one song, so it would essentially be inaccurate to call them the "most danceable" or "most energetic" artist since their
one entry doesn't hold as much weight in comparison to artists with more consistent entries*/



--The average danceability rating of an artists with more than two song entries

SELECT artists, ROUND(AVG(danceability))
FROM topspotifyeighteen
GROUP BY artists
HAVING COUNT(artists) > 2



--Aggregating data to see artists with more than two entries, the avg danceability of each artist, and the average danceability rating overall

SELECT *
FROM
	(SELECT artists,
	 COUNT(artists) OVER (PARTITION BY artists) artistentries,
	AVG(danceability) OVER (PARTITION BY artists) avgdanceperartist,
	 AVG(danceability) OVER() avgdance
	FROM topspotifyeighteen) dancepartitions
WHERE artistentries > 2 
ORDER BY artistentries DESC, avgdanceperartist DESC


--Looking at artists with more than two entries with a higher than average dance rating, essentially looking at the most danceable artists

SELECT *
FROM
	(SELECT artists,
	 COUNT(artists) OVER (PARTITION BY artists) artistentries,
	AVG(danceability) OVER (PARTITION BY artists) avgdanceperartist,
	 AVG(danceability) OVER() avgdance
	FROM topspotifyeighteen) dancepartitions
WHERE artistentries > 2 AND avgdanceperartist > avgdance
ORDER BY artistentries DESC, avgdanceperartist DESC


--Looking at artists with more than two entries with a higher than average energy rating, essentially looking at the most energetic artists

SELECT *
FROM
	(SELECT artists,
	 COUNT(artists) OVER (PARTITION BY artists) artistentries,
	AVG(energy) OVER (PARTITION BY artists) avgenergyperartist,
	 AVG(energy) OVER() avgenergy
	FROM topspotifyeighteen) energypartitions
WHERE artistentries > 2 AND avgenergyperartist > avgenergy
ORDER BY artistentries DESC, avgenergyperartist DESC


--Aggregating the data to see what tempo range has the highest average dancability rating while also looking at the amount of entries per tempo range

SELECT temporanges, 
COUNT(temporanges) OVER (PARTITION BY temporanges), 
AVG(danceability) OVER (PARTITION BY temporanges) avgdancepertempo
FROM
(SELECT danceability, 
CASE 
	WHEN tempo between 60 AND 69 THEN '60s'
	WHEN tempo between 70 AND 79 THEN '70s'
	WHEN tempo between 80 AND 89 THEN '80s'
	WHEN tempo between 90 AND 99 THEN '90s'
	WHEN tempo between 100 AND 109 THEN '100s'
	WHEN tempo between 110 AND 119 THEN '110s'
	WHEN tempo between 120 AND 129 THEN '120s'
	WHEN tempo between 130 AND 139 THEN '130s'
END AS temporanges
FROM topspotifyeighteen) AS temprngsubq
ORDER BY avgdancepertempo DESC


--Looking at the average danceability rating for tempo ranges in descending order to find the most danceable tempo

SELECT temporanges, ROUND(AVG(danceability))
FROM
	(SELECT tempo, danceability,
	 CASE 
	WHEN tempo between 60 AND 69 THEN '60s'
	WHEN tempo between 70 AND 79 THEN '70s'
	WHEN tempo between 80 AND 89 THEN '80s'
	WHEN tempo between 90 AND 99 THEN '90s'
	WHEN tempo between 100 AND 109 THEN '100s'
	WHEN tempo between 110 AND 119 THEN '110s'
	WHEN tempo between 120 AND 129 THEN '120s'
	WHEN tempo between 130 AND 139 THEN '130s'
	END AS temporanges
	FROM topspotifyeighteen) rangsfgrp
GROUP BY temporanges
ORDER BY AVG(danceability) DESC


--Looking at each tempo range's average energy rating to find the most energetic tempo range 

SELECT temporanges, AVG(energy) avgenergypertempo
FROM
	(SELECT tempo, energy,
	 CASE 
	WHEN tempo between 60 AND 69 THEN '60s'
	WHEN tempo between 70 AND 79 THEN '70s'
	WHEN tempo between 80 AND 89 THEN '80s'
	WHEN tempo between 90 AND 99 THEN '90s'
	WHEN tempo between 100 AND 109 THEN '100s'
	WHEN tempo between 110 AND 119 THEN '110s'
	WHEN tempo between 120 AND 129 THEN '120s'
	WHEN tempo between 130 AND 139 THEN '130s'
	END AS temporanges
	FROM topspotifyeighteen) rangsfgrp	
GROUP BY temporanges
ORDER BY AVG(energy) DESC


--Taking a look at the list of all of the songs with a higher than average duration in minutes

SELECT name, duration_mins, 
(SELECT AVG(duration_mins) FROM topspotifyeighteen) avgsongduration
FROM topspotifyeighteen
WHERE duration_mins >
	(SELECT AVG(duration_mins)
	FROM topspotifyeighteen) 
ORDER BY duration_mins DESC


--Seeing who the speechiest artists were

SELECT artists, name, speechiness
FROM topspotifyeighteen
WHERE speechiness >
	(SELECT AVG(speechiness)
	FROM topspotifyeighteen)
ORDER BY speechiness DESC


--Looking at the artists with multiple entries and greater than average energy ratings 

SELECT topspot.artists, COUNT(artists)
FROM topspotifyeighteen topspot
JOIN (SELECT AVG(energy) avge FROM topspotifyeighteen) avgesubq
	ON topspot.energy > avgesubq.avge
GROUP BY artists
ORDER BY COUNT(artists) DESC


--Aggregating data to see artists with a higher than average danceability rating, the songs, and filtering for artists with more than two entries

WITH CTE_dancy AS
(SELECT topspot.name, topspot.artists, topspot.danceability, 
 COUNT(artists) OVER (PARTITION BY artists) artistcount
FROM topspotifyeighteen topspot
JOIN (SELECT AVG(danceability) avgd FROM topspotifyeighteen) avgdsubq
	ON topspot.danceability >= avgdsubq.avgd)
SELECT *
FROM CTE_dancy
WHERE artistcount > 2
ORDER BY artistcount DESC


--Looking at artists with higher than avg energy rating and more than one entry in the dataset

WITH CTE_energy AS
(SELECT topspot.name, topspot.artists, topspot.energy, 
 COUNT(artists) OVER (PARTITION BY artists) artistcount
FROM topspotifyeighteen topspot
JOIN (SELECT AVG(energy) avge FROM topspotifyeighteen) avgesubq
	ON topspot.energy >= avgesubq.avge)
SELECT *
FROM CTE_energy
WHERE artistcount > 1
ORDER BY artistcount DESC


--Looking at the top 5 danciest songs

SELECT *
FROM topspotifyeighteen
ORDER BY danceability DESC
LIMIT 5


--Looking at the top 5 most energetic songs

SELECT *
FROM topspotifyeighteen
ORDER BY energy DESC
LIMIT 5


--Creating a view to store data for later visualizations to look at correlation

SELECT tempo, danceability
FROM topspotifyeighteen

SELECT tempo, energy
FROM topspotifyeighteen

SELECT tempo, speechiness
FROM topspotifyeighteen

SELECT speechiness, danceability
FROM topspotifyeighteen

SELECT speechiness, energy
FROM topspotifyeighteen

SELECT energy, danceability
FROM topspotifyeighteen

SELECT danceability, energy
FROM topspotifyeighteen


/*ENDING NOTES*/

/* One flaw about this dataset does not state if the list is ordered in most streamed to least streamed.
there is no stream column showing stream count for each song at the time of this dataset publication.

I believe it would have been great to see the genres for these songs to see what
was the most popular genre at the time.*/
