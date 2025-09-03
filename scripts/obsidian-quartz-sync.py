# taken from # https://github.com/AbstractGeek/my-dotfiles-macos/blob/main/bin/obsidian-quartz-sync.py

#!/usr/bin/env python3

## Constants
config_default = "~/gitfolder/.dotfiles/scripts/obsidian-quartz-sync.yml"

## Imports
import os
import sys
from glob import glob
import yaml
import frontmatter # pip install python-frontmatter
import logging
import shutil
import subprocess
# from pprint import pprint

## Functions
def find_publish_mds(md, ignore):
    '''find md files with publish'''
    # check if md file is not in one of the ignored folders
    for folder in ignore:
        if folder in md:
            return None, None
    # load md file
    try:
        post = frontmatter.load(md)
    except Exception as e:
        logging.error(f"Error loading {os.path.basename(md)}: {e}")
        return None, None
    
    # check if publish and title length
    if "publish" not in post:
        return None, None
    
    if not post["publish"]:
        return None, None
        
    title = post.get("title", "") or ""
    if len(title) < 4:
        logging.debug(f"Skipping {os.path.basename(md)} (title too short: '{title}')")
        return None, None
        
    return True, post["assets"] if "assets" in post else []


def find_asset(src, fn):
    '''find asset in md file'''
    fn = fn[2:-2]
    files = [file for file in glob(os.path.join(src, "**", fn), recursive=True)]
    if len(files) == 0:
        logging.error(f"Asset {fn} not found")
        return None
    elif len(files) > 1:
        logging.error(f"Multiple assets found for {fn}")
        return None
    else:
        return files[0]


