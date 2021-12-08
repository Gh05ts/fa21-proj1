-- Before running drop any existing views
DROP VIEW IF EXISTS q0;
DROP VIEW IF EXISTS q1i;
DROP VIEW IF EXISTS q1ii;
DROP VIEW IF EXISTS q1iii;
DROP VIEW IF EXISTS q1iv;
DROP VIEW IF EXISTS q2i;
DROP VIEW IF EXISTS q2ii;
DROP VIEW IF EXISTS q2iii;
DROP VIEW IF EXISTS q3i;
DROP VIEW IF EXISTS q3ii;
DROP VIEW IF EXISTS q3ii_1;
DROP VIEW IF EXISTS q3iii;
DROP VIEW IF EXISTS q4i;
DROP VIEW IF EXISTS q4ii;
DROP VIEW IF EXISTS q4iii;
DROP VIEW IF EXISTS q4iv;
DROP VIEW IF EXISTS q4v;

-- Question 0
CREATE VIEW q0(era)
AS
  SELECT MAX(era)
  FROM pitching
;

-- Question 1i
CREATE VIEW q1i(namefirst, namelast, birthyear)
AS
  SELECT namefirst, namelast, birthyear
  FROM people
  WHERE weight > 300
;

-- Question 1ii
CREATE VIEW q1ii(namefirst, namelast, birthyear)
AS
  SELECT namefirst, namelast, birthyear
  FROM people
  WHERE namefirst LIKE '% %'
  ORDER BY namefirst, namelast
;

-- Question 1iii
CREATE VIEW q1iii(birthyear, avgheight, count)
AS
  SELECT birthyear, AVG(height) AS avgheight, COUNT(*)
  FROM people
  GROUP BY birthyear
  ORDER BY birthyear
;

-- Question 1iv
CREATE VIEW q1iv(birthyear, avgheight, count)
AS
  SELECT birthyear, AVG(height) AS avgheight, COUNT(*)
  FROM people
  GROUP BY birthyear
  HAVING avgheight > 70
  ORDER BY birthyear
;

-- Question 2i
CREATE VIEW q2i(namefirst, namelast, playerid, yearid)
AS
  SELECT namefirst, namelast, people.playerID AS playerid, yearid
  FROM people
  INNER JOIN halloffame
  USING(playerID)
  WHERE inducted = 'Y'
  ORDER BY yearid DESC, playerid
;

-- Question 2ii
CREATE VIEW q2ii(namefirst, namelast, playerid, schoolid, yearid)
AS SELECT namefirst, namelast, playerid, schoolid, yearid
  FROM q2i
  INNER JOIN (
    SELECT *
    FROM schools
    INNER JOIN collegeplaying
    USING(schoolID)
    WHERE schoolState = 'CA'
  )
  USING(playerID)
  ORDER BY yearid DESC, schoolid, playerid
;

-- Question 2iii
CREATE VIEW q2iii(playerid, namefirst, namelast, schoolid)
AS
  SELECT playerid, namefirst, namelast, schoolid
  FROM q2i
  LEFT JOIN collegeplaying
  USING(playerid)
  ORDER BY playerid DESC, schoolid 
;

-- Question 3i
CREATE VIEW q3i(playerid, namefirst, namelast, yearid, slg)
AS
  SELECT playerid, namefirst, namelast, yearid, CAST((H-(H2B+H3B+HR))+(2*H2B)+(3*H3B)+(4*HR) AS Float)/AB AS slg
  FROM people
  INNER JOIN batting
  USING(playerid)
  WHERE AB > 50
  ORDER BY slg DESC, yearid, playerid
  LIMIT 10
;

