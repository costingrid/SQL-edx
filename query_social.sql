--Find the names of all students who are friends with someone named Gabriel.
SELECT H.name
FROM Highschooler H JOIN Friend F ON H.ID = F.ID1
WHERE F.ID2 IN (
    SELECT H1.ID
    FROM Highschooler H1
    WHERE H1.name = 'Gabriel'
);

--For every student who likes someone 2 or more grades younger than themselves,
--return that student's name and grade, and the name and grade of the student they like.
SELECT H1.name, H1.grade, H2.name, H2.grade
FROM ((Highschooler H1 JOIN Likes L ON H1.ID = L.ID1) JOIN Highschooler H2 ON L.ID2 = H2.ID)
WHERE H1.grade - H2.grade >= 2;

--For every pair of students who both like each other, return the name and grade of both students.
--Include each pair only once, with the two names in alphabetical order.
SELECT 
CASE WHEN H1.name < H2.name THEN H1.name ELSE H2.name END AS name_1,
H1.grade,
CASE WHEN H1.name < H2.name THEN H2.name ELSE H1.name END AS name_2,
H2.grade
FROM (Highschooler H1 JOIN Likes L ON H1.ID = L.ID1) JOIN Highschooler H2 ON L.ID2 = H2.ID AND H1.ID < H2.ID
WHERE H2.ID IN (
    SELECT L1.ID1
    FROM Likes L1
    WHERE L1.ID2 = H1.ID
);

--Find all students who do not appear in the Likes table (as a student who likes or is liked) and return their names and grades.
--Sort by grade, then by name within each grade.
SELECT H.name, H.grade
FROM Highschooler H
WHERE H.ID NOT IN (
    SELECT L.ID1
    FROM Likes L
)
AND H.ID NOT IN (
    SELECT L.ID2
    FROM Likes L
)
ORDER BY H.grade, H.name;

--For every situation where student A likes student B, but we have no information about whom B likes
--(that is, B does not appear as an ID1 in the Likes table), return A and B's names and grades.
SELECT H1.name, H1.grade, H2.name, H2.grade
FROM ((Highschooler H1 JOIN Likes L ON H1.ID = L.ID1) JOIN Highschooler H2 ON L.ID2 = H2.ID)
WHERE H2.ID NOT IN (
    SELECT L1.ID1
    FROM Likes L1
);

--Find names and grades of students who only have friends in the same grade.
--Return the result sorted by grade, then by name within each grade.
SELECT H.name, H.grade
FROM Highschooler H
WHERE H.ID NOT IN (
    SELECT F.ID1
    FROM Friend F JOIN Highschooler H1 ON F.ID2 = H1.ID
    WHERE H1.grade != H.grade
)
AND H.ID NOT IN (
    SELECT F.ID2
    FROM Friend F JOIN Highschooler H2 ON F.ID1 = H2.ID
    WHERE H2.grade != H.grade
)
ORDER BY H.grade, H.name;

--For each student A who likes a student B where the two are not friends,
--find if they have a friend C in common (who can introduce them!).
--For all such trios, return the name and grade of A, B, and C.
SELECT 
    ha.name AS A_name,
    ha.grade AS A_grade,
    hb.name AS B_name,
    hb.grade AS B_grade,
    hc.name AS C_name,
    hc.grade AS C_grade
FROM 
    Likes l
JOIN 
    Highschooler ha ON l.ID1 = ha.ID
JOIN 
    Highschooler hb ON l.ID2 = hb.ID
JOIN 
    Friend f1 ON f1.ID1 = ha.ID
JOIN 
    Friend f2 ON f2.ID1 = hb.ID AND f1.ID2 = f2.ID2
JOIN 
    Highschooler hc ON f1.ID2 = hc.ID
WHERE 
    NOT EXISTS (
        SELECT 1
        FROM Friend f
        WHERE f.ID1 = ha.ID AND f.ID2 = hb.ID
    )
ORDER BY 
    A_name, B_name, C_name;

--Find the difference between the number of students in the school and the
--number of different first names.
SELECT (
    SELECT COUNT(*)
    FROM Highschooler
) - (
    SELECT COUNT(DISTINCT name)
    FROM Highschooler
)

