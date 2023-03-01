/*This EDA was split up into two parts.
The first part was me cleaning/updating/transforming the data 
& changing data types. 
The second half was me doing more aggregational & functional queries 
in order to see the create insights from this dataset*/


/*I started with updating/changing the ID column. Each entry in the table had a distinct 21 character alphanumeric 
name as its "ID". For the sake of updating these records I could see how these specific ID's could be helpful in a security sense.
However, to avoid confusion and make it easier to keep track of the entries in this table I 
replaced this column with specific ID numbers for each entry.*/

ALTER TABLE topspotifyeighteen ADD songid SERIAL PRIMARY KEY;

ALTER TABLE topspotifyeighteen
DROP COLUMN id


--Cleaning data with question marks
/*From here I began to clean the data, starting with question marks.
Instant red flag.*/
/*Some data had question marks in their values that were not supposed to be there,
I researched the correct names of artists and songs and updated
the values accordingly */ 

/*Used this query to filter for every value in name column 
and artists column that has a question mark */

SELECT songid, name, artists
FROM topspotifyeighteen
WHERE name LIKE '%?%'
	OR artists LIKE '%?%'

--updated everything that had a question mark
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
to be halved because typically tempos above 130, their true bpm is halved*/
UPDATE topspotifyeighteen
SET tempo = tempo/2
WHERE tempo > 130

--ROUNDING THE TEMPOS
UPDATE topspotifyeighteen
SET tempo = ROUND(tempo)

--go through and update the next set of tempos that are wrong
SELECT songid, name, artists, tempo
FROM TOPSPOTIFYEIGHTEEN
ORDER BY tempo desc

--update tempos for other artists who I saw tempo was wrong
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
--change name cause its minutes now
ALTER TABLE topspotifyeighteen
RENAME COLUMN duration_ms to duration_mins
--wanna round to nearest hundredth
UPDATE topspotifyeighteen
SET duration_mins = ROUND(duration_mins, 1)

/* Wanted to make danceability, energy, and speechiness 
whole numbers so it was in a format that was easier to
read and compare rather than having it as a decimal*/

UPDATE topspotifyeighteen
SET danceability = ROUND(danceability * 100)
UPDATE topspotifyeighteen
SET energy = ROUND(energy * 100)
UPDATE topspotifyeighteen
SET speechiness = ROUND(speechiness * 100)

