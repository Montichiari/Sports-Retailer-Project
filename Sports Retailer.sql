----- Exploring / analysing age demographic at popular sports retailer

---- Data cleaning
--- Removing invalid rows from "transactions" table where column "sku_idr" = 0
-- These are null rows
DELETE FROM transactions
WHERE sku_idr = 0


--- Retaining only one instance of each transaction id
DELETE FROM transactions
WHERE "id" IN (
	SELECT "id"
	FROM (
		SELECT "id", ROW_NUMBER() OVER (PARTITION BY transaction_id ORDER BY "id" ASC) AS rownum
		FROM transactions
	) s
	WHERE rownum > 1
)

SELECT *
FROM transactions


--- Creating a table that includes all columns from transactions table
-- as well as 3 age demographic columns from the customer table.
CREATE TABLE transactionAge(
	"id" int,
	transaction_id varchar(100),
	date_transaction date,
	sku_idr int,
	product_type varchar(100),
	sports varchar(100),
	business_unit varchar(100),
	customer_id varchar(100),
	the_to_type varchar(100),
	qty_item int,
	turnover double precision,
	loyalty_card_num varchar(100),
	birthdate date,
	age int,
	age_range varchar(100)
);

-- Insert into table
INSERT INTO transactionAge
WITH custage AS (
	SELECT *, EXTRACT(YEAR FROM age(birthdate)) AS age
	FROM transactions LEFT JOIN customer ON transactions.customer_id = customer.loyalty_card_num
	)
SELECT *,
CASE WHEN age < 20 THEN 'Teen'
WHEN age >= 20 AND age < 40 THEN 'Young Adults'
WHEN age >= 40 AND age < 60 THEN 'Adults'
WHEN age >= 60 THEN 'Seniors'
ELSE 'NA'
END AS age_range
FROM custage;


--- Looking at no. of transactions by members vs non-members
WITH memvNon as (
	SELECT *,
	CASE WHEN loyalty_card_num NOTNULL THEN 'Member'
	ELSE 'Non-member'
	END AS ismember
	FROM transactionAge
	)
SELECT ismember, COUNT(*) as transactionsCount
FROM memvNon
GROUP BY ismember
ORDER BY transactionsCount DESC


--- Total transactions by each age group
SELECT age_range, COUNT(DISTINCT(transaction_id)) as transactionCount
FROM transactionAge
WHERE age_range != 'NA'
GROUP BY age_range
ORDER BY transactionCount DESC


--- Total transactions at each store / website
SELECT business_unit, COUNT(DISTINCT(transaction_id)) as transactionCount
FROM transactionAge
GROUP BY business_unit
ORDER BY transactionCount DESC


--- Top ranking age demographic by number of transaction for each store
WITH agedem2 as (
	SELECT *,
	RANK() OVER (PARTITION BY business_unit ORDER BY transactCount DESC) as rnk
	FROM (
		SELECT business_unit, age_range, COUNT(*) as transactCount
		FROM transactionAge
		WHERE age_range != 'NA'
		GROUP BY business_unit,age_range
		ORDER BY business_unit, transactCount
		) as agedem
					)
SELECT business_unit, age_range, transactCount
FROM agedem2
WHERE rnk = 1