--Find the name and grade of all students who are liked by more than one other student.
SELECT H.name, H.grade
FROM Highschooler H
WHERE H.ID IN (
    SELECT L.ID2
    FROM Likes L
    GROUP BY L.ID2
    HAVING COUNT(*) > 1
);

--For every situation where student A likes student B, but student B likes a different student C,
--return the names and grades of A, B, and C.
SELECT 
    ha.name AS A_name,
    ha.grade AS A_grade,
    hb.name AS B_name,
    hb.grade AS B_grade,
    hc.name AS C_name,
    hc.grade AS C_grade
FROM 
    Likes l1
JOIN 
    Likes l2 ON l1.ID2 = l2.ID1
JOIN 
    Highschooler ha ON l1.ID1 = ha.ID
JOIN 
    Highschooler hb ON l1.ID2 = hb.ID
JOIN 
    Highschooler hc ON l2.ID2 = hc.ID
WHERE 
    l1.ID1 <> l2.ID2;

--ind those students for whom all of their friends are in different grades from themselves.
--Return the students' names and grades.
SELECT H.name, H.grade
FROM Highschooler H
WHERE H.ID NOT IN (
    SELECT F.ID1
    FROM Friend F JOIN Highschooler H1 ON F.ID2 = H1.ID
    WHERE H1.grade = H.grade
)

--What is the average number of friends per student? (Your result should be just one number.)
SELECT AVG(friends)
FROM (
    SELECT COUNT(*) AS friends
    FROM Friend
    GROUP BY ID1
);

--Find the number of students who are either friends with Cassandra
--or are friends of friends of Cassandra. Do not count Cassandra,
--even though technically she is a friend of a friend.
SELECT COUNT(DISTINCT ID1)
FROM Friend
WHERE ID1 != (
    SELECT ID
    FROM Highschooler
    WHERE name = 'Cassandra'
)
AND (ID1 IN (
    SELECT ID2
    FROM Friend
    WHERE ID1 = (
        SELECT ID
        FROM Highschooler
        WHERE name = 'Cassandra'
    )
)
OR ID1 IN (
    SELECT ID2
    FROM Friend
    WHERE ID1 IN (
        SELECT ID2
        FROM Friend
        WHERE ID1 = (
            SELECT ID
            FROM Highschooler
            WHERE name = 'Cassandra'
        )
    )
));

--Find the name and grade of the student(s) with the greatest number of friends.
SELECT H.name, H.grade
FROM Highschooler H
WHERE H.ID IN (
    SELECT ID1
    FROM Friend
    GROUP BY ID1
    HAVING COUNT(*) = (
        SELECT MAX(friends)
        FROM (
            SELECT COUNT(*) AS friends
            FROM Friend
            GROUP BY ID1
        )
    )
);

--It's time for the seniors to graduate. Remove all 12th graders from Highschooler.
DELETE 
FROM Highschooler
WHERE grade = 12;

--If two students A and B are friends, and A likes B but not vice-versa, remove the Likes tuple.
DELETE FROM Likes
WHERE (ID1, ID2) IN (
    SELECT l1.ID1, l1.ID2
    FROM Likes l1
    JOIN Friend f ON l1.ID1 = f.ID1 AND l1.ID2 = f.ID2
    LEFT JOIN Likes l2 ON l1.ID2 = l2.ID1 AND l1.ID1 = l2.ID2
    WHERE l2.ID1 IS NULL
);

--For all cases where A is friends with B, and B is friends with C, add a new friendship for the pair A and C.
--Do not add duplicate friendships, friendships that already exist, or friendships with oneself.
--(This one is a bit challenging; congratulations if you get it right.)
INSERT INTO Friend (ID1, ID2)
SELECT DISTINCT f1.ID1, f2.ID2
FROM Friend f1, Friend f2
WHERE f1.ID2 = f2.ID1
  AND f1.ID1 <> f2.ID2
  AND NOT EXISTS (
      SELECT 1
      FROM Friend f3
      WHERE f3.ID1 = f1.ID1 AND f3.ID2 = f2.ID2
  );