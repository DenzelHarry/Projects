/*This is an Exploratory Data Analysis project that takes a deep dive into Washington's Prescription Monitoring Program
Public Use Data. This data was created to improve patient care and stop prescription drug misuse by collecting all dispensing records for 
Schedule II III IV drugs. The program started data collection from all dispensers October 7, 2011.
I used PostgreSQL to query this large dataset to gain insights and trends from this data with the intent of taking a thorough look at
data from the year of 2022. 
Skills used: Joins, Subqueries, Aggregate Functions, Windows Functions, CTE's, Temp Tables

The details on the collection, management, limitations of the data, schema, and the dataset itself can be found at:
https://data.wa.gov/health/Prescription-Monitoring-Program-PMP-Public-Use-Dat/8y5c-ekcc
*/

--This column was full of nulls so I deleted it from the table
ALTER TABLE wapmp DROP COLUMN drugname



--Took a look at individual generic drugs and the Schedules they are a part of
SELECT schedule, genericdrugname
FROM wapmp
GROUP BY schedule, genericdrugname



--Querying to find the most common primary drug ingredient dispensed
SELECT drug, COUNT(drug)
FROM wapmp
GROUP BY drug
ORDER BY COUNT(drug) DESC



--Shows what Schedule had the most outgoing Rx's
SELECT schedule, COUNT(drugclass)
FROM wapmp
WHERE schedule IS NOT NULL
GROUP BY schedule
ORDER BY COUNT(drugclass) DESC



--Shows a trend in drugs that veterinatians were prescribing the most
SELECT drug, COUNT(drug)
FROM wapmp
WHERE prescribervet = 'y' 
	  AND drug IS NOT NULL
GROUP BY drug
ORDER BY COUNT(drug) DESC



/*An insight I found was that the ndc may vary for the same generic drug depending on its strength & manufacturer.
I aggregated the data to look at ndc's, genericdrugname, and drugnamewithstrength.
I listed them from most dispensed to least dispensed.*/
SELECT ndc, genericdrugname, drugnamewithstrength, COUNT(ndc)
FROM wapmp
GROUP BY ndc, genericdrugname, drugnamewithstrength
ORDER BY COUNT(ndc) DESC



/*I used the below query to aggregated the data to take a look at what drug class had the most outgoing Rx's and listed
each one in descending order*/
SELECT drugclass, COUNT(drugclass) AS drugclasssums
FROM wapmp
WHERE drugclass IS NOT NULL
GROUP BY drugclass
ORDER BY COUNT(drugclass) DESC



--Aggregated the data in an effort to create an insight based on what the most common drugnamewithstrength Rx was and what schedule it belonged to
SELECT t1.schedule, t1.drugnamewithstrength, MAX(drugnamestrcount) 
 FROM
	(SELECT schedule, drugnamewithstrength, COUNT(drugnamewithstrength) AS drugnamestrcount
		FROM wapmp
		GROUP BY schedule, drugnamewithstrength
		ORDER BY schedule ASC, COUNT(drugnamewithstrength) DESC) t1
GROUP BY schedule, drugnamewithstrength
ORDER BY MAX(drugnamestrcount) DESC



--Used HAVING to filter for generic drug names with a higher than average count of outgoing RX's while also taking a look at their drug class
SELECT drugclass, genericdrugname, COUNT(genericdrugname)
FROM wapmp
GROUP BY drugclass, genericdrugname
HAVING COUNT(*) >
			(SELECT AVG(gendrug)
			 FROM
				(SELECT drugclass, genericdrugname, COUNT(genericdrugname) AS gendrug
				 FROM wapmp
				 GROUP BY drugclass, genericdrugname) AS gendrugsubq) 
ORDER BY COUNT(genericdrugname) DESC


				 
/*Fortunately enough, all of the data came in one table. 
For the sake of completing a join I decided to use a subquery join look into 
higher than average refills & filtered for no abnormally high refills, no nulls, and no animals.*/
SELECT *
FROM wapmp wap
JOIN (SELECT AVG(refillsauthorized) avgrefill 
	  FROM wapmp) avgrefillsubq
	  ON wap.refillsauthorized > avgrefillsubq.avgrefill
