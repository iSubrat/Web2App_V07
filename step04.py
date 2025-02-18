import os
import re
import sys
import uuid
import requests
import smtplib
import mysql.connector
from ftplib import FTP
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart


def send_email(sender_email, sender_password, username, recipient_email, subject, id, appname, app_logo_url, appname_link):
    try:
        email_host = os.environ['EMAIL_HOST']
        email_port = os.environ['EMAIL_PORT']
        
        # Generate a unique message ID
        message_id = f"<{uuid.uuid4()}@{email_host}>"
        
        # Setup the email message with Message-ID header
        email_message = MIMEMultipart()
        email_message['From'] = sender_email
        email_message['To'] = recipient_email
        email_message['Subject'] = subject
        email_message['Message-ID'] = message_id  # Add Message-ID header

        digit_sum = sum(int(digit) for digit in str(id))

        # Styling
        html_message = f"""
        <html>
            <style>
                body {{
                    font-family: 'Arial', sans-serif;
                    margin: 0;
                    padding: 0;
                    background-color: white;
                }}
                header {{
                    text-align: center;
                    background-color: #E72A73;
                    color: #ffffff;
                    padding: 20px 0;
                }}
                div {{
                    background-color: white;
                    color: #000;
                    font-size: 14px;
                    margin: 10px;
                }}
                .button {{
                    display: inline-flex; /* Use flexbox */
                    align-items: center; /* Center vertically */
                    padding: 10px 20px;
                    background-color: #E72A73; /* Blue color */
                    color: white;
                    text-decoration: none;
                    border-radius: 5px;
                    font-size: 16px;
                    margin-bottom: 10px;
                }}
                .button img {{
                    border-radius: 10%; /* Make image corners round */
                    margin-right: 10px; /* Add some space between the image and text */
                }}
                .button-secondary {{
                    background-color: #f4be41;
                    font-weight: bold;
                    color: white;
                }}
                #hidden_url {{
                    text-decoration: none;
                    color: inherit;
                }}
            </style>
            <body>
            <a id="hidden_url" href="https://play.google.com/store/apps/details?id=com.appcollection.web2app">
                <header>
                    <h1>Web2App</h1>
                    <p>Convert Websites to Android Apps</p>
                </header>
            </a>
                <div style="text-align: left;">
                    <p>Dear {username},<br>Congratulations! Your app {appname} is ready to download. Please click the below button:</p>
                    <a href="http://web2app.appcollection.in/V08/download.php?id={id}{str(digit_sum).zfill(2)}" class="button"><img src="{app_logo_url}" alt="Download" style="width: 25px; height: 25px;"> Download Your App ({appname_link})</a><br>
                    <br>
                    <br>
                    <h4>- Subrat Gupta<br>Web2App Team</h4>
                </div>
            </body>
        </html>"""
        email_message.attach(MIMEText(html_message, 'html'))

        # # Attach the logo
        # with open('logo.png', 'rb') as logo:
        #     logo_content = logo.read()
        #     logo_part = MIMEImage(logo_content)
        #     logo_part.add_header('Content-ID', '<logo>')
        #     email_message.attach(logo_part)

        # Create SMTP session for sending the mail
        with smtplib.SMTP_SSL(email_host, email_port) as session:
            session.login(sender_email, sender_password)
            session.sendmail(sender_email, recipient_email, email_message.as_string())

        print("Email sent successfully!")
    except Exception as e:
        print(f"Error: {e}")


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
        cursor = connection.cursor(dictionary=True)

        # Execute the query
        cursor.execute(query)

        # Fetch all the rows
        row = cursor.fetchone()

        # Print the rows
        if row:
          id = row["id"]
          appname = row["app_name"]
          pattern = re.compile(r'[^a-zA-Z0-9_]')
          appname_link = str(id).zfill(4) + '_' + pattern.sub('', row["app_name"]) + '.apk'
          username = row["user_name"]
          recipient_email = row["email_address"]
          app_logo = row["app_logo_name"]
          
          try:
              if len(app_logo)>5:
                  app_logo_url = f'https://web2app.appcollection.in/V08/uploads/{app_logo}'
              else:
                  app_logo_url = 'https://web2app.appcollection.in/icon.png'
          except Exception as e:
              app_logo_url = 'https://web2app.appcollection.in/icon.png'
       
          while cursor.nextset():
            pass
          email_username = os.environ['EMAIL_USERNAME']
          email_password = os.environ['EMAIL_PASSWORD']
          sender_email = email_username
          sender_password = email_password
          subject = 'Your App is Ready to Download'

          ftp_host = os.environ['FTP_SERVER']
          ftp_username = os.environ['FTP_USERNAME']
          ftp_password = os.environ['FTP_PASSWORD']

          send_email(sender_email, sender_password, username, recipient_email, subject, id, appname, app_logo_url, appname_link)
          # send_email(sender_email, sender_password, username, 'isubrat@icloud.com', subject, id, appname, app_logo_url, appname_link)

          # Update the status column to "Updated"
          update_query = "UPDATE app_data SET status = 'COMPLETED', status_updated_at = NOW() WHERE id = %s"
          cursor.execute(update_query, (id,))
          connection.commit()
          print("Status column updated to 'COMPLETED'")
        else:
          raise RuntimeError("There is no app for build.")

        # Close the cursor and connection
        cursor.close()
        connection.close()

    except mysql.connector.Error as e:
        print("Error executing query:", e)

if __name__ == "__main__":
  try:
    # MySQL database credentials temp
    host = os.environ['DB_HOST']
    username = os.environ['DB_USERNAME']
    password = os.environ['DB_PASSWORD']
    database = os.environ['DB_NAME']

    # Example query
    query = "SELECT * FROM app_data WHERE status = 'BUILDING' ORDER BY id DESC LIMIT 1"

    # Execute the query
    execute_query(host, username, password, database, query)
    
    url = "http://server.appcollection.in/delete.php"
    response = requests.get(url)
    if response.status_code == 200:
        print("Request was successful!")
        print(response.content)
    else:
        print(f"Request failed with status code: {response.status_code}")
  except Exception as e:
    raise RuntimeError("Process Aborted.")
