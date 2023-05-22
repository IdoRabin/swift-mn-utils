# !/usr/bin/env python3
# Ido Rabin @ Mar 2023
# python3

# bump.py
# Bumps build number or version by finding a line with a specified "anchor" in a specified source file. Assumes the version number is stored in semver format. Build number may also be stored in a saparate variable. Build number only may be expressed as an strng of int or a hex string.
# NOTE: it is bad grammer, but still the convention here is that the prefix "is_" denote this is a boolean variable.

# == : unused : ==
# import typing
# import fileinput
# from subprocess import check_output
# import itertools

import os
import re
import argparse
import semver
from typing import List, Tuple, Optional

class Detection:
    def __init__(self, filepath: str, file_extension: str, encoding: str, line_nr: int, orig_line: str, orig_line_fragment: str, detected_span: Tuple[int, int]):
        self.filepath = filepath
        self.file_extension = file_extension
        self.encoding = encoding
        self.line_nr = line_nr
        self.orig_line = orig_line
        self.orig_line_fragment = orig_line_fragment
        self.detected_span = detected_span
        self.latest_ver: Optional[semver.VersionInfo] = None
        self.type = 'unknown'

def find_files(root_folder: str, exclude_regexes: List[str], extension_regexes: List[str], filename_regexes: List[str]) -> List[str]:
    file_paths = []
    for folder_path, _, filenames in os.walk(root_folder):
        if should_exclude_folder(folder_path, exclude_regexes):
            continue

        for filename in filenames:
            if should_exclude_file(filename, extension_regexes, filename_regexes):
                continue

            file_path = os.path.join(folder_path, filename)
            file_paths.append(file_path)
    print(f'find_files: {file_paths}')
    return file_paths

def should_exclude_folder(folder_path: str, exclude_regexes: List[str]) -> bool:
    return any(re.match(regex, folder_path) for regex in exclude_regexes)

def should_exclude_file(filename: str, extension_regexes: List[str], filename_regexes: List[str]) -> bool:
    return any(re.match(regex, filename) for regex in extension_regexes) or any(re.match(regex, filename) for regex in filename_regexes)

def detect_version_strings(file_paths: List[str], line_regexes: dict) -> List[Detection]:
    detections = []
    for file_path in file_paths:
        with open(file_path, 'r', encoding='utf-8', errors='ignore') as file:
            for line_nr, line in enumerate(file, start=1):
                file_ext = get_file_extension(file_path)
                if file_ext:
                    regexes = line_regexes.get(file_ext.lower())
                    if regexes:
                        detection = find_detection(line, regexes, file_path, file_ext, line_nr)
                        if detection:
                            detections.append(detection)

    return detections

def get_file_extension(file_path: str) -> Optional[str]:
    _, file_ext = os.path.splitext(file_path)
    return file_ext.lower()

def find_detection(line: str, regexes: List[re.Pattern], file_path: str, file_ext: str, line_nr: int) -> Optional[Detection]:
    for regex in regexes:
        match = regex.search(line)
        if match:
            orig_line_fragment = match.group('semver') or match.group('build_nr')
            detected_span = match.span('semver') or match.span('build_nr')
            detection = Detection(
                filepath=file_path,
                file_extension=file_ext,
                encoding='utf-8',
                line_nr=line_nr,
                orig_line=line,
                orig_line_fragment=orig_line_fragment,
                detected_span=detected_span
            )
            return detection

    return None

def determine_version(detections: List[Detection], force_version: Optional[str]) -> (semver.VersionInfo | None):
    if force_version:
        try:
            return semver.parse(force_version)
        except ValueError:
            pass

    versions = [d.latest_ver for d in detections if d.latest_ver is not None and d.type != 'unknown']
    if versions:
        return max(versions, key=versions.count)

    if len(detections) == 0:
        return None

    print('Unable to determine the version automatically.')
    print('Please choose the detection to determine the version:')
    print()
    for i, detection in enumerate(detections, start=1):
        print(f'[{i}] {os.path.basename(detection.filepath)} | Line: {str(detection.line_nr).zfill(5)} | Version: {detection.orig_line_fragment}')
    print('[exit] Exit the script')

    while True:
        choice = input('Enter the number of the detection or "exit": ')
        if choice.lower() == 'exit':
            exit(0)
        try:
            index = int(choice) - 1
            if index >= 0 and index < len(detections):
                selected_detection = detections[index]
                version_str = selected_detection.orig_line_fragment
                try:
                    return semver.parse(version_str)
                except ValueError:
                    print('Invalid version format. Please choose another detection.')
            else:
                print('Invalid choice. Please choose another detection.')
        except ValueError:
            print('Invalid input. Please choose another detection.')

if __name__ == '__main__':
    parser = argparse.ArgumentParser(prog='Bump', description='Bumps build number or version by finding files with lines where the apps\' version appears using regexes, and bumping the version. Saves a valid version in all the needed locations. User may explicitly specify the root dir for the search (-p / -path arguments) or we are assuming the search should start one folder above the "current" run folder',
									epilog='Thanks')
    
    parser.add_argument('-b', '-base_folder', required=False, default='', type=str, help='The base - root folder to start the search')

    parser.add_argument('-v', '-version_forced', required=False, default='', type=str, help='Specify the version to fore into all version or build number locations detected in all files found in the tree, after all regex exclusions')

    parser.add_argument('-s', '-semver', '-semverpart', choices=['major', 'minor', 'patch', 'build'], default='build', help='Specify which part of the version string you want to bump: [major], [minor] or [build] number. Bumping the major version number will also zero the minor version and build count. Bumping the minor version will zero the build counter. Bumping the build number will increment it by one.')

    parser.add_argument('-e', '-exactver', required=False, default='', help='Specify an exact smever-complient string to set (and not "bump") the version in all the lines a version number or build nt is needed.')

    parser.add_argument('-f', '-file', required=False, default='', help='Specify a single source file where the version / build number string is stored (and needs to be bumped), and use that version to bump and apply to all other locations where a valid app version number appears.')

    parser.add_argument('-r', '-regex', required=False, default='', help='Specify a specific sourcefile regex where the verion / build number reside. The regex should capture one group only. NOTE: This is used ONLY when the -f/-file argument is also specified.')

    parser.add_argument('-g', '-git', '-git_tag', action='store_true', default=True, help='Specify if the script should locate the nearest git repository (up to 4 folders back) and commit the applied (bumped) semver version as a tag to the current branch in the git.')

    parser.add_argument('-p', '-path', required=False, default='../', help='Specify a specific root path to search for files - the search will be recursive downtree from this path and doewn. default is ../, i.e one folder above the "current".')

    parser.add_argument('-l', '-log', required=False, default=False, help='The script should log in a verbose manner.')

    args = parser.parse_args()

    # Hard coded:
    excl_line_regexes = {
        '.py': [re.compile(r'(?P<semver>\d+\.\d+\.\d+)')],
        '.txt': [re.compile(r'(?P<build_nr>\d+\.\d+\.\d+)')]
    }
    excl_folder_regexes = [
        r'\.git', r'scripts', r'script'
    ]
    excl_extension_regexes = [
        r'csv'
    ]
    excl_extension_filename = [
        r'bump.{0.12}.py'
    ]

    file_paths = find_files(args.b, excl_folder_regexes, excl_extension_regexes, excl_extension_filename)
    detections = detect_version_strings(file_paths, excl_line_regexes)
    version = determine_version(detections, args.v)

    print(f'Detected version: {version}')