WHERE refillsauthorized IS NOT NULL
	  AND refillsauthorized != 99
	  AND animal = 'n'
	

/*I could've achieved the same result by writing the above query differently. 
Instead of using a subquery as a JOIN I used one in the WHERE clause. This results in the same results. See below.*/
SELECT *
FROM
   (SELECT *
	FROM wapmp
	WHERE refillsauthorized >
		  (SELECT AVG(refillsauthorized) avgrefsub
		   FROM wapmp)) greatavgrefills
WHERE refillsauthorized IS NOT NULL
AND refillsauthorized != 99
AND animal = 'n'


	
--Looking at what refill count was prescribed the most
SELECT refillsauthorized, COUNT(refillsauthorized)
FROM wapmp wap
JOIN (SELECT AVG(refillsauthorized) avgrefill 
	  FROM wapmp) avgrefillsubq
	  ON wap.refillsauthorized > avgrefillsubq.avgrefill
WHERE refillsauthorized IS NOT NULL
	  AND refillsauthorized != 99
	  AND animal = 'n'
GROUP BY refillsauthorized
ORDER BY COUNT(refillsauthorized) DESC



--Of the higher than average refills count and most common refillsauthorized count being 5(from above query)...which drug was dispensed most
SELECT drug, COUNT(drug)
FROM wapmp wap
JOIN (SELECT AVG(refillsauthorized) avgrefill 
	  FROM wapmp) avgrefillsubq
	  ON wap.refillsauthorized > avgrefillsubq.avgrefill
WHERE refillsauthorized IS NOT NULL
	  AND refillsauthorized != 99
	  AND animal = 'n'
	  AND refillsauthorized = 5
GROUP BY drug
ORDER BY COUNT(drug) DESC



/*
I could've split this query into multiple queries to make it easier but for the love of SQL I wanted to challenge myself.
I wanted to create a query that:
-Looked at the drugs with greater than average dayssupply
-Of that result of greater than average number of dayssupply, what specific dayssupply had the highest count of outgoing Rx's
-Of that most popular dayssupply number, what were the most common drugs prescribed, listing them in descending order*/
SELECT drugnamewithstrength, COUNT(drugnamewithstrength)
FROM wapmp wap
JOIN (SELECT AVG(dayssupply) avgsup
	  FROM wapmp) avgsupsub
	  ON wap.dayssupply > avgsupsub.avgsup
WHERE dayssupply =
	(SELECT dayssupply
	FROM
		(SELECT dayssupply, COUNT(*) AS all
		FROM wapmp 
		GROUP BY dayssupply 
		HAVING COUNT(*) = 
			(SELECT MAX(supply) FROM
				(SELECT COUNT(dayssupply) AS supply
				 FROM wapmp
				 GROUP BY dayssupply) AS subq)) sub)
GROUP BY drugnamewithstrength
ORDER BY COUNT(drugnamewithstrength) DESC
/*Zolpidem was the result for both this query and the query above. Making me realize I found a trend.
I found a trend that Zolpidem was most commonly refilled 5 times and was most often prescribed for 30 days every refill.*/



/* I wanted to create an insight to see the most popular drug of this dataset by highest count in descending order, 
and of those drugs what the most popular specific drugs strengths were in each drug category, in descending order.
I also wanted to rank the subcategory of drug names & strengths for each drug. 
This led me to create a CTE with partitions.
*/
WITH CTE_popdrugstrength AS
(SELECT drug, mainingredientcount, drugnamewithstrength, popstrpermainingcount,
RANK() OVER(PARTITION BY drug ORDER BY popstrpermainingcount DESC) strrankpermainingredient
FROM
	(SELECT drug, 
	COUNT(drug) OVER (PARTITION BY drug) mainingredientcount,
	drugnamewithstrength,
	COUNT(drugnamewithstrength) OVER (PARTITION BY drug, drugnamewithstrength) popstrpermainingcount,
	ROW_NUMBER() OVER (PARTITION BY drug, drugnamewithstrength) r
	FROM wapmp) AS subq
WHERE r = 1
ORDER BY mainingredientcount DESC, popstrpermainingcount DESC)
SELECT *
FROM CTE_popdrugstrength
/*Found an interesting insight that Oxycodone was the most prescribed RX as far as drugs go but the specific RX of HYDROCODONE 5-325 
had the highest count of dispenses of any drug*/



