-- checking if we got all our tables
show tables;

-- checking in details, the major tables
select * from active_id;
select * from bank_churn ;
select * from Customer_ID limit 10;
select * from sql_project_geography;

-- renaming some tables for convinience
Rename table bankchurn to Bank_churn;
Rename table activeid to Active_ID;
Rename table CustomerID to Customer_ID;

-- defining a primary key in customer_id table
ALTER TABLE customer_id 
add PRIMARY KEY (CustomerId);

-- defining a primary key in bank_churn table
ALTER TABLE bank_churn
ADD primary key (customerID);

-- altering a data type in cusomer_id table (ask)
ALTER TABLE customer_id
ADD COLUMN BANKDOJ1 DATE;

ALTER TABLE customer_id
drop column BANKDOJ1;



select c.CustomerId, c.BankDOJ, bc.tenure from customer_id c 
join bank_churn bc on c.CustomerId=bc.CustomerId
;



-- Q1) What is the distribution of account balance across different regions?

select 
distinct c.geographyid, 
g.GeographyLocation, 
round(sum(b.balance) over(partition by GeographyLocation),2) as balance
from customer_id c
left join bank_churn b on c.CustomerId = b.CustomerId
left join sql_project_geography g on c.GeographyID = g.GeographyID
order by GeographyID;





-- Q2) Identify the top 5 customers with the highest Salary

select
surname as Customer_surName,
max(estimatedsalary) as Salary 
from customer_id
group by 1
order by Salary desc
limit 5;





-- Q3) Calculate the average number of products used by customers who have a credit card.

SELECT DISTINCT ROUND(AVG(bc.NumOfProducts),2) AS AvgProducts
FROM customer_id c
LEFT JOIN bank_churn bc 
ON c.CustomerId = bc.CustomerId
where bc.HasCrCard = 1;



-- Q4) Determine the churn rate by gender for the most recent year in the dataset.







 


-- Q5) Compare the average credit score of customers who have exited and those who remain.
-- Here 1 = "exited", 2 = "remain"

select exited, avg(creditscore) as avg_creditscore from bank_churn
group by exited;





-- Q6) Which gender has a higher average estimated salary, and how does it relate to the number of active accounts? 

select c.gender,
round(avg(c.estimatedsalary),2) avg_estimated_salary,
IsActiveMember
from customer_id c 
join bank_churn bc on c.CustomerId=bc.CustomerId
group by c.Gender, IsActiveMember;



-- Q7) Segment the customers based on their credit score 
-- and identify the segment with the highest exit rate.

with cte1 as(
select 
CustomerId, 
creditscore, 
exited, 
case
when creditscore >= 800 and creditscore <= 850 then 'excellent'
when creditscore >= 740 and creditscore <= 799 then 'verygood'
when creditscore >= 670 and creditscore <= 739 then 'good'
when creditscore >= 580 and creditscore <= 669 then 'fair'
else 'poor' 
end as credit_type
from bank_churn)

select CustomerId, creditscore, exited, credit_type,
count(exited) over(partition by credit_type) as max_exit_rate from cte1
order by max_exit_rate desc;






-- Q8) Find out which geographic region has the highest number of active customers with a tenure greater than 5 years. 

select distinct country,
count(c.customerid) as active_customers
from customer_id c 
join bank_churn bc on c.customerid=bc.CustomerId
where IsActiveMember = 1 and Tenure > 5
group by Country limit 1;







-- Q9) What is the impact of having a credit card on customer churn, based on the available data?

with churndata as (
select
HasCrCard,
count(*) as total_customers,
sum(case when exited = '1' then 1 else 0 end) as churned_customers
from bank_churn
group by HasCrCard
)

select
HasCrCard,
total_customers,
churned_customers,
churned_customers/total_customers as churn_rate
from churndata;






-- Q10) For customers who have exited, what is the most common number of products they had used?

select  Numofproducts, count(NumOfProducts) as common_num_products from bank_churn
where exited = 1
group by  Numofproducts;





-- Q11) Examine the trend of customer exits over time and identify any seasonal patterns (yearly or monthly).
-- Prepare the data through SQL and then visualize it.

