# taken from # https://github.com/AbstractGeek/my-dotfiles-macos/blob/main/bin/obsidian-quartz-sync.py

#!/usr/bin/env python3

## Constants
config_default = "~/gitfolder/.dotfiles/scripts/obsidian-quartz-sync.yml"

## Imports
import os
import sys
from glob import glob
import yaml
import frontmatter
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
    with open(md, "r") as f:
        try:
            post = frontmatter.load(f)
        except:
            logging.error(f"Error loading {md}")
            return None, None
    
    # check if publish
    if "publish" in post and post["publish"] and "path" in post:
        return post["path"], post["assets"] if "assets" in post else []
    else:   
        return None, None


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
    with open(src, 'r') as f:
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
        with open(dest, "w") as f:
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
    with open(config_file, "r") as f:
        read_data = f.read()
    config = yaml.safe_load(read_data)

    # Set up logging
    log_file = os.path.expanduser(config["log_file"])
    logging.basicConfig(
        filename=os.path.expanduser(log_file),
        level=logging.INFO,
        format="%(asctime)s - %(message)s",
    )

    # Get source and destination folders
    src = os.path.expanduser(config["obsidian_folder"])
    dest = os.path.expanduser(config["quartz_folder"])
    asset_dir = os.path.expanduser(config["attachment_folder"])
    sync_files = []
    assets = []

    # Find md files with publish and its assets
    for md in glob(os.path.join(src, "**/*.md"), recursive=True):
        path, asset = find_publish_mds(md, config["ignore_folders"])
        if path:
            if ".md" in path:
                sync_files.append((md, os.path.join(dest, path)))
            else:
                #print('md: %s -> copied to: %s'%(md, os.path.join(dest, path, os.path.basename(md))))
                sync_files.append((md, os.path.join(dest, path, os.path.basename(md))))
        if asset:
            for fn in asset:
                assets.append((find_asset(src, fn), os.path.join(dest, asset_dir, fn[2:-2])) )

    # sync files based on date modified
    for src, dest in sync_files:
        if not src:
            continue
        if not os.path.exists(os.path.dirname(dest)):
            os.makedirs(os.path.dirname(dest))
        if os.path.exists(dest):
            if os.path.getmtime(src) > os.path.getmtime(dest):
                logging.info(f"Updating {dest}")
                copy_public_text(src, dest)
        else:
            logging.info(f"Copying {dest}")
            copy_public_text(src, dest)

    # asset files based on date modified
    for src, dest in assets:
        if not src:
            continue
        if not os.path.exists(os.path.dirname(dest)):
            os.makedirs(os.path.dirname(dest))
        if os.path.exists(dest):
            if os.path.getmtime(src) > os.path.getmtime(dest):
                logging.info(f"Updating {dest}")
                copy_assets(src, dest, config["watermark"])
        else:
            logging.info(f"Copying {dest}")
            copy_assets(src, dest, config["watermark"])

    # sync complete

# get path
if __name__ == "__main__":
    # get argument
    if len(sys.argv) == 1:
        config_file = os.path.expanduser(config_default)
    elif len(sys.argv) == 2:
        config_file = os.path.expanduser(sys.argv[2])         
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