--I wanted to filter the above query down to see the top 5 results of drug names & strengths for each drug
WITH CTE_popdrugstrength AS
(SELECT drug, mainingredientcount, drugnamewithstrength, popstrpermainingcount,
RANK() OVER(PARTITION BY drug ORDER BY popstrpermainingcount DESC) strrankpermainingredient
FROM
	(SELECT drug, 
	COUNT(drug) OVER (PARTITION BY drug) mainingredientcount,
	drugnamewithstrength,
	COUNT(drugnamewithstrength) OVER (PARTITION BY drug, drugnamewithstrength) popstrpermainingcount,
	ROW_NUMBER() OVER (PARTITION BY drug, drugnamewithstrength) r
	FROM wapmp) AS subq
WHERE r = 1
ORDER BY mainingredientcount DESC, popstrpermainingcount DESC)
SELECT *
FROM CTE_popdrugstrength
WHERE strrankpermainingredient <= 5



/*Using partitions to aggregate the Drugclass data to get an output showing drug classes with the highest count of outgoing Rx's in descending order
with corresponding ranks and percentages*/
SELECT drugclass, drugcount, 
RANK() OVER(ORDER BY drugcount DESC) AS drugclassrank,
(ROUND(CAST(drugcount AS numeric)/totalcount, 2)*100) AS drugpercent
FROM
	(SELECT drugclass, 
	COUNT(drugclass) OVER (PARTITION BY drugclass) AS drugcount,
	COUNT(drugclass) OVER() totalcount,
	ROW_NUMBER() OVER (PARTITION BY drugclass) AS r
	FROM wapmp) AS subq
WHERE r = 1 AND drugclass IS NOT NULL
ORDER BY drugcount DESC



/*Since Opioids are the most common drug class I wanted to look at the most common strength Rx's
that went out for this specific drug class*/
SELECT drugnamewithstrength, COUNT(drugnamewithstrength)
FROM wapmp
WHERE drugclass = 'Opioid'
GROUP BY drugnamewithstrength
ORDER BY COUNT(drugnamewithstrength) DESC



/*If Hydrocodone is the most common drug being dispensed for the drugclass with the highest outgoing Rx's, I wanted to look at how many refills are authorized
for Hydrocodone.
Looking at the average number of refillsauthorized for Hydrocodone Rxs filtering out nulls, implausibly high refill values, and animal Rx's
Assuming nulls mean no refills authorized for the Rx, only ~ 2500 hydrocodone Rx's had refills with the average number of refills being 1.9*/
SELECT AVG(refillsauthorized)
	 FROM wapmp
	 WHERE drugnamewithstrength = 'HYDROCODONE-ACETAMIN 5-325 MG' 
			AND refillsauthorized IS NOT NULL
			AND refillsauthorized <> 99
			AND animal = 'n'



--Wanted to look at the Hydrocodone records that have greater than avg refills authorized
SELECT *
FROM wapmp
WHERE refillsauthorized >
	(SELECT AVG(refillsauthorized)
	FROM wapmp)
	AND drugnamewithstrength = 'HYDROCODONE-ACETAMIN 5-325 MG' 
	AND refillsauthorized IS NOT NULL
	AND refillsauthorized != 99
	AND animal = 'n'
	
	
	
--Same as above except in join form...for the love of SQL.
SELECT *
FROM wapmp wap
JOIN (SELECT AVG(refillsauthorized) avgrefill 
	  FROM wapmp) avgrefillsubq
	  ON wap.refillsauthorized > avgrefillsubq.avgrefill
