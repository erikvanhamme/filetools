import argparse
import fnmatch
import hashlib
import os
import re
import shutil
import sqlite3

from PIL import Image
from PIL.ExifTags import TAGS

# ANSI Color Codes
RED = 31
GREEN = 32
YELLOW = 33
BLUE = 34
MAGENTA = 35
CYAN = 36
WHITE = 37

# Color print helper
def printc(text, color_code):
    print(f"\033[{color_code}m{text}\033[0m")

def initialize():
    # Connect to SQLite database named 'photo2.db'
    conn = sqlite3.connect('photo2.db')

    # Create a cursor for executing SQL commands
    c = conn.cursor()

    # Create a new table named 'version' if needed
    c.execute('CREATE TABLE IF NOT EXISTS version(version INTEGER NOT NULL);')

    # Commit the transaction
    conn.commit()

    # Fetch the data from the 'version' table
    c.execute("SELECT * FROM version;")
    version = c.fetchone()

    # Check if new database was created
    if (version == None):
        # Set version to 2
        c.execute('INSERT INTO version(version) VALUES(2);')

        # Create photos table
        c.execute('CREATE TABLE photos(number INTEGER PRIMARY KEY, tag TEXT NOT NULL, timestamp TEXT NOT NULL, ' +
                  'sha1 TEXT NOT NULL, nef TEXT NOT NULL, dng TEXT, nksc TEXT, xmp TEXT, jpg TEXT, moved INTEGER NOT NULL);')

        # Commit the transaction
        conn.commit()

        # Log new db creation
        printc("New database created.", YELLOW)

    else:
        # Bail out if incorrect version
        if (version[0] != 2):
            printc("Incompatible database version.", RED)
            conn.close()
            return None

    return conn


def extract_last_four_digits(s):
    pattern = r'(\d{4})$'
    match = re.search(pattern, s)
    
    if match:
        return int(match.group(1))
    else:
        return None
    

def filter_prefix(p, f, t):
    num = extract_last_four_digits(p)
    if ((f != None) and (t != None)):
        return ((num >= f) and (num <= t))
    elif (f != None):
        return (num >= f)
    else:
        return (num <= t)


def find_endswith(fg, e):
    for f in fg:
        if (f.lower().endswith(e)):
            return f
        
    return None


def filter_filegroup(fg):
    nef = find_endswith(fg, '.nef')
    dng = find_endswith(fg, '.dng')
    xmp = None
    if (dng != None):
        xmp = find_endswith(fg, '.dng.xmp')
    else:
        xmp = find_endswith(fg, '.nef.xmp')
    nksc = find_endswith(fg, '.nef.nksc')
    jpg = find_endswith(fg, '.jpg')

    # XMP supersedes nksc
    if (xmp != None):
        nksc = None

    filtered = []
    filtered.append(nef)
    if (dng != None):
        filtered.append(dng)
    else:
        filtered.append('')
    if (nksc != None):
        filtered.append(nksc)
    else:
        filtered.append('')
    if (xmp != None):
        filtered.append(xmp)
    else:
        filtered.append('')
    if (jpg != None):
        filtered.append(jpg)
    else:
        filtered.append('')

    return filtered


def find_filegroups(folder, f, t):
    # Collection of filtered and prepared filegroups
    filegroups = []

    # Initialize an empty list to store .NEF files
    nef_files = []

    # Walk through each directory and its subdirectories
    for root, dirs, files in os.walk(folder):
        for file in files:
            # Check if the file has a .NEF extension
            if fnmatch.fnmatch(file.lower(), '*.nef'):
                # Get the complete file path and add it to the list of .NEF files
                file_path = os.path.join(root, file)
                nef_files.append(file_path)

    # Get the prefix and related files for each nef file
    for nef_file in nef_files:
        filename = os.path.basename(nef_file)
        prefix = os.path.splitext(filename)[0]

        # Filter if needed
        if ((f != None) or (t != None)):
            if (filter_prefix(prefix, f, t) == False):
                continue

        # Initialize an empty list to store the matched files
        files_with_prefix = []

        # Walk through the directory and its subfolders
        for dirpath, dirnames, filenames in os.walk(folder):
            for file in fnmatch.filter(filenames, f"{prefix}*"):
                files_with_prefix.append(os.path.join(dirpath, file))

        # Filter relevant files from each filegroup
        filtered_fg = filter_filegroup(files_with_prefix)
        filegroups.append(filtered_fg)

    return filegroups


def sha1sum(file_path):
    # Create a sha1 hasher instance
    hasher = hashlib.sha1()

    # Open file in the binary mode
    with open(file_path, 'rb') as file_to_hash:
        # Read the file in chunks for better memory consumption
        buffer = file_to_hash.read(8192)
        while buffer:
            # Update the hasher with the current chunk
            hasher.update(buffer)
            buffer = file_to_hash.read(8192)

    # Return the SHA1 hash of the file in hexadecimal format
    return hasher.hexdigest()


def get_timestamp(image_file):
    # Open the image
    img = Image.open(image_file)

    # Get the EXIF data
    exif_data = img.getexif()

    # Get the timestamp from EXIF data
    for tag, value in exif_data.items():
        if TAGS.get(tag) == 'DateTime':
            return value
    return None


