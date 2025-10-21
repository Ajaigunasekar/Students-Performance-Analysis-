create table Students_performance(
             Student_ID VARCHAR (5),
             gender	VARCHAR(6),
			 ethnicity	VARCHAR(7),
			 parental_level_of_education VARCHAR(18),
			 lunch	VARCHAR(12),
			 test_preparation_course VARCHAR(9),
			 math_score	INT,
			 reading_score	INT,
			 writing_score	INT	
	);
	
-------------------
select * from  Students_performance
-------------------	

--1. Rank students within each gender based on their average total score .
with avg_total_score as 
(
select 
      Student_ID,
	  gender,
ROUND((math_score + reading_score + writing_score)/3.0,2)as avg_total_score
from 
    Students_performance
)

select 
       Student_ID,
	   gender,
	   avg_total_score,
rank() over(partition by gender order by avg_total_score desc)as gender_rank
from 
    avg_total_score
order by 
    gender,
	gender_rank;

--2. For each parents education, find the top 3 performing students based on total score.

with total_score as
(
select 
    Student_ID,
    parental_level_of_education,
   (math_score + reading_score + writing_score) as total_score
from 
    Students_performance
),

Ranked_student as
(select 
    Student_ID,
    parental_level_of_education,
    total_score,
rank() over(partition by parental_level_of_education order by total_score desc ) as Rank_within_group
from 
    total_score
)
select 
    Student_ID,
    parental_level_of_education,
    total_score,
	Rank_within_group
from 
    Ranked_student
where 
    Rank_within_group <= 3
order by 
    parental_level_of_education;

--3. For each gender, find which subject  has the highest average score.

WITH avg_subject_score as
(
select 
    Student_ID,
	gender,
	ROUND(avg(math_score),2) as Math_avg_score,
    ROUND(avg(reading_score),2)	 as Reading_avg_score ,
    ROUND(avg(writing_score),2)	 as Writing_avg_score
from Students_performance
group by 
    Student_ID,
	gender
)
select 
    Student_ID,
	gender,
case
    when Math_avg_score>=Reading_avg_score and Math_avg_score>=Writing_avg_score then 'Math'
	when Reading_avg_score>= Math_avg_score and Reading_avg_score>=Writing_avg_score then 'Reading'
	else 'Writing'
end as highest_average_score
from 
    avg_subject_score
order by 
    CAST(REGEXP_REPLACE(Student_ID, '\D', '', 'g') AS INT);
	
--4. For each student, show whether their total score is above or below the average score of their ethnicity group.

with total_score as
(
select
    student_ID,
	Ethnicity,
	(math_score + reading_score + writing_score) as total_score	  
from 
    Students_performance 
),

Group_avg as   
(
select 
	Ethnicity,
    ROUND (avg(math_score + reading_score + writing_score),2) as  avg_grp_score
from Students_performance
group by 
     Ethnicity
)
select 
    s.Student_ID,
    s.ethnicity,
    s.total_score,
    g.avg_grp_score,
case 
    when s.total_score > g.avg_grp_score then 'Above Average'
    when s.total_score < g.avg_grp_score then 'Below Average'
    else 'Average'
END as comparison_to_group
from 
    total_score s
JOIN Group_avg g
ON s.ethnicity = g.ethnicity
order by 
     CAST(REGEXP_REPLACE(s.Student_ID, '\D', '', 'g') AS INT);	    
	
-- 5. Add a new column performance_level using CASE logic: “Excellent” → total ≥ 250, “Good” → total between 200–249,
--“Average” → total between 150–199, “Poor” → total < 150

select 
     student_ID,
	 ethnicity,
	 (math_score + reading_score + writing_score) as Total_core,
case
    when (math_score + reading_score + writing_score) >= 250 then 'Excellent'
	when (math_score + reading_score + writing_score) between 200 and 249 then 'Good'
	when (math_score + reading_score + writing_score) between 150 and 199 then 'Average'
	else 'poor'
End as performance_level
from Students_performance
    
	
--6. Find students whose scores in all three subjects differ by less than 10 points (consistent performance).
select
     student_ID,
	 ethnicity,
	 math_score,
	 reading_score,
	 writing_score	
from 
    Students_performance
where
    greatest (math_score, reading_score, writing_score)
    - least (math_score, reading_score, writing_score)< 10
order by 
    CAST(REGEXP_REPLACE(Student_ID, '\D', '', 'g') AS INT);

--7.  : For each race/ethnicity group, calculate the average improvement in total score 
--between students who completed vs did not complete the test preparation course.

with total_score as
(
select
    ethnicity,
	test_preparation_course,
    (math_score + reading_score + writing_score) as total_score
from
    Students_performance
)

select
    ethnicity,
	ROUND(avg(case when test_preparation_course = 'completed' then Total_score end )
	- avg(case when test_preparation_course = 'none' then Total_score end ),2) as average_improvement
from 
    total_score
group by
    ethnicity
order by 
    ethnicity ;
    
--8. Build a Student Report showing: Student ID, Gender, Total score, Performance category, 
--Rank within parental education, Above/below average flag

with total_score as
(
select
    Student_ID,
    gender,
	parental_level_of_education,
	math_score,
	reading_score,
	writing_score,
    (math_score + reading_score + writing_score) as total_score
from 
    Students_performance
),
ranked_edu as
(
select
    Student_ID,
    gender,
	parental_level_of_education,
	total_score,
rank () over(partition by parental_level_of_education 
        order  by total_score desc) as rank_within_parent_edu,
ROUND(avg (total_score) over (partition by parental_level_of_education),2) as avg_score_parent_edu
from 
    total_score
)
select
     Student_ID, 
	 Gender, 
	 Total_score,
     parental_level_of_education,
case
    when (total_score) >= 250 then 'Excellent'
	when (total_score) between 200 and 249 then 'Good'
	when (total_score) between 150 and 199 then 'Average'
	else 'Needs_Improvement'
End as performance_category,

rank_within_parent_edu,
 case when total_score > avg_score_parent_edu then 'Above Avg'
 else 'Below_Avg'
End as Avg_flag
from
    ranked_edu
order by 
    parental_level_of_education,
	rank_within_parent_edu

--9. For each student, find the subject they performed worst.

select
    Student_ID,
    gender,
	math_score,
	reading_score,
	writing_score,
case
    when math_score = Least(math_score, reading_score, writing_score) then 'Math'
	when reading_score = Least(math_score, reading_score, writing_score) then 'Reading'
	Else 'Writing'
End as performed_worst
from 
    Students_performance
order by
    CAST(REGEXP_REPLACE(student_ID,'\D','','g') as INT);

--10. Calculate the average difference between male and female scores in math, reading, and writing.

select 
ROUND (ABS(avg(case when gender = 'male' then math_score end)
           - avg(case when gender = 'female' then math_score end)),2) as math_diff,
ROUND (ABS(avg(case when gender = 'male' then reading_score end)
           - avg(case when gender = 'female' then reading_score end)),2) as reading_diff,		
ROUND (ABS(avg(case when gender = 'male' then writing_score end)
           - avg(case when gender = 'female' then writing_score end)),2) as writing_diff		   
from
    Students_performance

--------
 
  
     



