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
regex: re.Pattern = r'\b.{0,40}BUILD_NR\s{0,2}\:\s{0,2}Int\s{0,2}=\s{0,2}(?P<int_value>\d+)\b'
# consider >> let BUILD_NR : Int = 1717
print('= bump_build_nr.py is starting: =')

if not os.path.isfile(FILEPATH):
	print(f'❌ bump_build_nr.py failed finding FILEPATH - please correct the path: {FILEPATH}')


def incrementLastInt(input_line: str, regex: re.Pattern, addInt: int) -> str:
	if len(input_line) < 1:
		return input_line
	# will either return the same line it recieved, or change the line if it contains the contains string, looking for an int to increase by addInt amount
	result: str = input_line
	match: (re.Match | None) = re.search(regex, input_line)
	if match is not None:
		val = match.groupdict()['int_value']
		if type(val) is str and int(val) >= 0:
			# split the line arount this val:
			split_arr = input_line.split(val)

	# if len(arr) > 1:
	# result = arr[0] + contains + f'{int(arr[1]) + int(addInt)}\n'
	return result


# open Version file
def processfile(filepath: str):
	temp_file_name: str = ''
	was_changed = False
	with open(filepath, mode='r+', encoding='utf-8') as f:
		with NamedTemporaryFile(delete=False, mode='w+', encoding='utf-8') as fout:
			temp_file_name = fout.name
			for line in f:
				print(f'line: {line.strip()}')
				new_line = incrementLastInt(line, regex, +1)
				# fout.write(new_line)
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