WHERE drugnamewithstrength = 'HYDROCODONE-ACETAMIN 5-325 MG' 
AND refillsauthorized IS NOT NULL
AND refillsauthorized < 89
AND animal = 'n'
ORDER BY refillsauthorized DESC



/*Created a Temporary Table for the sole purpose of aggregating data to find insights on different drug names/strengths in relation to the
specific drug class they belong to. I also included a rank for drug names and strengths with the highest total within each drug class.*/
CREATE TEMP TABLE temp_drugclassrankings
(DrugClass varchar (50),
DrugClassTotals numeric,
DrugNameWithStrength varchar (50),
DrugStrengthTotals numeric,
RankPerDrugClass numeric)

INSERT INTO temp_drugclassrankings
SELECT drugclass, drugclasstotals, drugnamewithstrength, strinclass,
RANK() OVER (PARTITION BY drugclass ORDER BY strinclass DESC) rankperdrugclass
FROM
	(SELECT drugclass, 
		   COUNT(drugclass) OVER (PARTITION BY drugclass) drugclasstotals,
		   drugnamewithstrength,
		   COUNT(drugnamewithstrength) OVER (PARTITION BY drugclass, drugnamewithstrength) AS strinclass,
		   ROW_NUMBER() OVER (PARTITION BY drugclass, drugnamewithstrength) AS r 
	FROM wapmp) AS dcsubq
WHERE r = 1
ORDER BY drugclasstotals DESC, strinclass DESC

SELECT *
FROM temp_drugclassrankings



--Using temp table created to filter for top 10 most popular drugs/strengths and the the drugclass they belong to
SELECT *
FROM temp_drugclassrankings
WHERE rankperdrugclass <= 10



/*Looking at a count of each generic drug name in descending order with their corresponding percentages*/
SELECT genericdrugname, gendrugpartcount, gendrugtotal, 
((CAST(gendrugpartcount AS numeric)/gendrugtotal)*100) AS popgendrugdec
FROM (SELECT genericdrugname,
	  COUNT(genericdrugname) OVER (PARTITION BY genericdrugname) AS gendrugpartcount,
	  COUNT(genericdrugname) OVER () AS gendrugtotal,
	  ROW_NUMBER() OVER (PARTITION BY genericdrugname) AS r
	 FROM wapmp) AS testsubq
WHERE testsubq.r = 1
ORDER BY gendrugpartcount DESC



--Looking at a percentage of how much of this data is about humans vs animals
WITH CTE_humansanimals AS
(SELECT species, countperspec, spectotal,
(ROUND(CAST(countperspec AS numeric)/spectotal, 2)*100) AS specpercent
FROM
	(SELECT species,
	COUNT(species) OVER (PARTITION BY species) AS countperspec,
	ROW_NUMBER() OVER (PARTITION BY species) AS rownum,
	COUNT(species) OVER () AS spectotal
	FROM wapmp) AS specsubq
WHERE rownum = 1)
SELECT *
FROM CTE_humansanimals




--Creating a temp table to look specifically at drugs with mme details. 
--Opioids specifically and only humans, no animal data
--Looking at totalmme, daily mme, mmefactor stuff

CREATE TEMP TABLE temps_mme
(drug VARCHAR,
drugclass VARCHAR,
 drugnamewithstrength VARCHAR,
 strengthperunit numeric,
 quantity numeric,
 dayssupply numeric,
 mmefactor numeric,
 totalmme numeric,
 dailymme numeric,
recordnumber VARCHAR)

INSERT INTO temps_mme
SELECT drug, drugclass, drugnamewithstrength, strengthperunit, quantity, dayssupply, mmefactor, totalmme, dailymme, recordnumber
FROM wapmp
WHERE mmefactor IS NOT NULL 
	  AND drugclass = 'Opioid'
	  AND species = '01'
	  AND animal = 'n'
	  


--Of all the Opioids with mmes, filter out for Rx's with higher than average mme strength per unit
SELECT drug, drugclass, drugnamewithstrength, strengthperunit, quantity, dayssupply, mmefactor, totalmme, dailymme, recordnumber
FROM temps_mme
WHERE strengthperunit >
	(SELECT AVG(strengthperunit)
	 FROM temps_mme)



