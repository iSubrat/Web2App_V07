import os
import re
import sys
import uuid
import requests
import smtplib
import urllib.parse
import mysql.connector
from ftplib import FTP
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart


def send_email(sender_email, sender_password, username, recipient_email, subject, id, appname, app_logo_url, appname_link, phone_number = ''):
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
                    <p>Dear {username},<br>Congratulations!</p>
                    <p>We're excited to offer you the opportunity to publish your android app <strong>{appname}</strong> ({id}) for just <strong>20 USD</strong>.</p>
                    <a href="https://www.fiverr.com/s/lj9e0aR" class="button"><img src="{app_logo_url}" alt="Place Order" style="width: 25px; height: 25px;"> {appname}</a><br>
                    <br>
                    <br>
                    <p>Your package includes:</p>
                    <ul>
                        <li>Releasable APK & AAB File</li>
                        <li>1 Hour of expert time (Zoom meeting for modifications/changes)</li>
                        <li>Unlimited platform access (make changes anytime)</li>
                        <li>Lifetime Validity</li>
                        <li>No Recurring Charges</li>
                    </ul>
                    <p><strong>Place order today!</strong> Let's make your app a success together.</p>
                    <a href="https://www.fiverr.com/s/lj9e0aR" class="button button-secondary">Place Order Now</a>
                    <br>
                    <br>
                    <h4>Cheers,<br>Subrat Gupta<br><strong>Web2App Team</strong></h4>
                </div>
            </body>
        </html>"""

        message = f'''*Congratulations {username}*!
We're excited to offer you the opportunity to publish your android app *{appname}* ({id}) for just *20 USD*.
Your package includes:
 - Releasable APK & AAB File
 - 1 Hour of expert time (Zoom meeting for modifications/changes)
 - Unlimited platform access (make changes anytime)
 - Lifetime Validity
 - No Recurring Charges
*Contact us today!* Let's make your app a success together.

Cheers,
Subrat Gupta
*Web2App Team*'''
        encoded_message = urllib.parse.quote(message)
        personalised_message_link = f'''https://api.whatsapp.com/send?phone={phone_number}&text={encoded_message}'''
        
        # Styling
        html_message_subrat = f"""
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
                    <p>Dear {username},<br>Congratulations!</p>
                    <p>We're excited to offer you the opportunity to publish your android app <strong>{appname}</strong> ({id}) for just <strong>20 USD</strong>.</p>
                    <a href="{personalised_message_link}" class="button"><img src="{app_logo_url}" alt="Place Order" style="width: 25px; height: 25px;"> {appname}</a><br>
                    <br>
                    <br>
                    <p>Your package includes:</p>
                    <ul>
                        <li>Releasable APK & AAB File</li>
                        <li>1 Hour of expert time (Zoom meeting for modifications/changes)</li>
                        <li>Unlimited platform access (make changes anytime)</li>
                        <li>Lifetime Validity</li>
                        <li>No Recurring Charges</li>
                    </ul>
                    <p><strong>Place order today!</strong> Let's make your app a success together.</p>
                    <a href="https://www.fiverr.com/s/lj9e0aR" class="button button-secondary">Place Order Now</a>
                    <br>
                    <br>
                    <h4>Cheers,<br>Subrat Gupta<br><strong>Web2App Team</strong></h4>
                </div>
            </body>
        </html>"""
        if recipient_email=='isubrat@icloud.com':
                email_message.attach(MIMEText(html_message_subrat, 'html'))
        else:
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
        cursor = connection.cursor()

        # Execute the query
        cursor.execute(query)

        # Fetch all the rows
        row = cursor.fetchone()

        # Print the rows
        if row:
          id = row[0]
          appname = row[1]
          pattern = re.compile(r'[^a-zA-Z0-9_]')
          appname_link = str(id).zfill(4) + '_' + pattern.sub('', row[1]) + '.apk'
          username = row[3]
          phone_number = row[4][1:]
          recipient_email = row[5]
          app_logo = row[6]
          
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
          send_email(sender_email, sender_password, username, 'isubrat@icloud.com', subject, id, appname, app_logo_url, appname_link, phone_number)

          # Update the status column to "Updated"
          update_query = "UPDATE app_data SET status = 'SENT', status_updated_at = NOW() WHERE id = %s"
          cursor.execute(update_query, (id,))
          connection.commit()
          print("Status column updated to 'SENT'")
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
    query = "SELECT * FROM app_data WHERE status = 'SUBMITTED' ORDER BY id DESC LIMIT 1"

    # Execute the query
    execute_query(host, username, password, database, query)
    
    # url = "http://server.appcollection.in/delete.php"
    # response = requests.get(url)
    # if response.status_code == 200:
    #     print("Request was successful!")
    #     print(response.content)
    # else:
    #     print(f"Request failed with status code: {response.status_code}")
  except Exception as e:
    raise RuntimeError("Process Aborted.")
