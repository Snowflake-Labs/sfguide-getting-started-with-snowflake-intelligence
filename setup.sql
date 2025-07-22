use role accountadmin;

create or replace role snowflake_intelligence_admin;

set current_user = (SELECT CURRENT_USER());   
grant role snowflake_intelligence_admin to user IDENTIFIER($current_user);

create or replace database dash_db_si;
create or replace schema retail;
create or replace warehouse dash_wh_si with warehouse_size='LARGE';

create or replace database snowflake_intelligence;
create or replace schema snowflake_intelligence.agents;

use database dash_db_si;
use schema retail;
use warehouse dash_wh_si;

create or replace file format swt_csvformat  
  skip_header = 1  
  field_optionally_enclosed_by = '"'  
  type = 'CSV';  
  
-- Create table MARKETING_CAMPAIGN_METRICS and load data from S3 bucket
create or replace stage swt_marketing_data_stage  
  file_format = swt_csvformat  
  url = 's3://sfquickstarts/snowflake_world_tour_2025/marketing/';  
  
create or replace TABLE MARKETING_CAMPAIGN_METRICS (
	DATE DATE,
	CATEGORY VARCHAR(16777216),
	CAMPAIGN_NAME VARCHAR(16777216),
	IMPRESSIONS NUMBER(38,0),
	CLICKS NUMBER(38,0)
);

copy into MARKETING_CAMPAIGN_METRICS  
  from @swt_marketing_data_stage;

-- Create table PRODUCTS and load data from S3 bucket
create or replace stage swt_products_data_stage  
  file_format = swt_csvformat  
  url = 's3://sfquickstarts/snowflake_world_tour_2025/product/';  
  
create or replace TABLE PRODUCTS (
	PRODUCT_ID NUMBER(38,0),
	PRODUCT_NAME VARCHAR(16777216),
	CATEGORY VARCHAR(16777216)
);

copy into PRODUCTS  
  from @swt_products_data_stage;

-- Create table SALES and load data from S3 bucket
create or replace stage swt_sales_data_stage  
  file_format = swt_csvformat  
  url = 's3://sfquickstarts/snowflake_world_tour_2025/sales/';  
  
create or replace TABLE SALES (
	DATE DATE,
	REGION VARCHAR(16777216),
	PRODUCT_ID NUMBER(38,0),
	UNITS_SOLD NUMBER(38,0),
	SALES_AMOUNT NUMBER(38,2)
);

copy into SALES  
  from @swt_sales_data_stage;

-- Create table SOCIAL_MEDIA and load data from S3 bucket
create or replace stage swt_social_media_data_stage  
  file_format = swt_csvformat  
  url = 's3://sfquickstarts/snowflake_world_tour_2025/social_media/';  
  
create or replace TABLE SOCIAL_MEDIA (
	DATE DATE,
	CATEGORY VARCHAR(16777216),
	PLATFORM VARCHAR(16777216),
	INFLUENCER VARCHAR(16777216),
	MENTIONS NUMBER(38,0)
);

copy into SOCIAL_MEDIA  
  from @swt_social_media_data_stage;

-- Create table SUPPORT_CASES and load data from S3 bucket
create or replace stage swt_support_data_stage  
  file_format = swt_csvformat  
  url = 's3://sfquickstarts/snowflake_world_tour_2025/support/';  
  
create or replace TABLE SUPPORT_CASES (
	ID VARCHAR(16777216),
	TITLE VARCHAR(16777216),
	PRODUCT VARCHAR(16777216),
	TRANSCRIPT VARCHAR(16777216)
);

copy into SUPPORT_CASES  
  from @swt_support_data_stage;

create or replace stage semantic_models encryption = (TYPE = 'SNOWFLAKE_SSE') directory = ( ENABLE = true );

grant usage on warehouse compute_wh to role snowflake_intelligence_admin;
grant ownership on database dash_db_si to role snowflake_intelligence_admin;
grant ownership on schema dash_db_si.retail to role snowflake_intelligence_admin;
grant ownership on database snowflake_intelligence to role snowflake_intelligence_admin;
grant ownership on schema snowflake_intelligence.agents to role snowflake_intelligence_admin;
grant ownership on warehouse dash_wh_si to role snowflake_intelligence_admin;
grant ownership on stage semantic_models to role snowflake_intelligence_admin;

grant ownership on table MARKETING_CAMPAIGN_METRICS to role snowflake_intelligence_admin;
grant ownership on table PRODUCTS to role snowflake_intelligence_admin;
grant ownership on table SALES to role snowflake_intelligence_admin;
grant ownership on table SOCIAL_MEDIA to role snowflake_intelligence_admin;
grant ownership on table SUPPORT_CASES to role snowflake_intelligence_admin;

alter user set default_role = snowflake_intelligence_admin;
alter user set default_warehouse = dash_wh_si;

select * from dash_db_si.retail.MARKETING_CAMPAIGN_METRICS;