-- Question 3ii
CREATE VIEW q3ii_1(playerid, namefirst, namelast, lslg)
AS
  SELECT playerid, namefirst, namelast, CAST((lh-(lh2b+lh3b+lhr))+(2*lh2b)+(3*lh3b)+(4*lhr) AS Float)/lab AS lslg
  FROM people
  INNER JOIN (
    SELECT playerid, SUM(H) AS lh, SUM(H2B) AS lh2b, SUM(H3B) AS lh3b, SUM(HR) AS lhr, SUM(AB) AS lab
    FROM batting
    GROUP BY playerid
    HAVING lab > 50
  )
  USING(playerid)
  ORDER BY lslg DESC, playerid
;

CREATE VIEW q3ii(playerid, namefirst, namelast, lslg)
AS
  SELECT *
  FROM q3ii_1
  LIMIT 10
;
-- Question 3iii
CREATE VIEW q3iii(namefirst, namelast, lslg)
AS
  SELECT namefirst, namelast, lslg
  FROM q3ii_1
  WHERE lslg > (
    SELECT lslg
    FROM q3ii_1
    WHERE playerid = 'mayswi01'
  )
;

-- Question 4i
CREATE VIEW q4i(yearid, min, max, avg)
AS
  SELECT yearid, MIN(salary) AS 'min', MAX(salary) AS 'max', AVG(salary) AS 'avg'
  FROM salaries
  GROUP BY yearid
  ORDER BY yearid
;

-- Question 4ii
CREATE VIEW q4ii(binid, low, high, count)
AS
  WITH temp AS (
    SELECT CAST((salary - Q.min)/(((Q.max + 0.001) - Q.min)/10) AS INT) AS binid, COUNT(*) AS cnt
    FROM salaries AS S
    INNER JOIN q4i AS Q
    ON S.yearID = Q.yearID
    WHERE S.yearID = 2016
    GROUP BY binid
  ),
  low_tb AS (
    SELECT DISTINCT binid, Q.min + B.binid * ((Q.max - Q.min)/10) AS low
    FROM binids AS B, q4i AS Q
    WHERE Q.yearID = 2016
    GROUP BY binid
  ),
  high_tb AS (
    SELECT DISTINCT B.binid, 
    low, 
    CASE
      WHEN low + ((Q.max - Q.min)/10) < Q.max THEN CAST((low + ((Q.max - Q.min)/10)) AS VARCHAR(10))
      ELSE 'at least 33000000.0'
    END AS high
    FROM binids AS B
    LEFT JOIN low_tb AS LT
    ON B.binid = LT.binid,
    q4i AS Q
    WHERE Q.yearID = 2016
    GROUP BY B.binid
  )
  SELECT H.binid, low, high, cnt
  FROM high_tb AS H
  LEFT JOIN temp AS T
  ON H.binid = T.binid
;

-- Question 4iii
CREATE VIEW q4iii(yearid, mindiff, maxdiff, avgdiff)
AS
  SELECT yearid, min - LAG(min, 1) OVER(ORDER BY yearid), max - LAG(max, 1) OVER(ORDER BY yearid), avg - LAG(avg, 1) OVER(ORDER BY yearid)
  FROM q4i
  LIMIT -1 OFFSET 1
;

-- Question 4iv
CREATE VIEW q4iv(playerid, namefirst, namelast, salary, yearid)
AS
  SELECT playerid, namefirst, namelast, salary, yearid
  FROM (
    SELECT playerid, namefirst, namelast, salary, yearid, DENSE_RANK() OVER(PARTITION BY yearid ORDER BY salary DESC) AS rnk
    FROM people
    INNER JOIN salaries
    USING(playerid)
    WHERE yearid = 2000 OR yearid = 2001
  )
  WHERE rnk < 2
;
-- Question 4v
CREATE VIEW q4v(team, diffAvg) AS
  SELECT A.teamID AS team, MAX(salary) - MIN(salary) AS diffAvg
  FROM allstarfull AS A
  INNER JOIN salaries AS S
  USING(playerID, yearID, teamID)
  WHERE A.yearID = 2016
  GROUP BY A.teamID
;

