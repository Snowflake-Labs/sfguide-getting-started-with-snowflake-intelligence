use role accountadmin;

create or replace role snowflake_intelligence_admin;
grant create warehouse on account to role snowflake_intelligence_admin;
grant create database on account to role snowflake_intelligence_admin;
grant usage on warehouse compute_wh to role snowflake_intelligence_admin;
grant create integration on account to role snowflake_intelligence_admin;

set current_user = (SELECT CURRENT_USER());   
grant role snowflake_intelligence_admin to user IDENTIFIER($current_user);
alter user set default_role = snowflake_intelligence_admin;
alter user set default_warehouse = dash_wh_si;

use role snowflake_intelligence_admin;
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
  url = 's3://sfquickstarts/sfguide_getting_started_with_snowflake_intelligence/marketing/';  
  
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
  url = 's3://sfquickstarts/sfguide_getting_started_with_snowflake_intelligence/product/';  
  
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
  url = 's3://sfquickstarts/sfguide_getting_started_with_snowflake_intelligence/sales/';  
  
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
  url = 's3://sfquickstarts/sfguide_getting_started_with_snowflake_intelligence/social_media/';  
  
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
  url = 's3://sfquickstarts/sfguide_getting_started_with_snowflake_intelligence/support/';  
  
create or replace TABLE SUPPORT_CASES (
	ID VARCHAR(16777216),
	TITLE VARCHAR(16777216),
	PRODUCT VARCHAR(16777216),
	TRANSCRIPT VARCHAR(16777216),
	DATE DATE
);

copy into SUPPORT_CASES  
  from @swt_support_data_stage;

create or replace stage semantic_models encryption = (TYPE = 'SNOWFLAKE_SSE') directory = ( ENABLE = true );

create or replace NOTIFICATION INTEGRATION email_integration
  TYPE=EMAIL
  ENABLED=TRUE
  DEFAULT_SUBJECT = 'Snowflake Intelligence';

create or replace PROCEDURE send_email(
    recipient_email VARCHAR,
    subject VARCHAR,
    body VARCHAR
)
RETURNS VARCHAR
LANGUAGE PYTHON
RUNTIME_VERSION = '3.12'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'send_email'
AS
$$
def send_email(session, recipient_email, subject, body):
    try:
        # Escape single quotes in the body
        escaped_body = body.replace("'", "''")
        
        # Execute the system procedure call
        session.sql(f"""
            CALL SYSTEM$SEND_EMAIL(
                'email_integration',
                '{recipient_email}',
                '{subject}',
                '{escaped_body}'
            )
        """).collect()
        
        return "Email sent successfully"
    except Exception as e:
        return f"Error sending email: {str(e)}"
$$;

select 'Congratulations! Snowflake Intelligence setup has completed successfully!' as status;

