-- ## PARTITION BY RANGE ##

CREATE TABLE EMPLOYEE_RANGE (
	ID BIGSERIAL,
	BIRTH_DATE DATE NOT NULL,
	COUNTRY_CODE VARCHAR(2) NOT NULL
)
PARTITION BY
	RANGE (BIRTH_DATE)

SELECT
	*
FROM
	EMPLOYEE_RANGE;

/* 
Partition plan:
1. yearly partition
2. tablename employee_range_y2000 for year 2000 => range :  2000-01-01 to 2001-01-01
*/
CREATE TABLE PARTITION_TABLE_NAME PARTITION OF MASTER_TABLE FOR
VALUES
FROM
	VALUE1 TO VALUE2;

CREATE TABLE EMPLOYEE_RANGE_Y2000 PARTITION OF EMPLOYEE_RANGE FOR
VALUES
FROM
	('2000-01-01') TO ('2001-01-01')
CREATE TABLE EMPLOYEE_RANGE_Y2001 PARTITION OF EMPLOYEE_RANGE FOR
VALUES
FROM
	('2001-01-01') TO ('2002-01-01')

	
-- INSERT some data

	
INSERT INTO
	employee_range (birth_date,country_code)
VALUES
	('2000-01-01', 'US'),
	('2000-01-02', 'US')-- INSERT some data

	
INSERT INTO
	employee_range (birth_date,country_code)
VALUES
	('2000-01-01', 'US'),
	('2000-01-02', 'US'),
	('2000-12-31', 'US'),
	('2001-01-01', 'US'),
	('2000-12-31', 'US'),
	('2001-01-01', 'US')

-- VIEW data

SELECT * FROM employee_range;
SELECT * FROM ONLY employee_range; -- There is no data directly into master table

-- VIEW data from partitions table

SELECT * FROM employee_range_y2000;
SELECT * FROM employee_range_y2001;

-- Query Explaintion

SELECT * FROM employee_range;

SELECT * FROM employee_range WHERE birth_date = '2000-01-01'; -- Will check in specif partiton only due birth_date specific
SELECT * FROM employee_range WHERE id = 1; -- will check in all partitions, as we haven't ID for table partition



--------------------------------------------------------------------------------------------------------------------
-- ## PARTITION BY LIST 

/*

1. Table is partitioned by explicitly listing 
2. Can have multi-column (composite) partition key
	E.x : Partition by known values
	- By country_code like IND, US, JPN, SP
	- month_name like Jan, Feb, Mar, Apr

*/


CREATE TABLE employee_list (
	ID BIGSERIAL,
	birth_date DATE NOT NULL,
	country_code VARCHAR(2) NOT NULL
)
PARTITION BY
	LIST (country_code)

-- Create individual partition by field

CREATE TABLE partition_table_name PARTITION OF master_table
	FOR VALUES IN (field);

CREATE TABLE employee_list_in PARTITION OF employee_list
	FOR VALUES IN ('IN');

-- For european countries
CREATE TABLE employee_list_eu PARTITION OF employee_list
	FOR VALUES IN ('UK','DE','IT','FR','ES');


SELECT * FROM employee_list; 
SELECT * FROM ONLY employee_list; -- If use ONLY then will not get any data

-- For partioned tables

SELECT * FROM employee_list_in;
SELECT * FROM employee_list_eu;


-- INSERT some data

INSERT INTO
	employee_list (birth_date,country_code)
VALUES
	('2000-01-01', 'IN'),
	('2000-01-02', 'IN'),
	('2000-12-31', 'UK'),
	('2001-01-01', 'FR')


-- Will check for all partition
UPDATE employee_list SET country_code = 'IN' WHERE id = 3;

-- Will check for only employee_list_in partition
UPDATE employee_list SET birth_date = '2001-07-07' WHERE id = 1 AND country_code = 'IN';


--------------------------------------------------------------------------------------------------------------------
-- ## PARTITION BY HASH
/*

1. Used when we can't logically divide our data (When are unable to find best field or column to use for partition)
2. Can divide table into equal numbers of rows 
*/

CREATE TABLE employee_hash (
	ID BIGSERIAL,
	birth_date DATE NOT NULL,
	country_code VARCHAR(2) NOT NULL
)
PARTITION BY
	HASH (id)


-- Partition Tables

CREATE TABLE partition_table_name PARTITION OF master_table
	FOR VALUES WITH (MODULES m, REMAINDER n);

CREATE TABLE employee_hash_1 PARTITION OF employee_hash
	FOR VALUES WITH (MODULUS 3, REMAINDER 0);

CREATE TABLE employee_hash_2 PARTITION OF employee_hash
	FOR VALUES WITH (MODULUS 3, REMAINDER 1);

CREATE TABLE employee_hash_3 PARTITION OF employee_hash
	FOR VALUES WITH (MODULUS 3, REMAINDER 2);


-- INSERT Data

INSERT INTO
	employee_hash (birth_date,country_code)
VALUES
	('2000-01-01', 'IN'),
	('2000-01-02', 'IN'),
	('2000-12-31', 'UK'),
	('2001-01-01', 'FR')

