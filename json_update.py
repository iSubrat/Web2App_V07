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
import logging

# Setup basic logging
logging.basicConfig(level=logging.DEBUG)

# MySQL database credentials
host = os.getenv('DB_HOST')
username = os.getenv('DB_USERNAME')
password = os.getenv('DB_PASSWORD')
database = os.getenv('DB_NAME')

# FTP credentials
ftp_host = os.getenv('FTP_SERVER')
ftp_username = os.getenv('FTP_USERNAME')
ftp_password = os.getenv('FTP_PASSWORD')

openai_api_key = os.getenv('OPENAI_API_KEY')

def summarize_title(title, url, api_key):
    client = OpenAI(api_key=api_key)
    response = client.chat.completions.create(
        model="gpt-3.5-turbo",
        messages=[
            {"role": "system", "content": "You are a helpful assistant."},
            {"role": "user",
             "content": f"Current Webpage Title: {title}\nWebpage URL: {url}\n\nCould you give this webpage a one word title? do not add any other text as your output will be used in code."},
        ],
    )
    return response.choices[0].message.content

def normalize_url(url):
    url = url.split('?')[0].split('#')[0]
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
            try:
                response = requests.get(url)
                soup = BeautifulSoup(response.text, 'html.parser')
                title = 'Home'
                if i > 0:
                    title = soup.find('title').text if soup.find('title') else ''
                    if len(title.split(' ')) > 2 or len(title) < 1 or len(title) > 10:
                        title = summarize_title(title, url, api_key)
                url_titles.append((url, title))
            except (SSLError, ConnectionError) as e:
                logging.error(f"Error accessing {url}: {str(e)}")
        return url_titles
    except Exception as e:
        logging.error(f"Error in popular_urls: {e}")
        return []

def execute_query(db_host, db_username, db_password, db_database):
    try:
        logging.info("Connecting to MySQL database...")
        connection = mysql.connector.connect(
            host=db_host,
            user=db_username,
            password=db_password,
            database=db_database
        )

        if connection.is_connected():
            logging.info("Connected to MySQL database")
        else:
            logging.info("Failed to connect to MySQL database")
            return

        cursor = connection.cursor()
        cursor.execute("SELECT * FROM app_data WHERE status = 'UPDATE' AND published = ''")
        rows = cursor.fetchall()
        if not rows:
            logging.info("No data to process.")
            return
        for row in rows:
            process_row(row, cursor, ftp_host, ftp_username, ftp_password)
        cursor.close()
        connection.close()
    except mysql.connector.Error as e:
        logging.error(f"Error executing query: {e}")

if __name__ == "__main__":
    logging.info("Script started")
    execute_query(host, username, password, database)
