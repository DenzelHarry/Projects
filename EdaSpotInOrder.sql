/*
This is a data analysis project using SQL that takes a look into Spotify's Top 100 Streamed Songs of 2018.

This SQL project has two main components to it. The first being data cleaning and the second being exploratory data analysis.
The beginning starts off with me cleaning/updating/transforming the data & changing data types. 
The was followed by me doing more aggregational & functional queries in order to create insights from this dataset.*/

Lets begin.

/*I started with updating/changing the ID column. Each entry in the table had a distinct 21 character alphanumeric 
name as its "ID". For the sake of updating these records, I could see how these specific ID's could be helpful in a security sense.
However, to avoid confusion and make it easier to keep track of the entries in this table, I 
replaced this column with specific ID numbers for each entry.*/

ALTER TABLE topspotifyeighteen ADD COLUMN songid SERIAL PRIMARY KEY;

ALTER TABLE topspotifyeighteen
DROP COLUMN id

--Cleaning data with question marks
/*From here I began to clean the data, starting with the question marks I came across, an instant red flag.
 */ 

/*I used this query to filter for every value in name column 
and artists column that had a question mark */

SELECT songid, name, artists
FROM topspotifyeighteen
WHERE name LIKE '%?%'
	OR artists LIKE '%?%'

--Updated everything that had a question mark
--I researched the correct names of artists and songs and updated the values accordingly
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

--Next I saw that tempos were wrong
/*Updating wrong tempo's above 130bpm 
to be halved because majority of true tempos above 130 are halved
I had to research each song on a case by case basis to make sure each tempo was being updated correctly.*/
UPDATE topspotifyeighteen
SET tempo = tempo/2
WHERE tempo > 130

--ROUNDING THE TEMPOS
UPDATE topspotifyeighteen
SET tempo = ROUND(tempo)

--Going through and updating the next set of tempos that are wrong
SELECT songid, name, artists, tempo
FROM TOPSPOTIFYEIGHTEEN
ORDER BY tempo desc

--Going through tempos again and updating tempos for other artists who's tempos were incorrect
UPDATE topspotifyeighteen
SET tempo = tempo/2
WHERE tempo > 116 AND artists IN ('XXXTENTACION', '6ix9ine', 'Post Malone', 'Lil Baby')

/*Converting the time of duration*/
--ms to seconds conversion
UPDATE topspotifyeighteen
SET duration_ms = duration_ms * .001;
--seconds to minutes conversion
UPDATE topspotifyeighteen
SET duration_ms = duration_ms/60
--Rounding to nearest hundredth
UPDATE topspotifyeighteen
SET duration_ms = ROUND(duration_ms, 1)
--change name because we have converted the values to minutes now
ALTER TABLE topspotifyeighteen
RENAME COLUMN duration_ms to duration_mins


/* Wanted to make danceability, energy, and speechiness 
whole numbers so it was in a format that was easier to
read and compare rather than having it as a decimal*/

UPDATE topspotifyeighteen
SET danceability = ROUND(danceability * 100)
UPDATE topspotifyeighteen
SET energy = ROUND(energy * 100)
UPDATE topspotifyeighteen
SET speechiness = ROUND(speechiness * 100)