select 
c.CustomerId,
c.EstimatedSalary,
c.Country,
c.Gender,
c.BankDOJ,
bc.tenure,
bc.HasCrCard
from customer_id c 
join bank_churn bc 
on c.CustomerId=bc.CustomerId
where exited = '1' and tenure in (4,5,6,7)
order by tenure desc;







-- Q12) Analyze the relationship between the number of products and the account balance for customers who have exited.

select
NumOfProducts,
round(avg(Balance),2) as AvgBalance,
count(customerID) as CustomerCount
from bank_churn
where Exited = 1
group by NumOfProducts
order by NumOfProducts;





-- Q13) Identify any potential outliers in terms of spend among customers who have remained with the bank.

select customerID, NumOfProducts as products_bought
from bank_churn
where exited = 0 and NumOfProducts>1
order by NumOfProducts;





-- Q15) Using SQL, write a query to find out the gender-wise average income of males and females in each geography id. 
-- Also, rank the gender according to the average value.

select country, gender, 
round(avg(estimatedsalary),2) as avg_salary, 
rank() over (partition by country order by avg(estimatedsalary) desc) as gender_rank
from customer_id
group by gender, Country
order by Country, gender_rank;




-- Q16)Using SQL, write a query to find out the average tenure of the people who have exited in each age bracket
-- (18-30, 30-50, 50+).

SELECT
  CASE
    WHEN c.Age BETWEEN 18 AND 30 THEN '18-30'
    WHEN c.Age BETWEEN 31 AND 50 THEN '31-50'
    WHEN c.Age >= 51 THEN '50+'
  END AS age_bracket,
  AVG(bc.Tenure) AS avg_tenure
FROM
  customer_id c
JOIN
  bank_churn bc ON c.CustomerId = bc.CustomerId
WHERE
  bc.exited = 1
GROUP BY
  CASE WHEN c.Age BETWEEN 18 AND 30 THEN '18-30'
  WHEN c.Age BETWEEN 31 AND 50 THEN '31-50'
  WHEN c.Age >= 51 THEN '50+' 
  END
ORDER BY age_bracket;






-- Q17) Is there any direct correlation between salary and balance of the customers? 
-- And is it different for people who have exited or not?

-- Q18)  Is there any correlation between salary and Credit score of customers?





-- Q19) Rank each bucket of credit score as per the number of customers who have churned the bank.

with credit_score_bucket as (
	select *,
		case when creditscore between 0 and 579 then 'Poor'
			when creditscore between 580 and 669 then 'Fair'
            when creditscore between 670 and 739 then 'Good'
            when creditscore between 740 and 800 then 'Very Good'
            Else 'Excellent'
		End as credit_score_bucket from bank_churn
        where exited =1)
        
select 
	credit_score_bucket, count(CustomerId) as total_count,
	dense_rank() over (order by count(CustomerId) desc) as ranks
from credit_score_bucket
group by credit_score_bucket;




-- Q20) According to the age buckets find the number of customers who have a credit card. 
-- Also retrieve those buckets who have lesser than average number of credit cards per bucket.

with agebucket as (
select 
case
when c.age between 18 and 30 then '18-30'
when c.age between 31 and 50 then '31-50'
when c.age >= 51 then '50+'
end as agebucket,
count(distinct c.customerid) as num_customers,
avg(case when b.HasCrCard = 1 then 1 else 0 end) as avg_credit_cards
from customer_id c 
join bank_churn b 
on c.CustomerId = b.CustomerId
group by agebucket
)

select
agebucket,
num_customers,
avg_credit_cards
from agebucket
where avg_credit_cards < (select avg(avg_credit_cards) from agebucket);




-- Q21) Rank the Locations as per the number of people who have churned the bank and average balance of the customers.

with locations as (
select
c.Country,
count(c.customerid) as customer_count,
avg(b.balance) as avg_balance
from customer_id c 
join bank_churn b
on c.CustomerId = b.CustomerId
where Exited = 1
group by Country
)

select
country,
customer_count,
round(avg_balance,0) as average_balance,
rank() over(order by customer_count desc) as ranks
from locations;

select * from customer_id;
select * from bank_churn;
select * from sql_project_exit;