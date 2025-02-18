import mysql.connector
import ftplib
from ftplib import FTP, error_perm
from PIL import Image
import requests
import json
import sys
import os
import re
from bs4 import BeautifulSoup
from googlesearch import search
from requests.exceptions import SSLError, ConnectionError
from openai import OpenAI
import time
from requests.exceptions import HTTPError


# MySQL database credentials
host = os.environ['DB_HOST']
username = os.environ['DB_USERNAME']
password = os.environ['DB_PASSWORD']
database = os.environ['DB_NAME']

# FTP credentials
ftp_host = os.environ['FTP_SERVER']
ftp_username = os.environ['FTP_USERNAME']
ftp_password = os.environ['FTP_PASSWORD']

openai_api_key = os.environ['OPENAI_API_KEY']

def summarize_title(previous_titles, title, url, api_key):
    client = OpenAI(api_key=api_key)
    response = client.chat.completions.create(
        model="gpt-3.5-turbo",
        messages=[
            {"role": "system", "content": "You are a helpful assistant."},
            {"role": "user",
             "content": f"Previous Titles: {previous_titles}. Current Webpage Title: {title}. Webpage URL: {url}. Please provide a one-word title for this webpage that is different from the previous titles. Note: Your response should only include the title and no additional text, as it will be used directly in code."},
        ],
    )
    return response.choices[0].message.content


def normalize_url(url):
    # Remove URL parameters and fragment identifiers
    url = url.split('?')[0].split('#')[0]
    # Remove 'www.' if it exists and ensure consistent HTTP/HTTPS scheme
    url = url.replace('http://', 'https://').replace('https://www.', 'https://').rstrip('/')
    return url.lower()


def popular_urls(url, api_key):
    try:
        domain = url.split('://')[1]
        query = "site:" + domain.split('/')[0]
        search_results = search(query, stop=4)
        urls = [url] + list(search_results)
        normalized_urls = set()
        unique_urls = []
        for url in urls:
            norm_url = normalize_url(url)
            if norm_url not in normalized_urls:
                normalized_urls.add(norm_url)
                unique_urls.append(url)

        url_titles = []
        for i, url in enumerate(unique_urls):
            retry_count = 0
            while retry_count < 5:  # Try up to 5 times
                try:
                    response = requests.get(url)
                    response.raise_for_status()  # Will raise HTTPError for bad requests (400 or 500 level responses)
                    soup = BeautifulSoup(response.text, 'html.parser')
                    title = 'Home'
                    previous_titles = title
                    if i > 0:
                        title = soup.find('title').text if soup.find('title') else ''
                        if len(title.split(' ')) > 2 or len(title) < 1 or len(title) > 10:
                            title = summarize_title(previous_titles, title, url, api_key)
                    previous_titles = previous_titles + f', {title}'
                    url_titles.append((url, title))
                    break  # Break the loop if request is successful
                except HTTPError as e:
                    if e.response.status_code == 429:
                        time.sleep(10)  # Sleep for 10 seconds before retrying
                    else:
                        raise  # Re-raise the exception if it's not a 429
                retry_count += 1
        return url_titles
    except Exception as e:
        print('Debug A: ', e)
        return []

def execute_query(db_host, db_username, db_password, db_database, query):
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
            redirect_url = f'http://web2app.appcollection.in/V08/redirect.php?id={id}'
            web_url = row[2]
            app_logo = f'https://appcollection.in/InstantWeb2App/V08/uploads/{row[6]}'
            published = row[16]
            print('Debug B: ', id, app_name, redirect_url, web_url)

            while cursor.nextset():
                pass
            content = create_app_configuration(app_name, redirect_url, web_url, app_logo, published)
            filename = "mightyweb.json"
            if content != None:
                upload_to_ftp(ftp_host, ftp_username, ftp_password, filename, content, id)
        else:
            raise RuntimeError("There is no app for build.")

        # Close the cursor and connection
        cursor.close()
        connection.close()

    except mysql.connector.Error as e:
        print("Error executing query:", e)


def create_app_configuration(app_name, redirect_url, web_url, app_logo, published):
    # urls = popular_urls(web_url, openai_api_key)
    # print('Debug C: ', urls)
    
    if published=='PUBLISHED':
        content = None
    else:
        content = json.dumps({
            "appconfiguration": {
                "app_name": app_name,
                "url": redirect_url,
                "appLanguage": "en",
                "isJavascriptEnable": "true",
                "isSplashScreen": "true",
                "isZoomFunctionality": "false",
                "navigationStyle": "sidedrawer_tabs",
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
                "app_logo": app_logo,
                "floating_button": ""
            },
            "admob": {
                "ads_type": "none",
                "admobBannerID": "",
                "admobIntentialID": "",
                "admobBannerIDIOS": "",
                "admobIntentialIDIOS": "",
                "facebookBannerID": "",
                "facebookIntentialID": "",
                "facebookBannerIDIOS": "",
                "facebookIntentialIDIOS": ""
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
            "splash_configuration": {
            "first_color": "#000000",
            "second_color": "#000000",
            "title": app_name,
            "enable_title": "true",
            "title_color": "#ffffff",
            "enable_logo": "true",
            "enable_background": "true",
            "splash_logo_url": app_logo,
            "splash_background_url": "https://published.appcollection.in/upload/splash_background.png"
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
            }],
            "pages": [
              {
                "id": "1",
                "title": "Create More Apps",
                "image": "https://published.appcollection.in/upload/tabs/web2app.png",
                "url": "https://web2app.appcollection.in/web2app_promo.html",
                "status": "1"
              },
              {
                "id": "2",
                "title": "Upgrade App",
                "image": "https://published.appcollection.in/upload/tabs/web2app_pro.png",
                "url": "https://web2app.appcollection.in/web2app_pro_promo.html",
                "status": "1"
              }
            ]
        }, indent=4)
    return content

def upload_to_ftp(ftp_host, ftp_username, ftp_password, filename, content, id):
    with FTP(ftp_host) as ftp:
        ftp.login(ftp_username, ftp_password)
        
        # Prepare the directory path
        directory = f'01_Profiles/{id}/upload'
        
        # Attempt to create and navigate to each part of the path
        try:
            ftp.cwd(directory)  # Try to change to the full directory path
        except error_perm as e:
            # If the directory does not exist, create it
            print("Directory does not exist, attempting to create:", directory)
            # Split the directory to handle each part
            parts = directory.split('/')
            current_path = ''
            for part in parts:
                if not part:
                    # Skip empty parts (e.g., leading '/')
                    continue
                current_path += f"/{part}"
                try:
                    ftp.cwd(current_path)
                except error_perm:
                    print(f"Creating directory: {current_path}")
                    ftp.mkd(current_path)
                    ftp.cwd(current_path)
        
        # Write the content to a file locally before uploading
        with open(filename, 'w') as file:
            file.write(content)
        
        # Upload the file
        with open(filename, 'rb') as file:
            ftp.storbinary(f'STOR {filename}', file)

        print(f"Uploaded {filename} to FTP.")


if __name__ == "__main__":
    try:  
      # Example query
      query = "SELECT * FROM app_data WHERE status = 'BUILDING' ORDER BY id DESC LIMIT 1"
  
      # Execute the query
      execute_query(host, username, password, database, query)
    except Exception as e:
      raise RuntimeError("Process Aborted.")
