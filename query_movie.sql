--Find the titles of all movies directed by Steven Spielberg.
SELECT title FROM movie
WHERE director LIKE "%Spielberg"

--Find all years that have a movie that received a rating of 4 or 5,
--and sort them in increasing order.
SELECT DISTINCT m.year
FROM movie m JOIN Rating r
ON m.mID = r.mID
WHERE r.stars = 4 OR r.stars = 5
ORDER BY m.year;

--Find the titles of all movies that have no ratings
SELECT DISTINCT title
FROM movie
WHERE mID NOT IN (
	SELECT mID FROM rating
);

--Some reviewers didn't provide a date with their rating.
--Find the names of all reviewers who have ratings with a NULL value for the date.
SELECT DISTINCT Re.name
FROM rating Ra JOIN reviewer Re ON Re.rid = Ra.rid
WHERE Ra.ratingdate IS NULL;

--Write a query to return the ratings data in a more readable format: reviewer name,
--movie title, stars, and ratingDate. Also, sort the data, first by reviewer name,
--then by movie title, and lastly by number of stars.
SELECT Re.name, M.title, Ra.stars, Ra.ratingDate 
FROM (Reviewer Re JOIN Rating Ra ON Re.rID = Ra.rID) JOIN Movie M ON Ra.mID = M.mID
ORDER BY Re.name, M.title, Ra.stars;

--For all cases where the same reviewer rated the same movie twice and gave it
--a higher rating the second time, return the reviewer's name
--and the title of the movie.
SELECT DISTINCT Re.name, M.title
FROM (Rating Ra JOIN Reviewer Re ON Ra.rID = Re.rID) JOIN Movie M on Ra.mID = M.mID
WHERE Re.rID IN (
    SELECT DISTINCT Ra1.rID 
    FROM Rating Ra1 INNER JOIN Rating Ra2 ON Ra1.rID = Ra2.rID AND Ra1.ratingDate < Ra2.ratingDate
    WHERE Ra1.stars < Ra2.stars AND Ra1.mID = Ra2.mID
);

--For each movie that has at least one rating, find the highest number of stars that movie received.
--Return the movie title and number of stars. Sort by movie title.
SELECT M.title, MAX(Ra.stars)
FROM Movie M JOIN Rating Ra ON M.mID = Ra.mID
GROUP BY M.title;

--For each movie, return the title and the 'rating spread', that is, the difference between highest
--and lowest ratings given to that movie. Sort by rating spread from highest to lowest, then by movie title.
SELECT M.title, MAX(Ra.stars) - MIN(Ra.stars) AS rating_spread
FROM Movie M JOIN Rating Ra ON M.mID = Ra.mID
GROUP BY M.title
ORDER BY rating_spread DESC, M.title;