--Of those higher than average strength per drugs, what drug had the highest count of rx's with the highest strengths per unit
SELECT drugnamewithstrength, strengthperunit, COUNT(drugnamewithstrength)
FROM
(SELECT drug, drugclass, drugnamewithstrength, strengthperunit, quantity, dayssupply, mmefactor, totalmme, dailymme, recordnumber
FROM temps_mme
WHERE strengthperunit >
	(SELECT AVG(strengthperunit)
	 FROM temps_mme)) AS highavgsubq
GROUP BY drugnamewithstrength, strengthperunit
ORDER BY COUNT(drugnamewithstrength) DESC, strengthperunit DESC



--Looking at drugs with higher than average mme factors and seeing which ones had the highest count with the highest mmefactor
SELECT drugnamewithstrength, COUNT(drugnamewithstrength), mmefactor
FROM
	(SELECT drug, drugclass, drugnamewithstrength, strengthperunit, quantity, dayssupply, mmefactor, totalmme, dailymme, recordnumber
	 FROM temps_mme
	 WHERE mmefactor >
		(SELECT AVG(mmefactor)
		 FROM temps_mme)) AS highavgmme
GROUP BY drugnamewithstrength, mmefactor
ORDER BY mmefactor DESC, COUNT(drugnamewithstrength) DESC



--Looking at what quarter had the most dispenses for drugs with higher than average mme factors
SELECT yearqtr, COUNT(yearqtr)
FROM wapmp
WHERE recordnumber IN
   (SELECT recordnumber
	FROM temps_mme
	WHERE mmefactor > 
		 (SELECT AVG(mmefactor)
		  FROM temps_mme))
GROUP BY yearqtr
ORDER BY COUNT(yearqtr) DESC



--Using CASE/WHEN to check total mme calculations
SELECT totalmme, totalmmecheck,
CASE
	WHEN totalmme = totalmmecheck THEN 'Correct Total'
	ELSE 'Incorrect Total'
END AS TotalMMEChecks
FROM
	(SELECT recordnumber, totalmme, strengthperunit*quantity*mmefactor AS totalmmecheck
	FROM temps_mme
	WHERE totalmme IS NOT NULL) AS subq
	
	
	
--Looking to see if there are any incorrect totals
SELECT *
FROM
	(SELECT totalmme, totalmmecheck,
	CASE
		WHEN totalmme = totalmmecheck THEN 'Correct Total'
		ELSE 'Incorrect Total'
	END AS TotalMMEChecks
	FROM
		(SELECT recordnumber, totalmme, strengthperunit*quantity*mmefactor AS totalmmecheck
		FROM temps_mme
		WHERE totalmme IS NOT NULL) AS subq) AS dubsubq
WHERE totalmmechecks != 'Correct Total'



--Looking at the records with higher than average TotalMME's
SELECT *
FROM temps_mme tem
JOIN (SELECT AVG(totalmme) avgmme FROM temps_mme) totalavgsubq
	ON tem.totalmme > totalavgsubq.avgmme
	
	
	
/*Looking at what drugs out of higher than average total mme list had a high count of RX's going out 
and a high total mme*/
SELECT drug, totalmme, COUNT(drug) drugcount
FROM
	(SELECT drug, drugclass, drugnamewithstrength, totalmme, recordnumber
	 FROM temps_mme tem
	 JOIN (SELECT AVG(totalmme) avgmme FROM temps_mme) totalavgsubq
		ON tem.totalmme > totalavgsubq.avgmme) AS higheravgmme
GROUP BY totalmme, drug
ORDER BY COUNT(drug) DESC, totalmme DESC




/*Ending thoughts*/
/* I contemplated splitting the drug information into a different table for the sake of doing more JOINS but since all the information was already in one table
I decided to use subquery joins instead. 
I would love to see data like this for each state or even the entire US as a whole to see what insights could be found.
If you have made it this far, I would like to say thank you for taking the time to look at this project. */
