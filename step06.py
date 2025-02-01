import mysql.connector
from ftplib import FTP
import sys
import os
import re
import requests

def execute_query(db_host, db_username, db_password, db_database, query):
    global appname
    try:
        # Connect to the MySQL server
        connection = mysql.connector.connect(
            host=db_host,
            user=db_username,
            password=db_password,
            database=db_database
        )

        if connection.is_connected():
            print("Connected to MySQL database")

        # Create a cursor object
        cursor = connection.cursor()

        # Execute the query
        cursor.execute(query)

        # Fetch all the rows
        row = cursor.fetchone()

        # Print the rows
        if row:
          id = row[0]
          pattern = re.compile(r'[^a-zA-Z0-9_]')
          appname = str(id).zfill(4) + '_' + pattern.sub('', row[1]) + '.aab'

          host = os.environ['FTP_SERVER']
          username = os.environ['FTP_USERNAME']
          password = os.environ['FTP_PASSWORD']
          old_name = 'app-release.aab'
          new_name = appname
          
          rename_ftp_file(host, username, password, old_name, new_name)
          while cursor.nextset():
            pass
        else:
          raise RuntimeError("There is no app for build.")

        # Close the cursor and connection
        cursor.close()
        connection.close()

    except mysql.connector.Error as e:
        print("Error executing query:", e)

def rename_ftp_file(host, username, password, old_name, new_name):
    try:
        # Connect to the FTP server
        with FTP(host) as ftp:
            # Login to the FTP server
            ftp.login(username, password)

            # Rename the file
            ftp.rename(old_name, new_name)
            print(f"File '{old_name}' renamed to '{new_name}' successfully.")

    except Exception as e:
        print(f"An error occurred: {e}")


if __name__ == "__main__":
  try:
    # MySQL database credentials
    host = os.environ['DB_HOST']
    username = os.environ['DB_USERNAME']
    password = os.environ['DB_PASSWORD']
    database = os.environ['DB_NAME']

    url = "https://raw.githubusercontent.com/iSubrat/Web2App_V07/refs/heads/main/aab_counter.txt"
    
    response = requests.get(url)
    
    if response.status_code == 200:
        app_id = response.text
        print(app_id)  # Output the text content
    else:
        print("Failed to fetch the data")


    # Example query
    query = f"SELECT * FROM app_data WHERE id = {app_id}"

    # Execute the query
    execute_query(host, username, password, database, query)
  except Exception as e:
    raise RuntimeError("Process Aborted.")
    