/*All data values had a parenthesis instead of [ when listing features so I changed the one value with [ to parenthesis
to be consistent with the rest of the data*/
--fixed cardi b to have ( instead of [
UPDATE topspotifyeighteen
SET name = 'Finesse Remix (feat. Cardi B)'
WHERE songid = '47'

--THIS MARKS THE END OF THE DATA CLEANING PROCESS

/*This next section is where I began my aggregate/manipulative functions
in order to extract insights from the data*/


/*Out of the top 100 most streamed songs, 
What artist had the most entries of of this list, filtered by artists who have at least 2 entries.
*/

SELECT artists, COUNT(artists)
FROM topspotifyeighteen
GROUP BY artists
HAVING COUNT(artists) >= 2
ORDER BY COUNT(artists) DESC

/*Looking at the most FEATURED artist
Every song used a term that said "FEAT" or "WITH"
filtered for featured artists*/
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

/*Used SUBSTR formula to take away parenthesis 
so you can see just the featured artists
AND then I stored it into a CTE*/
WITH CTE_featuredartists AS
(SELECT SUBSTRING(name FROM POSITION('(' IN name)) AS features
FROM
	(SELECT name
	FROM topspotifyeighteen
	WHERE name LIKE '%feat%'
		OR name LIKE '%with%') AS ftartists)
SELECT SUBSTRING(features FROM POSITION(' ' IN features) FOR POSITION(')' IN features) - POSITION(' ' IN features)) AS substringofcte
FROM CTE_featuredartists

/*Wanted to use this list as a temp table
A temptable of featured artists from the original dataset*/
--created temp table
CREATE TEMP TABLE temp_featuredartists (features varchar)

--inserted cte into temp table
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

/*Temptable created and count all features, 
This doesnt accurately depict the count of an artist who may have been a part of a song with multiple featured artists*/
SELECT features, COUNT(features)
FROM temp_featuredartists
GROUP BY features
ORDER BY COUNT(features) DESC

/*We see Cardi B had the most stand alone features but we also saw
that there were features that listed more than just one artist*/

/*Used this query below to filter for the artists that came up more than once
in the above query to get a more accurate count of artists features, which includes
not just standalone features but multiple features on one song*/
Halsey and Khalid tied for 2nd most features.
Cardi B still had the highest amount of features when counting not just her singlular features where
she was the only artist on a song but counting features from multiple people
being on one song*/

SELECT COUNT(features), features
FROM temp_featuredartists
WHERE features LIKE '%Khalid%'
	OR features LIKE '%Selena%'
	OR features LIKE '%Cardi B%'
	OR features LIKE '%Halsey%'
GROUP BY features

/*Next I wanted to look at tempos*/

--Looking at the average tempo
SELECT AVG(tempo)
FROM topspotifyeighteen

/*Using a CASE statement to put each tempo into a range and see what tempo range was the most popular of the year 2018*/
--popular tempo ranges
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

/*These were the songs of the most popular tempo range*/
SELECT songid, *
FROM topspotifyeighteen
WHERE tempo BETWEEN 90 AND 99

/*Using a windows function to see the average danceability rating of the most popular tempo range*/
SELECT *, AVG(danceability) OVER (PARTITION BY ninetystempo)
FROM
	(SELECT tempo, danceability, 
	CASE
		WHEN tempo between 90 AND 99 THEN '90s'
	END AS ninetystempo
	FROM topspotifyeighteen
	WHERE tempo BETWEEN 90 AND 99) subq

/* Looking atThe most popular specific tempo of the most popukar tempo range */

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



/*As I got into the more aggregate functions below looking at averages in comparison to artists and such, I would filter for artists
with more than two entries to avoid an unrealistic skew in the data. One artist could have a very high rating for one of these attributes but
only have that one song so it would essentially be inaccurate to call them the "most danceable" or "most energetic" artist since their
one entry doesn't hold as much weight in comparison to artists with more consistent entries*/


/*The rounded average danceability of an artist who has more than one entry
in this dataset*/
SELECT artists, ROUND(AVG(danceability))
FROM topspotifyeighteen
GROUP BY artists
HAVING COUNT(artists) > 2

/*Similar to the query above except in partition form and shows the average dance rating for
all tracks. We can look at this side by side with the artist, amount of entries for the artist (filtered for artists with more than two entries).
and the avg danceability of each artist*/
SELECT *
FROM
	(SELECT artists,
	 COUNT(artists) OVER (PARTITION BY artists) artistentries,
	AVG(danceability) OVER (PARTITION BY artists) avgdanceperartist,
	 AVG(danceability) OVER() avgdance
	FROM topspotifyeighteen) dancepartitions
WHERE artistentries > 2 
ORDER BY artistentries DESC, avgdanceperartist DESC


/*Looking for the most streamed artists except filtering for artists that not only have more than two entries
but also a higher than average dance rating */
SELECT *
FROM
	(SELECT artists,
	 COUNT(artists) OVER (PARTITION BY artists) artistentries,
	AVG(danceability) OVER (PARTITION BY artists) avgdanceperartist,
	 AVG(danceability) OVER() avgdance
	FROM topspotifyeighteen) dancepartitions
WHERE artistentries > 2 AND avgdanceperartist > avgdance
ORDER BY artistentries DESC, avgdanceperartist DESC


/*Looking for the most streamed artists except filtering for artists that not only have more than two entries
but also a higher than average energy rating*/
--majority of these top entry artist's energy ratings are below avg
SELECT *
FROM
	(SELECT artists,
	 COUNT(artists) OVER (PARTITION BY artists) artistentries,
	AVG(energy) OVER (PARTITION BY artists) avgenergyperartist,
	 AVG(energy) OVER() avgenergy
	FROM topspotifyeighteen) energypartitions
WHERE artistentries > 2 AND avgenergyperartist > avgenergy
ORDER BY artistentries DESC, avgenergyperartist DESC

--Looking at which tempo range has the highest average dancability rating while also comparing it to the amount of entries per tempo range
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


--Looking at the average danceability rating for tempo ranges from highest to lowest average danceability rating using GROUP BY
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

/*Looking at the average energy ratings in comparison to tempo ranges and ordering the results to see the highest average energy rating in descending order
for each tempo range*/
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


/*Looking at the list of all of the songs with a higher than average duration in minutes*/
SELECT name, duration_mins, 
(SELECT AVG(duration_mins) FROM topspotifyeighteen) avgsongduration
FROM topspotifyeighteen
WHERE duration_mins >
	(SELECT AVG(duration_mins)
	FROM topspotifyeighteen) 
ORDER BY duration_mins DESC

/*Seeing who the speechiest artists were*/
SELECT artists, name, speechiness
FROM topspotifyeighteen
WHERE speechiness >
	(SELECT AVG(speechiness)
	FROM topspotifyeighteen)
ORDER BY speechiness DESC

/* Looking at the artists with greater than average energy ratings that also had more than one entry in this dataset*/
SELECT artists, COUNT(artists)
FROM topspotifyeighteen topspot
JOIN (SELECT AVG(energy) avge FROM topspotifyeighteen) avgesubq
	ON topspot.energy > avgesubq.avge
GROUP BY artists
ORDER BY COUNT(artists) DESC

/*
Essentially looking at artists with higher than average danceability records that have more than two records
Looking at the most danceable artists and songs of the year*/
WITH CTE_dancy AS
(SELECT name, artists, danceability, 
 COUNT(artists) OVER (PARTITION BY artists) artistcount
FROM topspotifyeighteen topspot
JOIN (SELECT AVG(danceability) avgd FROM topspotifyeighteen) avgdsubq
	ON topspot.danceability >= avgdsubq.avgd)
SELECT *
FROM CTE_dancy
WHERE artistcount > 2
ORDER BY artistcount DESC

/*Looking at artists with higher than avg energy rating and more than one entry in the dataset*/
WITH CTE_energy AS
(SELECT name, artists, energy, 
 COUNT(artists) OVER (PARTITION BY artists) artistcount
FROM topspotifyeighteen topspot
JOIN (SELECT AVG(energy) avge FROM topspotifyeighteen) avgesubq
	ON topspot.energy >= avgesubq.avge)
SELECT *
FROM CTE_energy
WHERE artistcount > 1
ORDER BY artistcount DESC

/*Looking at the top 5 danciest songs*/
SELECT *
FROM topspotifyeighteen
ORDER BY danceability DESC
LIMIT 5

/*Looking at the top 5 most energetic songs*/
SELECT *
FROM topspotifyeighteen
ORDER BY energy DESC
LIMIT 5

/*Queries for correlation visualization below*/
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