def add(conn, folder, tag, f, t):
    file_groups = find_filegroups(folder, f, t)

    cursor = conn.cursor()
    
    for file_group in file_groups:
        # Calculate the SHA1 hash of the .nef file
        sha1 = sha1sum(file_group[0])

        # Check if the SHA1 has is already in the database
        cursor.execute("SELECT COUNT(*) FROM photos WHERE sha1=\"" + sha1 + "\";")
        if (cursor.fetchone()[0] > 0):
            printc("Skipping " + file_group[0] + " because it is already in the database.", RED)
            continue

        # Get the exif timestamp of the picture
        timestamp = get_timestamp(file_group[0])

        # Build SQL query
        q = "INSERT INTO photos(tag, timestamp, sha1, nef, dng, nksc, xmp, jpg, moved) VALUES ("
        q += "\"" + tag + "\", "
        q += "\"" + timestamp + "\", "
        q += "\"" + sha1 + "\", "
        q += "\"" + file_group[0] + "\", "
        q += "\"" + file_group[1] + "\", "
        q += "\"" + file_group[2] + "\", "
        q += "\"" + file_group[3] + "\", "
        q += "\"" + file_group[4] + "\", "
        q += "0);"
        
        # Execute
        cursor.execute(q)
        conn.commit()

        # Log addition
        printc("Added photo " + file_group[0], GREEN)       


def move_file(conn, number, old, new, col):
    # Only move if needed
    if (old != new):
        printc("Moving file " + old + " to " + new, GREEN)

        # Create target folders if they do not exist
        os.makedirs(os.path.dirname(new), exist_ok=True)

        # Move the file to the target location
        shutil.move(old, new)

        # Update database
        q = "UPDATE photos SET " + col + " = \"" + new + "\" WHERE number = " + str(number) + ";"
        cursor = conn.cursor()
        cursor.execute(q)
        conn.commit()


def move(conn):
    # Get database cursor
    cursor = conn.cursor()

    # Iterate over all the unmoved items
    cursor.execute('SELECT * FROM photos WHERE moved = 0;')
    unmoved = cursor.fetchall()
    for item in unmoved:

        # Get data
        number = item[0]
        tag = item[1]
        timestamp = item[2]
        nef = item[4]
        dng = item[5]
        nksc = item[6]
        xmp = item[7]
        jpg = item[8]

        # Construct the base of the target filenames
        folder = "archive/" + tag + "/" 
        base = tag.replace('/', '-') + "_" + timestamp.replace(':', '-').replace(' ', '_')
        ext = ".nef"
        if (dng != ""):
            ext = ".dng"

        # Check if base already exists, and suffix a number if it does
        q = "SELECT COUNT(*) FROM photos WHERE nef LIKE \"" + (folder + base) + "\";"
        cursor.execute(q)
        count = cursor.fetchone()[0]
        if (count != 0):
            base += "_(" + str(count) + ")"

        # Targets
        nef_target = folder + base + ".nef"
        dng_target = folder + base + ".dng"
        nksc_target = folder + "NKSC_PARAM/" + base + ".nksc"
        xmp_target = folder + base + ext + ".xmp"
        jpg_target = folder + "jpg/" + base + ".jpg"

        # Move files, update references
        move_file(conn, number, nef, nef_target, "nef")
        if (dng != ""):
            move_file(conn, number, dng, dng_target, "dng")
        if (nksc != ""):
            move_file(conn, number, nksc, nksc_target, "nksc")
        if (xmp != ""):
            move_file(conn, number, xmp, xmp_target, "xmp")
        if (jpg != ""):
            move_file(conn, number, jpg, jpg_target, "jpg")

        # Tag all moves complete.
        q = "UPDATE photos SET moved = 1 WHERE number = " + str(number) + ";"
        cursor.execute(q)
        conn.commit()
        printc("Done.", GREEN)

        
def adopt(conn, folder):
    # Collect the list of folders and their tags, in pairs
    pairs = []

    # Walk through each directory and its subdirectories
    for root, dirs, files in os.walk(folder):
        for file in files:
            # Check if the file has a .NEF extension
            if fnmatch.fnmatch(file.lower(), '*.nef'):
                tag = root.replace(folder, "")
                pair = []
                pair.append(root)
                pair.append(tag)
                pairs.append(pair)
    dedup_set = set(tuple(x) for x in pairs)
    dedup_list = [list(x) for x in dedup_set]
    
    for pair in dedup_list:
        folder = pair[0]
        tag = pair[1]

        add(conn, folder, tag, None, None)
    

# Start banner
printc("Photo organizer [tool V2, database V2]", CYAN)
printc("  Copyright 2023 Erik Van Hamme (erik.vanhamme@gmail.com)", CYAN)

# Get connection
conn = initialize()
if (conn == None):
    exit(-1)

# Parse args
parser = argparse.ArgumentParser(description="Photo organizer input tags.")
parser.add_argument("--tag", dest="tag", type=str, default=None, help="Tag input")
parser.add_argument("--add", dest="add", type=str, default=None, help="Add action")
parser.add_argument("--adopt", dest="adopt", type=str, default=None, help="Adopt library")
parser.add_argument("--move", dest="move", action='store_true', default=False, help="Move action")
parser.add_argument("--links", dest="links", action='store_true', default=False, help="Links action")
parser.add_argument("--from", dest="f", type=int, default=None, help="Filter from")
parser.add_argument("--to", dest="t", type=int, default=None, help="Filter to")
args = parser.parse_args()

# Actions
if (args.add != None):
    if (args.tag == None):
        parser.print_usage()
    else:
        add(conn, args.add, args.tag, args.f, args.t)
elif (args.move):
    move(conn)
elif (args.adopt):
    adopt(conn, args.adopt)
elif (args.links):
    print('TODO: implement linking')
else:
    printc("Nothing to do. Exiting.", YELLOW)

# Clean up
conn.close()