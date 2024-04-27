import mysql.connector
import ftplib
from ftplib import FTP, error_perm
import json
import os
import requests
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
        print(e)
        return []



def execute_query(db_host, db_username, db_password, db_database):
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

        # Execute the query to fetch all rows where status is "UPDATE"
        cursor.execute("SELECT * FROM app_data WHERE status = 'UPDATE' AND published = ''")

        # Process each row
        for row in cursor.fetchall():
            process_row(row, cursor, ftp_host, ftp_username, ftp_password)

        # Close the cursor and connection
        cursor.close()
        connection.close()

    except mysql.connector.Error as e:
        print("Error executing query:", e)

def process_row(row, cursor, ftp_host, ftp_username, ftp_password):
    id, app_name, redirect_url, web_url, app_logo, published = row[0], row[1], f'http://web2app.appcollection.in/V07/redirect.php?id={row[0]}', row[2], f'https://appcollection.in/InstantWeb2App/V07/uploads/{row[6]}', row[15]
    print(id, app_name, redirect_url, web_url)

    # Generate configuration content for the app
    content = create_app_configuration(app_name, redirect_url, web_url, app_logo, published)

    # Upload to FTP
    filename = "mightyweb.json"
    upload_to_ftp(ftp_host, ftp_username, ftp_password, filename, content, id)

def create_app_configuration(app_name, redirect_url, web_url, app_logo, published):
    urls = popular_urls(web_url, openai_api_key)
    print(urls)
    
    if published=='DIY':
        pass
    elif published=='PUBLISHED':
        pass
    else:
        if len(urls)<4:
            content = json.dumps({
                "appconfiguration": {
                    "app_name": app_name,
                    "url": redirect_url,
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
        else:
            content = json.dumps({
                "appconfiguration": {
                    "app_name": app_name,
                    "url": redirect_url,
                    "appLanguage": "en",
                    "isJavascriptEnable": "true",
                    "isSplashScreen": "false",
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
                "exitpopup_configuration": {
                    "title": "Do you want to exit app?",
                    "positive_text": "Yes",
                    "negative_text": "No",
                    "enable_image": "false",
                    "exit_image_url": ""
                },
                "tabs": [
                  {
                    "id": "1",
                    "title": urls[0][1],
                    "image": "https://published.appcollection.in/upload/tabs/ic_home.png",
                    "url": urls[0][0],
                    "status": "1"
                  },
                  {
                    "id": "2",
                    "title": urls[1][1],
                    "image": "https://published.appcollection.in/upload/tabs/ic_search.png",
                    "url": urls[1][0],
                    "status": "1"
                  },
                  {
                    "id": "3",
                    "title": urls[2][1],
                    "image": "https://published.appcollection.in/upload/tabs/ic_profile.png",
                    "url": urls[2][0],
                    "status": "1"
                  },
                  {
                    "id": "4",
                    "title": urls[3][1],
                    "image": "https://published.appcollection.in/upload/tabs/ic_heart.png",
                    "url": urls[3][0],
                    "status": "1"
                  }
                ],
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
                    "title": urls[0][1],
                    "image": "https://published.appcollection.in/upload/tabs/ic_home.png",
                    "url": urls[0][0],
                    "status": "0"
                  },
                  {
                    "id": "2",
                    "title": urls[1][1],
                    "image": "https://published.appcollection.in/upload/tabs/ic_search.png",
                    "url": urls[1][0],
                    "status": "1"
                  },
                  {
                    "id": "3",
                    "title": urls[2][1],
                    "image": "https://published.appcollection.in/upload/tabs/ic_profile.png",
                    "url": urls[2][0],
                    "status": "1"
                  },
                  {
                    "id": "4",
                    "title": urls[3][1],
                    "image": "https://published.appcollection.in/upload/tabs/ic_heart.png",
                    "url": urls[3][0],
                    "status": "1"
                  }
                ]
            }, indent=4)
    return content

def upload_to_ftp(ftp_host, ftp_username, ftp_password, filename, content, id):
    with FTP(ftp_host) as ftp:
        ftp.login(ftp_username, ftp_password)
        directory = f'01_Profiles/{id}/upload'
        try:
            ftp.cwd(directory)  # Navigate to the directory
        except error_perm:
            create_directory(ftp, directory)  # Create the directory if it doesn't exist
        
        with open(filename, 'w') as file:
            file.write(content)
        
        with open(filename, 'rb') as file:
            ftp.storbinary(f'STOR {filename}', file)

        print(f"Uploaded {filename} to FTP.\n")

def create_directory(ftp, directory):
    parts = directory.split('/')
    current_path = ''
    for part in parts:
        if not part:
            continue
        current_path += f"/{part}"
        try:
            ftp.cwd(current_path)
        except error_perm:
            print(f"Creating directory: {current_path}")
            ftp.mkd(current_path)
            ftp.cwd(current_path)

if __name__ == "__main__":
    execute_query(host, username, password, database)
