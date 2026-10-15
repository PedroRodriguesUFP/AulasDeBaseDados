
-- find the names of all instructors
select name
from instructor;

--department names of all instructors, and remove duplicates
select distinct dept_name
from instructor;

-- keyword all specifies that duplicates should not be removed
select all dept_name
from instructor;