--Find the difference between the average rating of movies released before 1980 and the average rating of movies
--released after 1980. (Make sure to calculate the average rating for each movie, then the average of those averages
--for movies before 1980 and movies after. Don't just calculate the overall average rating before and after 1980.)
SELECT ABS( AVG(
    CASE
	WHEN year <= 1980 THEN rating_average ELSE NULL
	END
) - 
	AVG (
    CASE
	WHEN year > 1980 THEN rating_average ELSE NULL
	END
) ) AS difference
FROM (
SELECT M.mID, M.year, AVG(Ra.stars) AS rating_average
FROM Movie M JOIN Rating Ra ON M.mID = Ra.mID
GROUP BY M.mID, M.year
);

--EXTRAS:
--Find the names of all reviewers who rated Gone with the Wind.
SELECT DISTINCT Re.name
FROM Reviewer Re JOIN Rating Ra on Re.rID = Ra.rID
WHERE Ra.mID = (
    SELECT mID
    FROM Movie
    WHERE title LIKE 'Gone with the Wind'
    );

--For any rating where the reviewer is the same as the director of the movie,
--return the reviewer name, movie title, and number of stars.
SELECT Re.name, M.title, Ra.stars
FROM (Reviewer Re JOIN Rating Ra ON Re.rID = Ra.rID) JOIN Movie M ON Ra.mID = M.mID
WHERE Re.name = M.director;

--Return all reviewer names and movie names together in a single list, alphabetized.
--(Sorting by the first name of the reviewer and first word in the title is fine;
--no need for special processing on last names or removing "The".)
(SELECT name AS names
FROM Reviewer)
UNION
(SELECT title AS names
FROM Movie)
ORDER BY names;

--Find the titles of all movies not reviewed by Chris Jackson.
SELECT title
FROM Movie
WHERE mID NOT IN (
    SELECT M.mID
    FROM (Reviewer Re JOIN Rating Ra ON Re.rID = Ra.rID) JOIN Movie M ON Ra.mID = M.mID
    WHERE Re.name LIKE 'Chris Jackson'
)

--For all pairs of reviewers such that both reviewers gave a rating to the same movie,
--return the names of both reviewers. Eliminate duplicates, don't pair reviewers with themselves,
--and include each pair only once. For each pair, return the names in the pair in alphabetical order.
SELECT DISTINCT
    CASE WHEN Re1.name < Re2.Name THEN Re1.name ELSE Re2.name END AS name_1,
    CASE WHEN Re1.name < Re2.Name THEN Re2.name ELSE Re1.name END AS name_2
FROM ((Rating Ra1 INNER JOIN Rating Ra2 ON Ra1.mID = Ra2.mID AND Ra1.rID < Ra2.rID)
JOIN Reviewer Re1 ON Re1.rID = Ra1.rID) JOIN Reviewer Re2 ON Re2.rID = Ra2.rID
GROUP BY name_1, name_2
ORDER BY name_1, name_2;

--For each rating that is the lowest (fewest stars) currently in the database,
--return the reviewer name, movie title, and number of stars.
SELECT Re.name, M.title, Ra.stars
    FROM (Reviewer Re JOIN Rating Ra ON Re.rID = Ra.rID) JOIN Movie M ON Ra.mID = M.mID
    WHERE Ra.stars = ( SELECT MIN(stars)FROM Rating);

--List movie titles and average ratings, from highest-rated to lowest-rated.
--If two or more movies have the same average rating, list them in alphabetical order.
SELECT M.title, AVG(Ra.stars) AS rating_average
FROM Movie M JOIN Rating Ra ON M.mID = Ra.mID
GROUP BY M.title
ORDER BY rating_average DESC, M.title;

--Find the names of all reviewers who have contributed three or more ratings.
--(As an extra challenge, try writing the query without HAVING or without COUNT.)
SELECT Re.name
FROM Reviewer Re
WHERE Re.rID IN (
    SELECT Ra.rID
    FROM Rating Ra
    GROUP BY Ra.rID
    HAVING COUNT(Ra.rID) >= 3
);

--Some directors directed more than one movie. For all such directors,
--return the titles of all movies directed by them, along with the director name.
--Sort by director name, then movie title.
--(As an extra challenge, try writing the query both with and without COUNT.)
SELECT M.title, M.director
FROM Movie M
WHERE M.director IN (
    SELECT M1.director
    FROM Movie M1
    GROUP BY M1.director
    HAVING COUNT(M1.director) > 1
)
ORDER BY M.director, M.title;

--Find the movie(s) with the highest average rating. Return the movie title(s)
--and average rating. (Hint: This query is more difficult to write in SQLite
--than other systems; you might think of it as finding the highest average rating
--and then choosing the movie(s) with that average rating.)

SELECT M1.title, AVG(Ra.stars) AS rating_average1
FROM Movie M1 JOIN Rating Ra ON M1.mID = Ra.mID
GROUP BY M1.title
HAVING M1.title IN (
SELECT M.title
FROM Movie M JOIN Rating Ra ON M.mID = Ra.mID
GROUP BY M.title
ORDER BY AVG(Ra.stars) DESC
LIMIT 1
)

--Find the movie(s) with the lowest average rating. Return the movie title(s) and average rating.
--(Hint: This query may be more difficult to write in SQLite than other systems;
--you might think of it as finding the lowest average rating and then choosing the movie(s) with that average rating.)
SELECT M1.title, AVG(Ra.stars) AS rating_average1
FROM Movie M1 JOIN Rating Ra ON M1.mID = Ra.mID
GROUP BY M1.title
HAVING M1.title IN (
SELECT M.title
FROM Movie M JOIN Rating Ra ON M.mID = Ra.mID
GROUP BY M.title
ORDER BY AVG(Ra.stars)
LIMIT 1
)

--For each director, return the director's name together with the title(s) of the movie(s) they directed that
--received the highest rating among all of their movies, and the value of that rating. Ignore movies whose director is NULL.

SELECT DISTINCT 
    m.director,
    m.title,
    r.stars AS rating
FROM 
    Movie m
JOIN 
    Rating r ON m.mID = r.mID
WHERE 
    m.director IS NOT NULL
    AND r.stars = (
        SELECT MAX(r2.stars)
        FROM Rating r2
        JOIN Movie m2 ON m2.mID = r2.mID
        WHERE m2.director = m.director
    )
ORDER BY 
    m.director, m.title;

--Add the reviewer Roger Ebert to your database, with an rID of 209.
INSERT INTO Reviewer values(209, 'Roger Ebert')

--For all movies that have an average rating of 4 stars or higher, add 25 to the release year.
--(Update the existing tuples; don't insert new tuples.)
UPDATE Movie
SET year = year + 25
WHERE mID IN (
    SELECT mID
    FROM Rating
    GROUP BY mID
    HAVING AVG(stars) >= 4
);

--Remove all ratings where the movie's year is before 1970
--or after 2000, and the rating is fewer than 4 stars.
DELETE
FROM Rating
WHERE stars < 4
AND mID IN (
    SELECT mID
    FROM Movie
    WHERE year < 1970 OR year > 2000
);