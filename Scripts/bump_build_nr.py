#!/usr/bin/env python3

# bump_build_nr.py
# Bumps build version to an APP_VERSION file containing hard-coded SemVer 2.0 struct definition:
# Ido Rabin @ Sept 2022
# python3

from typing import List, Tuple, Optional
import fileinput
from subprocess import check_output
import re
import sys
import os
import fileinput
from tempfile import NamedTemporaryFile

# globals
FILEPATH: str = '/Users/syncme/xcode/MNUtils/MNUtils/Sources/MNUtils/Version.swift'
regex: re.Pattern = r'\b.{0,40}BUILD_NR\s{0,2}:\s{0,2}Int\s{0,2}=\s{0,2}(?P<version_int>\d+)\b'
print('= bump_build_nr.py is starting: =')
regex_key = 'version_int'
# consider >> let BUILD_NR : Int = 1717
print('= bump_build_nr.py is starting for MNUtils =')
if not os.path.isfile(FILEPATH):
	print(f'❌ bump_build_nr.py failed finding FILEPATH - please correct the path: {FILEPATH}')


def incrementLastInt(input_line: str, line_index: int, addInt: int) -> str:
    global regex
    global regex_key

    # will either return the same line it recieved, or change the line if it contains the contains string, looking for an int to increase by addInt amount
    result: str = input_line
    # match with the regex:
    match = re.search(regex, result)
    if match:
        dict = match.groupdict()
        for key in dict:
            if key == regex_key:
                span = match.span(key)
                value = int(match.group(key))
                prev = result.strip()
                start: int = int(span[0])
                end: int = int(span[1])
                if value > 0 and value < 6535600:
                    new_value = value + addInt
                    # Replace at span:
                    result = result[:start] + f'{new_value}' + result[end:]
                    print(f'    Found and bumped build nr line #{line_index} from: {value} to: {new_value}')
    return result


# open Version file
def processfile(filepath: str):
	temp_file_name: str = ''
	was_changed = False
	with open(filepath, mode='r+', encoding='utf-8') as f:
		with NamedTemporaryFile(delete=False, mode='w+', encoding='utf-8') as fout:
			temp_file_name = fout.name
			line_index = 0
			for line in f:
				print(f'#{line_index} {line.strip()}')
				new_line = incrementLastInt(line, line_index, +1)
				line_index += 1
				fout.write(new_line)
				if new_line != line:
					was_changed = True
	if was_changed:
		# os.rename(temp_file_name, filepath)
		print(f'✅  {FILEPATH} was successfully updated')
	else:
		print(f'✅  {FILEPATH} was NOT updated')


# main run:
processfile(FILEPATH)

## TODO:
# commit annotated tag
# git tag -a 1.4.2 -m "my version 1.4.2"
# -- DO NOT PUSH: git push --tags
