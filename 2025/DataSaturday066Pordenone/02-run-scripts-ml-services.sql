

SELECT configuration_id, [name] FROM sys.configurations;



-- Let's use an input dataset from a query
-- Result on the Messages tab
EXEC sp_execute_external_script
@language = N'py310',
@script = N'
import pandas as pd
print(configs_df.shape[0])',
@input_data_1 = N'SELECT configuration_id, name FROM sys.configurations', 
@input_data_1_name = N'configs_df';



-- What if you want to reuse this data in a later data stream instead?
-- Let's use parameters
-- Result on the Result tab
DECLARE @external_row_count INT;

EXEC sp_execute_external_script
@language = N'py310',
@script = N'
import pandas as pd
row_count = configs_df.shape[0]
print(row_count)',
@input_data_1 = N'SELECT configuration_id, name FROM sys.configurations',
@input_data_1_name = N'configs_df',
@params = N'@row_count INT OUTPUT',
@row_count = @external_row_count OUTPUT;

SELECT NumRows = @external_row_count;



-- What if you want to apply transformations to the input dataframe and output the transformed result set?
-- Associate the transformed dataframe with the OutputDataSet variable in your script to get a result set as output
-- no column names!
EXEC sp_execute_external_script
@language = N'py310',
@script = N'
import pandas as pd
configs_df["id_name"] = configs_df["configuration_id"].astype(str) + configs_df["name"]
OutputDataSet = configs_df',
@input_data_1 = N'SELECT configuration_id, name FROM sys.configurations',
@input_data_1_name = N'configs_df';



-- The same of above, this time with a custom output variable and column names.
EXEC sp_execute_external_script
@language = N'py310',
@script = N'
import pandas as pd
configs_df["id_name"] = configs_df["configuration_id"].astype(str) + configs_df["name"]
transformed_df = configs_df',
@input_data_1 = N'SELECT configuration_id, name FROM sys.configurations',
@input_data_1_name = N'configs_df',
@output_data_1_name = N'transformed_df'
WITH RESULT SETS(
	(
		configuration_id INT NOT NULL,
		name VARCHAR(150) NOT NULL,
		id_name VARCHAR(200) NOT NULL
	)
);



-- Reuse the output result set in the next T-SQL flow
DROP TABLE IF EXISTS #InstanceConfigurations;

CREATE TABLE #InstanceConfigurations (
	configuration_id INT NOT NULL,
	name VARCHAR(150) NOT NULL,
	id_name VARCHAR(200) NOT NULL
);

INSERT INTO #InstanceConfigurations
EXEC sp_execute_external_script
@language = N'py310',
@script = N'
import pandas as pd
configs_df["id_name"] = configs_df["configuration_id"].astype(str) + configs_df["name"]
transformed_df = configs_df',
@input_data_1 = N'SELECT configuration_id, name FROM sys.configurations',
@input_data_1_name = N'configs_df',
@output_data_1_name = N'transformed_df';

SELECT * FROM #InstanceConfigurations;
-- The query passed to the @input_data_1 parameter can be as complex as you like,
-- but it must be in the form of SELECT ... FROM ... .
-- This means that you cannot pass an EXEC query that executes a stored procedure, for example.



-- What if you need to get data from two or more data sources?
-- The parameter name input_data_N might suggest you can pass multiple parameters like @input_data_2,
-- but this isn't supported. Microsoft named it this way to hint at potential future functionality.
--
-- There are the LOOPBACK requests. You can connect back to SQL Server from the external script using an ODBC connection.
-- You need to install the pyodbc package in your Python environment.
--
-- In this example, there is no input result set, just data gthered using a loopback request.
-- To allow a loopback request, you have to create a login in SQL Server for SQLRUserGroup
-- (https://learn.microsoft.com/en-us/sql/machine-learning/security/create-a-login-for-sqlrusergroup?view=sql-server-ver16)
EXEC sp_execute_external_script
@language = N'py310',
@script = N'
import pandas as pd
import pyodbc

conn = pyodbc.connect(
    "Driver={ODBC Driver 17 for SQL Server};"
    "Server=.;"
    "Database=master;"
    "Trusted_Connection=yes;")

configs_df = pd.read_sql("SELECT configuration_id, name FROM sys.configurations", conn) 
configs_df["id_name"] = configs_df["configuration_id"].astype(str) + configs_df["name"]
transformed_df = configs_df',
@output_data_1_name = N'transformed_df'
WITH RESULT SETS(
	(
		configuration_id INT NOT NULL,
		name VARCHAR(150) NOT NULL,
		id_name VARCHAR(200) NOT NULL
	)
);


-- If an error like the following occurs:
-- "A 'py310' script error occurred during execution of 'sp_execute_external_script' with HRESULT 0x80004004.
--  STDOUT message(s) from external script: Installing Python and R custom runtimes for SQL Server
--  2023-09-23 15:42:18.32    Error: Python error: <class 'pyodbc.OperationalError'>:
--  ('08001', '[08001] [Microsoft][ODBC Driver 17 for SQL Server]Named Pipes Provider: Could not open a connection to SQL Server [5]."
--
-- then you need to enable the TCP/IP protocol in the SQL Server Configuration Manager.


-- ODBC (via RODBC in R or pyodbc in Python) uses the slower TCP/IP protocol, so it's typically used for
-- smaller secondary datasets like lookup tables. Larger datasets are passed through @input_data_1 in
-- sp_execute_external_script, leveraging the faster Shared Memory protocol for efficient transport
-- between SQL Server and the external process (e.g., Launchpad).