/*All datasets had a parenthesis instead of [ so I changed the one with [ to parenthesis
to be consistent with the rest of the data*/
--fixed cardi b to have ( instead of [
UPDATE topspotifyeighteen
SET name = 'Finesse Remix (feat. Cardi B)'
WHERE songid = '47'



/*This next section is where I began my aggregate/manipulative functions
in order to extract insights from the data*/


/*Out of the top 100 most streamed songs, 
Who had the most entries of of this list
We dont want to see anyone with anything less than 2 entries on this list*/

SELECT artists, COUNT(artists)
FROM topspotifyeighteen
GROUP BY artists
HAVING COUNT(artists) >= 2
ORDER BY COUNT(artists) DESC

/*I wanted to see who the most FEATURED artist was which took more work
than I thought it would*/

/*Every song used a term that said "FEAUTURE" or "WITH"*/
/*filtered for featured artists, one has () and other has [] but both have feat or with in it
so I used that */
SELECT name
FROM topspotifyeighteen
WHERE name LIKE '%feat%'
	OR name LIKE '%with%'

--substring to seperate artists
SELECT name, SUBSTRING(name FROM POSITION('(' IN name)) AS featuredartists
FROM
	(SELECT name
	FROM topspotifyeighteen
	WHERE name LIKE '%feat%'
		OR name LIKE '%with%') AS ftartists

/*Used SUBSTR formula to take away parenthesis 
so you can see just the featured artists
AND then I stored it into a CTE*/
--cte to store this, also in
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

/*temptable created and count all features, singular features, this doesnt count 
songs that more than one artist was featured on*/
SELECT features, COUNT(features)
FROM temp_featuredartists
GROUP BY features
ORDER BY COUNT(features) DESC

/*We see Cardi B had the most features but we also saw
that there are stand alone features and features that had more
than just one artist*/
/*Used this query to filter for the artists that came up more than once
in the above query to get a more accurate count of artists features, which includes
not just standalone features but multiple features on one song*/

/*Halsey and Khalid tied for 2nd most features
while Cardi B still had the highest amount when  counting not just her singlular features where
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

--AVG TEMPO
SELECT AVG(tempo)
FROM topspotifyeighteen

/*Used this query to put each tempo into a range and see what tempo range
did the best in this dataset*/
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

/*90's by far...lets look into the 90's more
These were the songs of the most popular tempo range*/
SELECT songid, *
FROM topspotifyeighteen
WHERE tempo BETWEEN 90 AND 99

/*Average danceability rating of the most popular tempo range*/
SELECT *, AVG(danceability) OVER (PARTITION BY ninetystempo)
FROM
	(SELECT tempo, danceability, 
	CASE
		WHEN tempo between 90 AND 99 THEN '90s'
	END AS ninetystempo
	FROM topspotifyeighteen
	WHERE tempo BETWEEN 90 AND 99) subq

/*Most popular tempo range that year was 90's
Of that tempo range what tempo exactly was the most popylar
The most popular tempo of that range was 95*/

SELECT tempo, COUNT(tempo)
FROM topspotifyeighteen
WHERE tempo BETWEEN 90 AND 99
GROUP BY tempo
ORDER BY COUNT(tempo) DESC


--looking at key thats most popular
SELECT key, COUNT(key)
FROM topspotifyeighteen
GROUP BY key
ORDER BY COUNT(key) DESC



/*As I got into the more aggregate functions below looking at averages in comparison to artists and such, I would filter for artists
with more than two entries to avoid an unrealistic skew in the data. One artist could have a very high rating for one of these attributes but
only have that one song so it would essentially be inaccurate to call them the "mos danceable" or "most energetic" artist since their
one entry doesn't hold as much weight in comparison to artists with more consistent entries*/

--avgdanceabilitypertopartist
/*The rounded average danceability of an artist who has more than one entry
in this dataset*/
SELECT artists, ROUND(AVG(danceability))
FROM topspotifyeighteen
GROUP BY artists
HAVING COUNT(artists) > 2

/*Similar to the query above except in partition form and shows thr average dance rating for
all tracks.
Artist, amount of entries (filtered for artists with more than two entries).
The avg danceability of each artist,
And the average danceability overall for the entire dataset*/
SELECT *
FROM
	(SELECT artists,
	 COUNT(artists) OVER (PARTITION BY artists) artistentries,
	AVG(danceability) OVER (PARTITION BY artists) avgdanceperartist,
	 AVG(danceability) OVER() avgdance
	FROM topspotifyeighteen) dancepartitions
WHERE artistentries > 2 
ORDER BY artistentries DESC, avgdanceperartist DESC



/*Query below shows that of the top 6 artists
only two had an avgdance rating above average.
Same as the query above except filtering for artists that not only have more than two entries
but also a higher than average dance rating */
/*From this we see XXXTENTACION and Drake were the most danceable artists*/
SELECT *
FROM
	(SELECT artists,
	 COUNT(artists) OVER (PARTITION BY artists) artistentries,
	AVG(danceability) OVER (PARTITION BY artists) avgdanceperartist,
	 AVG(danceability) OVER() avgdance
	FROM topspotifyeighteen) dancepartitions
WHERE artistentries > 2 AND avgdanceperartist > avgdance
ORDER BY artistentries DESC, avgdanceperartist DESC



/*Did the same thing for the artists average energy ratings.
Looked at artists with more than two entries, the average energy per artists,
and average energy for the entire dataset, Looked at artists with above avg energy rating*/
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

/*avgdanceability for tempo ranges in partition by form
also with the count for each tempo range...*/
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

--avg danceability for tempo ranges in group by form
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

/*AVG energy per tempo range*/
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


/*All of the songs with a higher than average duration in minutes*/
SELECT name, duration_mins, 
(SELECT AVG(duration_mins) FROM topspotifyeighteen) avgsongduration
FROM topspotifyeighteen
WHERE duration_mins >
	(SELECT AVG(duration_mins)
	FROM topspotifyeighteen) 
ORDER BY duration_mins DESC

/*Speechiest artist*/
SELECT artists, name, speechiness
FROM topspotifyeighteen
WHERE speechiness >
	(SELECT AVG(speechiness)
	FROM topspotifyeighteen)
ORDER BY speechiness DESC

/* Songs with greater than average energy ratings from artists with more than one entry in this dataset*/
SELECT artists, COUNT(artists)
FROM topspotifyeighteen topspot
JOIN (SELECT AVG(energy) avge FROM topspotifyeighteen) avgesubq
	ON topspot.energy > avgesubq.avge
GROUP BY artists
ORDER BY COUNT(artists) DESC

/*Selects name, artist, danceability, and counts artists
Then uses a JOIN to look at the higher than avg danceability records
Put it into a CTE table then filters for artists with more than two records
Essentially looking at artists with higher than average danceability records that have more than two records
The most danceable artists and songs of the year*/
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

/*Most energetic artists
artists with higher than avg energy rating and more than one entry 
on the higher than avg energy rating list*/
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

/*top 5 danciest songs*/
SELECT *
FROM topspotifyeighteen
ORDER BY danceability DESC
LIMIT 5

/*top5 most energetic songs*/
SELECT *
FROM topspotifyeighteen
ORDER BY energy DESC
LIMIT 5

/*Queries for correlation visualizatio below*/
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