def copy_public_text(src, dest):
    '''copy public text to destination'''
    print(src)
    with open(src, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    # find start and stop of private text
    start = [i for i, e in enumerate(lines) if '%%private-start%%' in e]
    stop = [i for i, e in enumerate(lines) if '%%private-stop%%' in e]

    # make sure start and stop are in pairs
    if len(start) != len(stop):
        if len(start) - len(stop) > 1:
            logging.error(f"Private text start and stop not in pairs in {src}")
            return None
        else:
            stop.append(len(lines)-1)

    # if no private text, copy all
    if len(start) == 0:
        shutil.copy2(src, dest)
    else:
        for r in reversed(range(len(start))):
            lines[start[r]:stop[r]+1] = []    
        # write to destination
        with open(dest, "w", encoding='utf-8') as f:
            f.writelines(lines)

    return None

def copy_assets(src, dest, config):
    # check if asset is a pdf
    if (os.path.splitext(src)[1] == '.pdf'):
        # place watermarked pdfs at destination
        watermark_pdf(src, dest, config["pdf"])
    else:
        # place watermarked image
        watermark_image(src, dest, config["img"])

def watermark_pdf(src, dest, config):
    # use ghostscript to add a copyright to pdfs
    result = subprocess.run(
        [
            'gs',
            '-dBATCH',
            '-dNOPAUSE',
            '-q',
            '-sDEVICE=pdfwrite',
            '-o', dest,
            config["postscript"],
            src,
        ]
    )
    if result.stdout:
        logging.info("Ghostscript: %s" % (result.stdout))
    if result.stderr:
        logging.error("Ghostscript: %s" % (result.stderr))

def watermark_image(src, dest, config):
    # use imagemagick to add a copyright to images
    result = subprocess.run(
        [
            "magick",
            src,
            "-gravity",
            "SouthEast",
            "-append",
            "-strip",
            "-pointsize",
            "%%[fx:h*%s]" % (config["fontsize"]),
            "-annotate",
            config["offset"],
            config["copyright"],
            dest,
        ]
    )
    if result.stdout:
        logging.info("Imagemagick: %s" % (result.stdout))
    if result.stderr:
        logging.error("Imagemagick: %s" % (result.stderr))    


## Main
def main(config_file):
    # Load config
    with open(config_file, "r", encoding="utf-8") as f:
        read_data = f.read()
    config = yaml.safe_load(read_data)

    # Set up logging to both file and console
    log_file = os.path.expanduser(config["log_file"])
    logger = logging.getLogger()
    logger.setLevel(logging.DEBUG)
    
    # File handler with timestamps
    file_handler = logging.FileHandler(log_file)
    file_handler.setLevel(logging.DEBUG)
    file_formatter = logging.Formatter("%(asctime)s - %(message)s")
    file_handler.setFormatter(file_formatter)
    
    # Console handler without timestamps  
    console_handler = logging.StreamHandler()
    console_handler.setLevel(logging.DEBUG)
    console_formatter = logging.Formatter("%(message)s")
    console_handler.setFormatter(console_formatter)
    
    logger.addHandler(file_handler)
    logger.addHandler(console_handler)
    
    logging.info("Starting Obsidian-Quartz sync...")

    # Get source and destination folders
    src = os.path.expanduser(config["obsidian_folder"])
    dest = os.path.expanduser(config["quartz_folder"])
    asset_dir = os.path.expanduser(config["attachment_folder"])
    sync_files = []
    assets = []

    # Find md files with publish and its assets
    logging.info(f"Scanning for markdown files in: {src}")
    md_files = glob(os.path.join(src, "**/*.md"), recursive=True)
    logging.info(f"Found {len(md_files)} markdown files")
    
    processed = 0
    published = 0
    
    for md in md_files:
        processed += 1
        should_publish, asset = find_publish_mds(md, config["ignore_folders"])
        if should_publish:
            published += 1
            logging.info(f"✓ Publishing: {os.path.basename(md)}")
            # Calculate relative path from source directory to preserve folder structure
            rel_path = os.path.relpath(md, src)
            dest_file = os.path.join(dest, rel_path)
            sync_files.append((md, dest_file))
            
            if asset:
                logging.info(f"  - Found {len(asset)} assets for {os.path.basename(md)}")
                for fn in asset:
                    asset_src = find_asset(src, fn)
                    if asset_src:
                        # Calculate relative path for asset to preserve folder structure
                        asset_rel_path = os.path.relpath(asset_src, src)
                        asset_dest = os.path.join(dest, asset_rel_path)
                        assets.append((asset_src, asset_dest))
    
    logging.info(f"Processing complete: {published} files marked for publishing out of {processed} total")

    # sync files based on date modified
    logging.info(f"Syncing {len(sync_files)} markdown files...")
    updated_files = 0
    new_files = 0
    
    for src_file, dest_file in sync_files:
        if not src_file:
            continue
        if not os.path.exists(os.path.dirname(dest_file)):
            os.makedirs(os.path.dirname(dest_file))
        if os.path.exists(dest_file):
            if os.path.getmtime(src_file) > os.path.getmtime(dest_file):
                logging.info(f"Updating {os.path.basename(dest_file)}")
                copy_public_text(src_file, dest_file)
                updated_files += 1
        else:
            logging.info(f"Copying {os.path.basename(dest_file)}")
            copy_public_text(src_file, dest_file)
            new_files += 1

    # asset files based on date modified
    logging.info(f"Syncing {len(assets)} assets...")
    updated_assets = 0
    new_assets = 0
    
    for src_asset, dest_asset in assets:
        if not src_asset:
            continue
        if not os.path.exists(os.path.dirname(dest_asset)):
            os.makedirs(os.path.dirname(dest_asset))
        if os.path.exists(dest_asset):
            if os.path.getmtime(src_asset) > os.path.getmtime(dest_asset):
                logging.info(f"Updating asset {os.path.basename(dest_asset)}")
                copy_assets(src_asset, dest_asset, config["watermark"])
                updated_assets += 1
        else:
            logging.info(f"Copying asset {os.path.basename(dest_asset)}")
            copy_assets(src_asset, dest_asset, config["watermark"])
            new_assets += 1

    # Mirror sync: remove files that shouldn't exist in target
    logging.info("Mirroring target directory...")
    deleted_count = 0
    
    # Get all expected files (both md and assets)
    expected_files = set(dest_file for _, dest_file in sync_files)
    expected_files.update(dest_asset for _, dest_asset in assets)
    
    # Find all files currently in target
    target_files = glob(os.path.join(dest, "**/*"), recursive=True)
    target_files = [f for f in target_files if os.path.isfile(f)]
    
    # Delete files that shouldn't exist
    for target_file in target_files:
        if target_file not in expected_files:
            logging.info(f"Deleting removed file: {os.path.relpath(target_file, dest)}")
            os.remove(target_file)
            deleted_count += 1

    # sync complete
    logging.info("Sync complete!")
    logging.info(f"Files: {new_files} new, {updated_files} updated")
    logging.info(f"Assets: {new_assets} new, {updated_assets} updated") 
    logging.info(f"Deleted: {deleted_count} files removed from target")

# get path
if __name__ == "__main__":
    # get argument
    if len(sys.argv) == 1:
        config_file = os.path.expanduser(config_default)
    elif len(sys.argv) == 2:
        config_file = os.path.expanduser(sys.argv[1])         
    else:
        print("Usage: obsidian-quartz-sync <config-path>")
        sys.exit(1)

    # check if config file exists
    if not os.path.exists(config_file):
        print(config_file)
        print("Config file does not exist")
        sys.exit(1)

    # run main
    main(config_file)