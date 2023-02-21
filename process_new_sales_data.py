"""
Script to process new sales data
- Import excel with sales data;
- Append sales data to the SQL database table;
- Move processes excel file to processed folder.
"""

# 1. Setting up my environment

# Import
import pandas as pd
import glob # for dynamic file names
import pyodbc # to connect to the SQL Server database
import shutil # to move files
import ctypes # to open pop up message
import sys 

# 2. Importing the data from the excel to a dataframe:

source_folder = 'C:\\Users\\raque\\Documents\\Data Analytics\\SQL Notion Template Sales\\new_sales_data\\'
file_pattern = source_folder + 'sales_*.xlsx' # Flexible file name. this creates a list of files with this name pattern. 

# Check for files
if len( glob.glob(file_pattern) ) == 0:

   ctypes.windll.user32.MessageBoxW(0, "No files to be processed. The file name must start with 'sales_' and the format must be .xlsx","", 64)
   #exit()
   sys.exit(1)

else:
   pass

file_path = glob.glob(file_pattern)[0] # Assumes there is only one matching file

# Read excel file
df = pd.read_excel(file_path)
df = df.drop('discount', axis=1)

# 3. Connecting to the SQL Server and INSERTING the data from the dataframe to the sales table:

server = 'DESKTOP-4A09347\SQLEXPRESS' 
database = 'BRAINLOADING' 
table = 'sales'
driver = '{SQL Server Native Client 11.0}'

# Connect to SQL Server database
conn = pyodbc.connect('DRIVER=' + driver + ';SERVER=' + server + ';DATABASE=' + database + ';Trusted_Connection=yes')

# Create a cursor
cursor = conn.cursor()

# Define the INSERT statement
sql = f"INSERT INTO {table} (item_id,sale_id,product_id,client_id,date) VALUES (?, ?, ?, ?, ?)"

# Execute the INSERT statement for each row in the DataFrame
for row in df.itertuples(index=False):
    cursor.execute(sql, row)

# Commit the changes
conn.commit()

# Close the database connection
conn.close()

# 4. Moving the excel file to a "processed" folder:

new_folder = 'C:\\Users\\raque\\Documents\\Data Analytics\\SQL Notion Template Sales\\processed_sales_data\\'

# Move excel file
shutil.move(file_path, new_folder)

# 5. End process by informing user

ctypes.windll.user32.MessageBoxW(0, "Process finished successfully.", "", 64)