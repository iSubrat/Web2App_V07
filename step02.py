import mysql.connector
from ftplib import FTP
from PIL import Image
import requests
import json
import sys
import os
import re


# MySQL database credentials
host = os.environ['DB_HOST']
username = os.environ['DB_USERNAME']
password = os.environ['DB_PASSWORD']
database = os.environ['DB_NAME']

# FTP credentials
ftp_host = os.environ['FTP_SERVER']
ftp_username = os.environ['FTP_USERNAME']
ftp_password = os.environ['FTP_PASSWORD']

def execute_query(db_host, db_username, db_password, db_database, query):
    global id, app_name, web_url
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
            app_name = row[1]
            web_url = row[2]
            print(id, app_name, web_url)

            while cursor.nextset():
                pass
            content = json.dumps({
                "appconfiguration": {
                    "app_name": app_name,
                    "url": web_url,
                    "appLanguage": "en",
                    "isJavascriptEnable": "true",
                    "isSplashScreen": "false",
                    "isZoomFunctionality": "false",
                    "navigationStyle": "fullscreen",
                    "header_style": "left",
                    "is_walkthrough": "false",
                    "is_webrtc": "true",
                    "is_floating_button": "false",
                    "floating_button_style": "regular",
                    "is_pull_refresh": "true",
                    "tab_style": "tab_with_title_icon",
                    "bottom_navigation": "bottom_navigation_3",
                    "walkthrough_style": "walkthrough_style_3",
                    "clear_cookie": "false",
                    "isExitPopupScreen": "true",
                    "disable_header": "false",
                    "disable_footer": "false",
                    "app_logo": "",
                    "floating_button": ""
                },
                "progressbar": {
                    "is_progressbar": "true",
                    "loaderStyle": "FadingCircle"
                },
                "theme": {
                    "themeStyle": "Custom",
                    "customColor": "#000000",
                    "gradientColor1": None,
                    "gradientColor2": None
                },
                "exitpopup_configuration": {
                    "title": "Do you want to exit app?",
                    "positive_text": "Yes",
                    "negative_text": "No",
                    "enable_image": "false",
                    "exit_image_url": ""
                },
                "user_agent": [{
                    "id": "1",
                    "title": "Safari Mac M1",
                    "android": "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Mobile Safari/537.36",
                    "ios": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15",
                    "status": "1"
                }]
            }, indent=4)
            filename = "mightyweb.json"
            upload_to_ftp(ftp_host, ftp_username, ftp_password, filename, content, id)
        else:
            raise RuntimeError("There is no app for build.")

        # Close the cursor and connection
        cursor.close()
        connection.close()

    except mysql.connector.Error as e:
        print("Error executing query:", e)

def upload_to_ftp(ftp_host, ftp_username, ftp_password, filename, content, id):
    with FTP(ftp_host) as ftp:
        ftp.login(ftp_username, ftp_password)
        with open(filename, 'w') as file:
            file.write(content)
        with open(filename, 'rb') as file:
            ftp.storbinary(f'STOR downloads/01_Profiles/{id}/upload/{filename}', file)

if __name__ == "__main__":
    try:  
      # Example query
      query = "SELECT * FROM app_data WHERE status = 'BUILDING' ORDER BY id DESC LIMIT 1"
  
      # Execute the query
      execute_query(host, username, password, database, query)
    except Exception as e:
      raise RuntimeError("Process Aborted.")
