import mysql.connector
from PIL import Image
import requests
import sys
import os
import re

def replace_text_in_file(file_path, find_text, new_text):
    try:
        # Open the file in read mode
        with open(file_path, 'r') as file:
            lines = file.readlines()

        # Replace the line containing the find_text with the new_text
        updated_lines = [new_text if find_text in line else line for line in lines]

        # Open the file in write mode and write the updated data
        with open(file_path, 'w') as file:
            file.writelines(updated_lines)
        
        print(f"Text replaced successfully in {file_path}.")

    except FileNotFoundError:
        print(f"File {file_path} not found.")
    except Exception as e:
        print(f"An error occurred while replacing text in {file_path}: {e}")

def execute_query(db_host, db_username, db_password, db_database, query):
    global id, app_name, web_url, username, email_address, app_logo_name
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
            username = row[3]
            email_address = row[5]
            app_logo_name = row[6]
            package_name = row[18]
            if len(row[15])<10:
                admob_app_id = 'ca-app-pub-3940256099942544~3347511713'
            else:
                admob_app_id = row[15]
            if len(package_name)<5:
                package_name = to_package_name(app_name, id)
            print(id, app_name, web_url, username, email_address)

            while cursor.nextset():
                pass

            # Replace text in files
            file_path = [
                "android/app/src/main/AndroidManifest.xml",
                "android/app/src/main/AndroidManifest.xml",
                "lib/utils/constant.dart",
                "android/app/build.gradle",
                "android/app/google-services.json"
            ]
            
            find_text = [
                "android:label=",
                "ca-app-pub",
                "const BASE_URL =",
                "applicationId",
                '"package_name": '
            ]
            
            new_text = [
                f'        android:label="{app_name.replace("&", "&amp;")}"\n',
                f'            android:value="{admob_app_id}" />\n',
                f'const BASE_URL = "https://web2app.appcollection.in/downloads/01_Profiles/{id}";\n',
                f'        applicationId "{package_name}"\n',
                f'          "package_name": "{package_name}"\n'
            ]

            for fp, ft, nt in zip(file_path, find_text, new_text):
                replace_text_in_file(fp, ft, nt)
    
            # Open the file in write mode and write the updated data
            with open('app_id.txt', 'w') as file:
                file.write(str(id))
            
            # Update the status column to "Updated"
            update_query = "UPDATE app_data SET status = 'BUILDING', status_updated_at = NOW() WHERE id = %s"
            cursor.execute(update_query, (id,))
            connection.commit()
            print("Status column updated to 'BUILDING'")
        else:
            raise RuntimeError("There is no app for build.")

        # Close the cursor and connection
        cursor.close()
        connection.close()

    except mysql.connector.Error as e:
        print("Error executing query:", e)


def resize_image(input_path, output_path, size):
    with Image.open(input_path) as img:
        resized_img = img.resize(size)
        resized_img.save(output_path)

def generate_resized_images(original_image_path):
    sizes = {
        "hdpi": (72, 72),
        "mdpi": (48, 48),
        "xhdpi": (96, 96),
        "xxhdpi": (144, 144),
        "xxxhdpi": (192, 192),
    }

    for density, size in sizes.items():
        output_folder = f'android/app/src/main/res/mipmap-{density}'
        if not os.path.exists(output_folder):
            os.makedirs(output_folder)
        output_path = os.path.join(output_folder, "ic_launcher.png")
        resize_image(original_image_path, output_path, size)
        print(f"Generated {density} image: {output_path}")

def download_image(url, filename):
    response = requests.get(url)
    if response.status_code == 200:
        with open(filename, 'wb') as file:
            file.write(response.content)
        print(f"Image downloaded successfully as {filename}")
    else:
        print(f"Failed to download image. Status code: {response.status_code}")

def get_logo(url):
    main_url = 'https://besticon-demo.herokuapp.com/allicons.json?url='
    r = requests.get(main_url+url)
    best_icon = r.json()['icons'][0]['url']
    print(best_icon)
    return best_icon

def to_package_name(app_name, id):
    # Replace '&' with 'and', assuming '&' is not desired in package names
    app_name = app_name.replace('&', 'and')
    # Replace spaces and any non-alphanumeric characters (excluding '.') with '_'
    app_name = re.sub('[^0-9a-zA-Z]+', '_', app_name)
    # Convert to lowercase
    app_name = app_name.lower()
    # Ensure the package name starts with the specified domain
    app_name = 'com.appcollection.x' + app_name + str(id)
    return app_name

if __name__ == "__main__":
    try:
      # MySQL database credentials
      host = os.environ['DB_HOST']
      username = os.environ['DB_USERNAME']
      password = os.environ['DB_PASSWORD']
      database = os.environ['DB_NAME']
      
      # Example query
      query = "SELECT * FROM app_data WHERE status = 'PENDING_00' ORDER BY id DESC LIMIT 1"
  
      # Execute the query
      execute_query(host, username, password, database, query)

      download_image('https://appcollection.in/InstantWeb2App/icon.png', 'ic_launcher.png')
      try:
          if len(app_logo_name)>5:
              print(f'downloading {app_logo_name} file.')
              download_image('https://appcollection.in/InstantWeb2App/V08/uploads/'+app_logo_name, 'ic_launcher.png')
              print(f'Custom logo downloaded.')
          else:
              icon_url = get_logo('.'.join(web_url.split('/')[2].split('.')[-2:]))
              download_image(icon_url, 'ic_launcher.'+icon_url.split('.')[-1])
      except Exception as e:
          print(f'{web_url} has some error to download favicon.')
      original_image_path = "ic_launcher.png"
      generate_resized_images(original_image_path)

    except Exception as e:
      raise RuntimeError("Process Aborted.")