-- VIEW Data
	
SELECT * FROM employee_hash;

SELECT * FROM employee_hash_1;
SELECT * FROM employee_hash_2;
SELECT * FROM employee_hash_3;


--------------------------------------------------------------------------------------------------------------------
-- ## DEFAULT PARTITION
/*

1. When record does't fit for any of the partitions

*/
-- We dont have partition for JP so INSERT will throw an error
INSERT INTO employee_list (birth_date,country_code)
	VALUES ('JP','2001-01-01');

CREATE TABLE partition_table_name PARTITION OF parent_table DEFAULT;

CREATE TABLE employee_list_default PARTITION OF employee_list DEFAULT;

-- Let's try to add data with country_code 'JP'
INSERT INTO employee_list (birth_date,country_code)
	VALUES ('2001-01-01','JP');

INSERT INTO employee_list (birth_date,country_code)
	VALUES ('2001-01-01','SL');

SELECT * FROM employee_list;
SELECT * FROM employee_list_default;
SELECT * FROM employee_list where country_code = 'SL'; -- Will search only in default partition



-------------------------------------------------------------------_code = 'UK'; -- Check for sub partitions in EU

-- Check only specific partition according to hash ID in EU table (As we have specified COUNTRY_CODE and ID)
SELECT * FROM employee_master WHERE ID = 2 AND COUNTRY_CODE = 'IN'; 
-------------------------------------------------
-- ## SUB PARTITION
/*

1. A partition table can be a further partitioned into sub partition
	PARENT_TABLE
		PARTITION_1
		PARTITION_2
			PARTITION_2.1
			PARTITION_2.2
			...
2. While making sub partitions for on Range based partition, will create sub-partition with less or no-data sometimes. 

*/

-- 1) Create master table

CREATE TABLE employee_master (
	ID BIGSERIAL,
	birth_date DATE NOT NULL,
	country_code VARCHAR(2) NOT NULL
)
PARTITION BY LIST (country_code);

-- 2) Create partition and sub-partition
-- Create main partition
-- IN		LIST
-- EU		LIST
---- EU_1		HASH
---- EU_2		HASH

CREATE TABLE employee_master_in PARTITION OF employee_master
	FOR VALUES IN ('IN');

CREATE TABLE employee_master_eu PARTITION OF employee_master
	FOR VALUES IN ('UK','DE','IT','FR')
	PARTITION BY HASH (id);

-- Create sub partitions

CREATE TABLE employee_master_eu_1 PARTITION OF employee_master_eu
	FOR VALUES WITH (MODULUS 3, REMAINDER 0);

CREATE TABLE employee_master_eu_2 PARTITION OF employee_master_eu
	FOR VALUES WITH (MODULUS 3, REMAINDER 1);

CREATE TABLE employee_master_eu_3 PARTITION OF employee_master_eu
	FOR VALUES WITH (MODULUS 3, REMAINDER 2);


-- INSERT Data

INSERT INTO
	employee_master (birth_date,country_code)
VALUES
	('2000-01-01', 'IN'),
	('2000-01-02', 'IN'),
	('2000-12-31', 'UK'),
	('2001-01-01', 'FR')

-- VIEW DATA
	
SELECT * FROM employee_master; -- Check for all partitions with sub

SELECT * FROM employee_master WHERE country_code = 'UK'; -- Check for sub partitions in EU

-- Check only specific partition according to hash ID in EU table (As we have specified COUNTRY_CODE and ID)
SELECT * FROM employee_master WHERE ID = 2 AND COUNTRY_CODE = 'IN'; 

SELECT * FROM only employee_master_eu; -- Data not going to store directly into master_eu table

SELECT * FROM ONLY employee_master_eu_1;
SELECT * FROM ONLY employee_master_eu_2;


-------------------------------------------------------------------------------------------------------------------------------------------------
-- ## PARTITION MAINTENANCE
/*
	We have all new country SP : Sinapore, need to add new partition in existing master table
	- employee_master_list
*/

CREATE TABLE employee_list_sp PARTITION OF EMPLOYEE_LIST
	FOR VALUES IN ('SP');

INSERT INTO employee_list_sp (birth_date, country_code) 
	VALUES ('2001-08-07','SP');

SELECT * FROM employee_list WHERE country_code = 'SP';

-- ## DETACH MAINTENANCE

ALTER TABLE master_table_name DETACH PARTITION partition_table_name;

ALTER TABLE employee_list ATTACH PARTITION employee_list_sp;

SELECT * FROM employee_list_sp;

-- ## ALTERing the partition boundries
-- ###################################
INSERT INTO
	employee_list (birth_date,country_code)
VALUES
	('2000-01-01', 'GE') -- will add into default
SELECT * FROM employee_list_default;
SELECT * FROM employee_list_eu;

BEGIN TRANSACTION;
	ALTER TABLE employee_list DETACH PARTITION employee_list_eu;
	ALTER TABLE employee_list ATTACH PARTITION employee_list_eu FOR VALUES IN ('UK','DE','IT','FR','GE');
COMMIT TRANSACTION;
ROLLBACK;
