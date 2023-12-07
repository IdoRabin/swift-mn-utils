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

import re
import sys
import os
from tempfile import NamedTemporaryFile
import argparse
import semver
from charset_normalizer import detect, CharsetMatch
import traceback
import string
from typing import List, Callable
from collections import Counter

global_args = {}
#  MARK: Classes


class GlobalConstants:
	OK_EMOJI: str = "✅"
	FAIL_EMOJI: str = "❌"
	EMPTY_EMOJI: str = "×"
	CHECK_EMOJI: str = "✓"
	MAX_FOLDER_DEPTH: int = 2
	MIN_FILE_LEN: int = 3
	MAX_FILE_LEN: int = 256999
	MIN_LINE_LEN: int = 2
	MAX_LINE_LEN: int = 256
	MIN_WORD_LEN: int = 3
	MAX_WORD_LEN: int = 64
	MAX_SEMVER_LEN: int = 128  # maximum chars per semver (as a string)
	MIN_SEMVER_BUILD_NR: int = 0
	MAX_SEMVER_BUILD_NR: int = 9999

	EXCEPTION_FILTER_KEY: str = "exception_filter_key"

	# example:>>   let MNUTILS_VERSION = "0.1.0"
	SEMVER_REGEXES: list[re.Pattern] = [
		r'\b(?P<semver_major>0|[1-9]\d*)\.(?P<semver_minor>0|[1-9]\d*)\.(?P<semver_patch>0|[1-9]\d*).{0,1}(?P<semver_prerelease>\w+)?.{0,1}(?P<semver_build_nr>[\dxX×]+)?\b'
		]

	# OLD VERSIONS:
	# hex \b(?P<build_nr_hex>0[xX][\da-fA-F]+)\b
	# int \b(?P<build_nr_int>[^xX]\d{1,5})\b
	# \b(?P<build_nr_int>[^xX]\d{1,5})\b
	BUILD_NR_REGEXES: list[re.Pattern] = [
		r'\b(?P<build_nr_hex>0[xX][\da-fA-F]+)\b',
		r'(?P<build_nr_int>([+-]|\b)?(\d{1,5})(\.[\d]{1,5})?\b)']
		
	IGNORED_FOLDER_REGEXES: list[re.Pattern] = [
		r'\.git.{0,64}', r'/\.git.{0,64}/',
		r'.{0,14}build.{0,14}', r'.{0,14}cocoa.{0,14}', r'.{0,14}pods.{0,14}',
		r'.{0,14}carthag.{0,14}', r'\.swiftpm.{0,14}']

	IGNORED_FILENAME_REGEXES: list[re.Pattern] = [
		r'^\.{1,64}[\.]{0,1}.{0,64}',  # no prefix dot
		r'bump\.py', 'bump\.py\.{0,64}',
		r'[Ee]rror.{0,4}[Cc]ode$',
		r'[Dd][Ss]_[Ss]tore$',
		r'\.vscode.{0, 200}$',
		r'package\.swift',
		]

	IGNORED_FILE_EXTENSIONS: list[re.Pattern] = [
		r'log', r'db', r'sql', r'sqlite',
		r'postgre', r'mongo', r'temp', r'tmp', r'flake8', r'ini',  # misc types
		r'doc', r'xls', r'pdf', r'eps', r'csv',  # document types
		r'xib', r'storyboard', r'png', r'gif', r'jpg', r'bmp', r'ico', r'jpeg',
		r'tif', r'tiff', r'svg', r'pict',  # image types
		r'mov', r'qtm', r'avi', r'mkv', r'flic', r'swf', r'lottie'  # movie types
		]

	# dict[str: list[re.Pattern]]
	# if found in the prev line, we exclude the following line 
	# from being alligable for version detection/update
	IGNORED_BY_PREV_LINE_FOR_FTYPE:  dict[str: list[re.Pattern]] = {
		'*': [],
		'swift': [r'\bswitch\b'],
		'py': [r'$\#'],
	}

	# if found in the cur line (read about the arrow prefix below), we exclude that line 
	# from being alligable for version detection/update
	IGNORED_IN_LINE_FOR_FTYPE: dict[str: list[re.Pattern]] = {
		# PLACE < or > on 0th char or regex.
		#  '<' use only the string part preceeding the detected ver/bouild nr.
		#  '>' use only the string part following the detected ver/bouild nr. 
		'*': [r'<$case\s.{0, 30}\:\s', r'\s\!\=\s', r'bump.py: not part', r'bump.py: ignore semver', r'bump.py: ignore number'],
		'swift': [r'$//', r'$\\*'],
		'py': [r'$\#'],
	}

	# if found in the cur line we exclude all matches for version/build number that overlap this match.
	# from being alligable for version detection/update
	IGNORED_IN_LINE_OVERLAP_FOR_FTYPE: dict[str: list[re.Pattern]] = {
		'*': [r'\b\d{1,2}[/\\\s\.\-_]\d{1,2}[/\\\s\.\-_]\d{1,4}\b'],  # dd.mm.yy or dd.mm.yyyy
		'swift': [],
		'py': [],
	}

	# if found in the next line, we exclude the previous line 
	# from being alligable for version detection/update
	IGNORED_BY_NEXT_LINE_FOR_FTYPE: dict[str: list[re.Pattern]] = {
		'*': [],
		'swift': [r'\bswitch\b'],
		'py': [r'$\#'],
	}

	def line_nr_to_str(self, line_nr: int, fill_w: int = 4) -> str:
		return f'{line_nr or 0}'.zfill(fill_w or 4)


class GlobalArgs:
	semverpart_to_bump: str = None  # string
	exact_version: (semver.VersionInfo | None) = None  # semver.VersionInfo
	sourcefile: str = None  # source file where the version / build number string is stored
	is_update_git_tag: bool = False
	possible_paths: list[str] = []
	is_log_verbose: bool = False
	is_log_matching: bool = False  # will log the actual matching process, i.e the regex comparisons

	def as_dict(self) -> dict[str: any]:
		return {
			'semverpart_to_bump': self.semverpart_to_bump,
			'exact_version': self.exact_version,
			'sourcefile': self.sourcefile,
			'update_git_tag': self.is_update_git_tag,
			'possible_paths': self.possible_paths,
			'is_log_verbose': self.is_log_verbose,
			'is_log_matching': self.is_log_matching,
		}


class SuccessCounter:
	success: int = 0
	total: int = 0

	def count_failure(self) -> None:
		# count an operation as a failure
		self.total = self.total + 1

	def count_success(self) -> None:
		# count an operation as a success
		self.total = self.total + 1
		self.success = self.success + 1

	def ratio(self) -> float:
		if abs(self.total) < 0.01:
			return float(0.0)
		return float(self.success) / float(self.total)


class Match:
	filepath: str = None
	line_nr: int = None
	regex_used: str = None
	span: list[int] = None
	line_quote: str = None
	encoding_used: str = None
	last_bumped_v: semver.VersionInfo = None
	detection_type: str = 'unknown'  # may be 'semver', 'build_nr', 'build_nr_hex', 'in_str', 'no_caps', 'find_ver_str'
	original_before_any_bump: str = None
	line_before_match: str = None
	line_after_match: str = None

	def validate_a_span(self, orig: str, span: tuple[int]) -> (tuple[int], str):
		result: tuple[int] = span
		
		stripped = orig.strip().strip(string.punctuation)
		if len(stripped) < len(orig) and len(stripped) > max(max(len(orig) / 2, len(orig) - 4), 1):
			range = substring_range(orig, stripped)
			if range:
				start = span[0] + range[0]
				end = max(start + len(stripped) - 1, start)
				if span[0] != start or span[1] != end:
					result = tuple([start, end])

		return result

	def validate_span(self):
		if self.span is None or self.line_quote is None:
			return
		
		new_span = self.validate_a_span(self.line_quote, self.span)

		prfx = ' ' * 5
		str = self.found_match_str()

		stripped = str.strip().strip(string.punctuation)
		if len(stripped) < len(str) and len(stripped) > max(max(len(str) / 2, len(str) - 4), 1):
			range = substring_range(str, stripped)
			if range:
				start = self.span[0] + range[0]
				end = max(start + len(stripped) - 1, start)
				if self.span[0] != start or self.span[1] != end:
					prev = self.span
					self.span = tuple([start, end])
					# print(f'{prfx} validate_span fixed span: "{self.filename()}" | ln# {self.line_nr} | {prev}->{range} | matched: {self.found_match_str()} in full line: "{self.line_quote.strip()}"\
	   # \n prev found:"{str}"')

	def lines_dict(self, is_add_nones: bool = True) -> dict[str:str]:
		result: dict[str:str] = {}

		if self.line_before_match is not None:
			result['prv'] = self.line_before_match.strip()
		elif is_add_nones:
			result['prv'] = '<Unknown>'

		if self.line_quote is not None:
			result['cur'] = self.result['pre'] = self.line_before_match.strip().strip()
		elif is_add_nones:
			result['cur'] = '<Unknown>'

		if self.line_after_match is not None:
			result['nxt'] = self.result['pre'] = self.line_after_match.strip().strip()
		elif is_add_nones:
			result['nxt'] = '<Unknown>'

	def lines_missing_desc(self, lpad: int = 3) -> str:
		prfx = ' ' * lpad
		arr: list[str] = []
		cur_nr_str = self.line_nr_to_str()
		empty = global_consts.EMPTY_EMOJI

		if self.line_before_match is None:
			arr.append(f'{prfx} {cur_nr_str} NO PRE')
		elif self.line_before_match == empty:
			arr.append(f'{prfx} {cur_nr_str} {empty} PRE')

		if self.line_quote is None:
			arr.append(f'{prfx} {cur_nr_str} NO CUR')
		elif self.line_quote == empty:
			arr.append(f'{prfx} {cur_nr_str} {empty} CUR')

		if self.line_after_match is None:
			arr.append(f'{prfx} {cur_nr_str} NO POST')
		elif self.line_after_match == empty:
			arr.append(f'{prfx} {cur_nr_str} {empty} POST')

		if len(arr) == 0:
			return '[✔]'
		
		return '[' + ', '.join(arr) + ']'

	def lines_desc(self, lpad: int = 3) -> str:
		prfx = ' ' * lpad
		arr: list[str] = []
		ln_str: str = global_consts.line_nr_to_str(self.line_nr - 1)
		nr = f'{prfx} {ln_str}'
		if self.line_before_match is not None:
			arr.append(f'{nr}  pre |' + self.line_before_match.strip())
		else:
			arr.append(f'{nr}  pre | <None>')

		nr = f'{prfx} {self.line_nr_to_str()}'
		if self.line_quote is not None:
			arr.append(f'{nr}  cur |' + self.line_quote.strip())
		else:
			arr.append(f'{nr}  cur | <None>')
			
		line_nr_str = global_consts.line_nr_to_str(self.line_nr + 1)
		nr = f'{prfx} {line_nr_str}'
		if self.line_after_match is not None:
			line_str = global_consts.line_nr_to_str(self.line_nr - 1)
			nr = f'{prfx} {line_str}'
			arr.append(f'{nr} post |' + self.line_after_match.strip())
		else:
			arr.append(f'{nr} post | <None>')

		return '  [\n' + ', \n'.join(arr) + '\n]'

		if len(list) == 0:
			print(f'> is_in_list: for [{self.filename()}] ln# {self.line_nr} list was EMPTY')
			return False

		log(f'> is_in_list: for [{self.filename()}]] ln# {self.line_nr} checking in {len(list)} items list:')

		for item in list:
			if isinstance(item, Match):
				amatch: Match = item
				equals = (self == amatch)
				if equals:
					log(f'-   is_in_list {self.filename()} ln# {self.line_nr}  YES equals {amatch}')
					return True
				else:
					log(f'-   is_in_list {self.filename()} ln# {self.line_nr} NOT equals {amatch}')

		log('-   is_in_list --- NOT found in list')
		return False

	def __init__(self, filepath: str, encoding: str = None, line_nr: int = None):
		# init requires at least a filepath. Optionals are encoding, line_nr.
		self.filepath = filepath
		self.encoding_used = encoding
		self.line_nr = line_nr

	def __eq__(self, other) -> bool:
		#  Overrides the default implementation
		if isinstance(other, Match):
			is_print = False  # global_args.is_log_matching
			prfx = ' ' * 6

			other_match: Match = other
			# oname = other.filename()
			# print(f' __eq__ [{oname}]')

			# ugly 4 readability & debugging
			result = self.filepath.lower() == other_match.filepath.lower()
			if not result:
				# print(f'{prfx} __eq__ == FAILED filepath: [{self.filepath}] [{other_match.filepath}]')
				return False
			if is_print:
				print(f'{prfx} __eq__ == filepaths equal {self.filepath}')

			result = result and (int(self.line_nr) == int(other_match.line_nr))
			if not result:
				# print(f'{prfx} __eq__   == FAILED line_nr: [{self.line_nr}] [{other_match.line_nr}]')
				return False
			if is_print:
				print(f'{prfx} __eq__ == 	line_nr equal {self.line_nr}')

			result = result and (self.span[0] == other_match.span[0]) and (self.span[1] == other_match.span[1])
			if not result:
				# if self.filepath == other_match.filepath:
				# print(f'{prfx} __eq__ == FAILED SPANS: [{self.span[0]}] [{other_match.span[0]}]')
				return False
			if is_print:
				print(f'{prfx} __eq__ == 	matched_span equal {self.span}')

			result = result and (self.line_quote == other_match.line_quote)
			if not result:
				print(f'{prfx} __eq__ == FAILED line_quote: [{self.line_quote}] [{other_match.line_quote}]')
				return False
			if is_print:
				print(f'{prfx} __eq__ == 	line_quote equal [> "{self.line_quote}" <]')

			result = result and (self.detection_type == other_match.detection_type)
			if not result:
				print(f'{prfx} __eq__ == FAILED detection_type: [{self.detection_type}] [{other_match.detection_type}]')
				return False

			if is_print:
				print(f'{prfx} __eq__ == 	detection_type equal [{self.detection_type}]')

			return result

		# print(f'__eq__ NotImplemented! for {self} {mother}')
		return NotImplemented

	def __ne__(self, other) -> bool:
		# Overrides the default implementation (unnecessary in Python 3)
		is_equals = self.__eq__(other)
		if is_equals is not NotImplemented:
			return not is_equals
		return NotImplemented

	def __hash__(self):
		# Overrides the default implementation
		return hash(tuple(sorted(self.__dict__.items())))

	def __str__(self):
		result: list[str] = ['Match']

		fpath = self.filepath
		if fpath is not None and len(fpath) > 0:
			fname = fpath.split('/')[-1]
			result.append(f'fl: "{fname}"')

		if self.line_nr is not None:
			result.append(f'ln: {self.line_nr}')

		if self.span is not None and len(self.span) == 2 and self.line_quote is not None and len(self.line_quote) > 0:
			astring = self.found_match_str()
			result.append(f'found: "{astring.strip()}"')
		return f'< {" | ".join(result)} >'

	# slice the line_quote param using the span param to produce the detected sub-string that matches semver or 
	def found_match_str(self) -> str:
		if (self.span is None) or \
			(self.filepath is None) or (self.line_quote is None) or (self.span is None):
			return None
		
		# calc substring / slice:
		start = self.span[0]
		end = (self.span[1] + 1)

		# calc result
		result: str = self.line_quote[start:end]  # both are indexes

		# example '1.1.' -> '1.1.2-beta-12345' if found...
		if len(result.split('.')) >= 2 and result.endswith('.'):
			suffix = self.line_quote[end:]
			
			matches = find_regex_matches_in_str(global_consts.SEMVER_REGEXES, self.line_quote, self.filepath or '?',  False, True, 'suffix is whole semver test')
			if len(matches) > 0:
				# is semver!
				key: str = list(matches.keys())[0]
				val: Match = matches[key]				
				start = val.span[0]
				end = val.span[1]
				found_str = self.line_quote[start:end]
				try:
					semver = semver.versionInfo.parse(found_str)
					if semver:
						# we have a semver section in the line:
						self.span = val.span
						self.validate_span()
						return found_str  # return the whole detected semver string.
					
				except Exception as e:  # work on python 3.x
					# print(f'{global_consts.FAIL_EMOJI} semver.VersionInfo.parse failed parsing "{match_str}" as semver. Exception: {type(e)}  {str(e)}\n{traceback.format_exc()}')
					found_str = ''
			else:
				# TODO: determine if we should test for no result and only in those cases test 
				# regex_match: re.Match = re.search(regex, cur_line_stripped, flags)
				matches = find_regex_matches_in_str([r'\b\d+\b'], suffix, '?',  False, True, 'suffix is digits test')
				if len(matches) > 0:
					key: str = list(matches.keys())[0]
					val: Match = matches[key]
					self.span = tuple([start, end])
					self.validate_span()
					result += suffix.rstrip()
					print(f'find_regex_matches_in_str MATCH of digits: line[{self.span[0]}:{self.span[1]}] = "{self.found_match_str()}"')
		return result

	def file_extension_lower(self) -> str:
		exten = self.file_extension() 
		if self.filepath is None or exten is None:
			return ''		
		return exten.lower()
	
	def file_extension(self) -> str:
		if self.filepath is None and len(self.filepath) <= 1:
			return ''
		
		_, file_extension = os.path.splitext(self.filepath)
		file_extension = file_extension.strip().rstrip('.')
		return file_extension  # OR: self.filepath.split('/')[0]
	
	def filename(self) -> str:
		if self.filepath is None or len(self.filepath) == 0:
			return None

		# if filepath is not None:
		return os.path.basename(self.filepath).strip()
		# --- OR: return filepath.split(',')[-1]

	def build_nr_as_hex(self) -> str:
		if self.last_bumped_v is not None:
			# There must be “b” at the beginning of the string indicating that the value is converted to bytes.
			print(b'{last_bumped_v.build}'.hex())

	def description(self):
		return self.__str__()
	
	# returns True if both matches are at the same filepath, line nr and their spans intersect (chars ranges where match was detected inside line_quote)
	def is_intersects(self, other: any) -> bool:
		# guard
		if type(other) != Match:
			return
		
		if self.filepath != other.filepath:
			return False
		
		if self.line_nr != other.line_nr:
			return False
		
		if self.span[0] > other.span[0] and self.span[1] >= other.span[1]:
			return True
		
		if self.span[0] < other.span[0] and self.span[1] < other.span[1]:
			return True
		
		return self.is_contains(other)

	def line_nr_to_str(self, fill_w: int = 4) -> str:
		# return a formatted line number:
		if self.line_nr is None:
			return global_consts.EMPTY_EMOJI
		
		if self.line_nr is None:
			return global_consts.EMPTY_EMOJI
		
		return global_consts.line_nr_to_str(self.line_nr)

	# returns True if both matches are at the same filepath, line nr and this matches' span contains the others' span (chars ranges where match was detected inside line_quote)
	def is_contains(self, other: any) -> bool:
		# guard
		if type(other) != Match:
			return
		
		if self.filepath != other.filepath:
			return False
		
		if self.line_nr != other.line_nr:
			return False
		
		# self span contains other span
		if self.span[0] <= other.span[0] and self.span[1] >= other.span[1]:
			return True
		
		return False
	
	def to_version_info(self) -> (semver.VersionInfo | None):
		result: (semver.VersionInfo | None) = None
		match_str = self.found_match_str()
		cleaned_str = match_str.strip(string.punctuation)
		is_print = False
		result = None
		periods_cnt = max(len(cleaned_str.split('.')) - 1, 0)
	
		# try to parse as semver
		# detection_type may be 'semver', 'build_nr', 'build_nr_hex', 'in_str', 'no_caps', 'find_ver_str'
		if periods_cnt > 1:  # and self.detection_type != 'build_nr'
			try:
				result = semver.VersionInfo.parse(cleaned_str)
				if not result:
					result = semver.VersionInfo.parse(cleaned_str)

				if not result:
					result = semver.VersionInfo.parse(self.original_before_any_bump)

				if not result and is_print:
					print(f'{global_consts.FAIL_EMOJI} to_version_info failed parsing in {self.filename()} | ln# {self.line_nr_to_str()} | "{cleaned_str}" as semver.')

			except Exception as e:  # work on python 3.x
				print(f'{global_consts.FAIL_EMOJI} semver.VersipeonInfo.parse failed parsing in {self.filename()} | ln# {self.line_nr_to_str()} | "{cleaned_str}" as semver. Exception: "{e}"')
				result = None
				
		# try to parse as number
		if not result:
			try:
				# try to parse as build nr
				has_periods = len(cleaned_str.split('.')) > 1
				# has_dec_periods = len(cleaned_str.split('.')) == 2
				is_float = match_str.endswith('.0') or match_str.endswith('.00')
	   
				abuild_nr: (int | None) = None
				if is_float:  # is a round float number. 
					abuild_nr = int(float(cleaned_str))
				elif cleaned_str.lower().startswith('0x') and not has_periods:
					abuild_nr = int(cleaned_str, 16)  # from hex to int or str
				elif not has_periods:
					abuild_nr = int(cleaned_str)
				
				if cleaned_str == '0':  # special case
					result = None  # used to be: TODO: check what to do. result = semver.VersionInfo(0, 0, 0, None, 0)
				elif abuild_nr and abuild_nr >= 0:
					result = semver.VersionInfo(0, 0, 0, None, abuild_nr)

				if not result and is_print:
					if not is_float and has_periods and round(float(cleaned_str)) != float(cleaned_str):
						print(f'{global_consts.FAIL_EMOJI} to_version_info failed parsing in {self.filename()} | ln# {self.line_nr_to_str()} | "{cleaned_str}" as build nr. (build nr should NOT contain non-zero decimals)')
					else:
						print(f'{global_consts.FAIL_EMOJI} to_version_info failed parsing in {self.filename()} | ln# {self.line_nr_to_str()} | "{cleaned_str}" as build nr.')

			except Exception as e:  # work on python 3.x
				print(f'{global_consts.FAIL_EMOJI} build nr failed parsing in {self.filename()} | ln# {self.line_nr_to_str()} | "{cleaned_str}" as build nr. Exception: "{e}"')
				result = None

		return result


class GlobalVars:
	regexes_for_filepath: dict[str: list[str]] = {}
	latest_bumped_match: (Match | None) = None


# MARK: global vars
global_args: GlobalArgs = GlobalArgs()  # cmd line arguments
global_vars: GlobalVars = GlobalVars()  # variables, expected to be replaced or mutated
global_consts: GlobalConstants = GlobalConstants()  # constants, not expected to change ever.
global_min_path_depth: int = 0
global_wasAborted: str = ''

# MARK: command line arguments:


def setup_parser() -> None:

	print('⤷ setup_parser')
	# Command line params / args:

	parser = argparse.ArgumentParser(prog='Bump', description='Bumps build number or version by finding files with lines where the apps\' version appears using regexes, and bumping the version. Saves a valid version in all the needed locations. User may explicitly specify the root dir for the search (-p / -path arguments) or we are assuming the search should start one folder above the "current" run folder',
									epilog='Thanks')

	parser.add_argument('-s', '-semver', '-semverpart', choices=['major', 'minor', 'patch', 'build'], default='build', help='Specify which part of the version string you want to bump: [major], [minor] or [build] number. Bumping the major version number will also zero the minor version and build count. Bumping the minor version will zero the build counter. Bumping the build number will increment it by one.')

	parser.add_argument('-e', '-exactver', required=False, default='', help='Specify an exact smever-complient string to set (and not "bump") the version in all the lines a version number or build nt is needed.')

	parser.add_argument('-f', '-file', required=False, default='', help='Specify a single source file where the version / build number string is stored (and needs to be bumped), and use that version to bump and apply to all other locations where a valid app version number appears.')

	parser.add_argument('-r', '-regex', required=False, default='', help='Specify a specific sourcefile regex where the verion / build number reside. The regex should capture one group only. NOTE: This is used ONLY when the -f/-file argument is also specified.')

	parser.add_argument('-g', '-git', '-git_tag', action='store_true', default=True, help='Specify if the script should locate the nearest git repository (up to 4 folders back) and commit the applied (bumped) semver version as a tag to the current branch in the git.')

	parser.add_argument('-p', '-path', required=False, default='../', help='Specify a specific root path to search for files - the search will be recursive downtree from this path and doewn. default is ../, i.e one folder above the "current".')

	parser.add_argument('-l', '-log', required=False, default=False, help='The script should log in a verbose manner.')

	# actual magic of parsing the command line arguments:
	parser_args = parser.parse_args()

	# Args dictionary to be returned:
	global_args.semverpart_to_bump = parser_args.s 	# choices=['major', 'minor', 'patch', 'pre', 'build']
	arg_e = parser_args.e.strip()
	if len(arg_e) > 2:
		# exact ver is used as-is-provided (and not to "bump")
		global_args.exact_version = semver.VersionInfo.parse(parser_args.e)

	global_args.sourcefile = parser_args.f.strip()  # source file where the version / build number string is stored

	arg_regex = parser_args.r.strip()
	if len(global_args.sourcefile) > 2 and len(arg_regex) > 2:
		# use the specified regex instead of the default regexes for the specified filename only:
		global_args.regexes_by_filepath[global_args.sourcefile] = [arg_regex]

	global_args.root_path = parser_args.p
	global_args.is_update_git_tag = parser_args.g


def setup_regexes_by_filename():
	global global_args
	# Uses section '§' unicode:
	semvers = global_consts.SEMVER_REGEXES
	semver = semvers[-1]  # last regex for cathing a semver
	print('semver: {semver} semvers: {semvers}')
	build_nrs = global_consts.BUILD_NR_REGEXES
	global_vars.regexes_for_filepath = {
		'*^': semvers + build_nrs,
		'readme.md^': [f'^.{1,6}version:.{1,6}(<?P:semver>' + semver + ')',
		f'^.{1,6}build nr:.{1,6}(<?P:build_nr>' + '|'.join(build_nrs) + ')'],
	}

# MARK: Util functions

def log_if(condition: bool, str: str, verbose: bool = True):
	if condition:
		print(str)


def log(str: str, verbose: bool = True):
	if verbose and not global_args.is_log_verbose:
		return
	print(str)


def substring_range(orig_str, expected_substring) -> (tuple[int] | None):
	for item in re.finditer(re.escape(expected_substring), orig_str):
		amatch: re.Match = item
		if amatch.span() is not None:
			return amatch.span()

	return None


def lists_intersection(list1: list[any], list2: list[any]):
	return list(set(list1).intersection(list2))


def unique(arr: list[any]):
	return list(set(arr))

	
def compare_in_list(arr: list[str], compare: Callable[[str, str], bool]) -> list[str]:
	# will accept only the first element of the two into a list of elements from the given array, where the lambda accepts two items in the list to compare and returns a bool.
	# compares all elements in the array one with another (once).
	if not compare or not arr or len(arr) < 2:
		return arr
	
	filtered_lst = []
	larr = len(arr)
	for i in range(larr):
		for j in range(i + 1, larr):
			if i != j and arr[i] not in filtered_lst and compare(arr[i], arr[j]):
				filtered_lst.append(arr[i])
				break
	return filtered_lst


def string_full_or_empty(string: (str | None))->(str):
	string = string.strip()
	if string is None: return global_consts.EMPTY_EMOJI
	if len(string) < global_consts.MIN_LINE_LEN: return global_consts.EMPTY_EMOJI
	return global_consts.CHECK_EMOJI

def string_len_or_none(list1: (list[any] | None))->(int | None):
	if list1 is None: return None
	return len(list1)

def capture_groups_into_match(regex_match: re.Match, match: Match, regex_nr: int, regex: str, 
			      orig_line: str, is_no_name_groups: bool = False) -> Match:
	
	# This function is part of the "matching" process, so global_args.is_log_matching needs to be on:
	is_print = (match.line_nr is not None or match.filepath is not None) and True  # (global_args.is_log_verbose and global_args.is_log_matching)

	# prep
	if is_no_name_groups:
		is_print = False
	line_nr_str = match.line_nr_to_str()
	prfx = ('  ' * 4)
	captured_groups: dict[str, any] = regex_match.groupdict()

	matched_str = regex_match.group(0)  # first match is the whole range of found string, containing within it the matching groups:
	matched_span = regex_match.span(0)  # span=(51, 444)

	# guard
	if is_no_name_groups:
		if is_print:
			print(f'{prfx} capture_groups_into_match: is_no_name_groups: True {match}')
		grps = list(regex_match.groups(re.Match))
		if len(grps) == 0:
			grps = [regex_match]

		key_nr = 0
		for grp in grps:
			# dict[str, any]
			key = 'no_caps|{key_nr}|' + regex + f'|{regex_nr}'
			captured_groups[key] = grp
			if is_print:
				print(f'{prfx} >> creating capture_groups_into_match: is_no_name_groups: key: {key} : grp: {grp}')
			key_nr += 1

	elif captured_groups is None or len(captured_groups) == 0:
		print(f'{prfx} {global_consts.FAIL_EMOJI} capture_groups_into_match failed guard: empty captured_groups')
		return None

	if match.filepath is None or len(match.filepath) == 0:
		print(f'{prfx} {global_consts.FAIL_EMOJI} capture_groups_into_match failed guard: empty match.filepath')
		return None

	if regex_nr < 0 or regex_nr > 20:
		print(f'{prfx} {global_consts.FAIL_EMOJI} failed guard: we test up to max 20 regexes per line/file. regex_nr is: {regex_nr}')
		return None
		
	if regex is None or len(regex) == 0:
		print(f'{prfx} {global_consts.FAIL_EMOJI} failed guard: actual regex string is empty')
		return None

	if matched_span is None or len(matched_span) != 2:
		print(f'{prfx} {global_consts.FAIL_EMOJI} failed guard: matched_span is empty or no start or end')
		return None

	# Actual code:
	line: str = match.line_quote
	match.span = matched_span  # two ints list[int]
	match.validate_span()
	add: int = 0

	start: int = matched_span[0]
	end: int = matched_span[1] + add + 1

	# sliced = line[start:end]
	o_sliced: str = orig_line[start:end]
	
	# orig_line
	capt_groups_keys = list(captured_groups.keys())
	grp_0_name = '<Unknown>'
	if len(capt_groups_keys) > 0:
		grp_0_name = capt_groups_keys[0]
	found_semver: semver.VersionInfo = None

	filename = match.filename()

	# fpath = match.filepath
	# if fpath is not None and len(fpath) > 0:
	# 	filename = fpath.split('/')[-1]
	if is_print:
		print(f'{prfx}⤷ capture_groups_into_match | {filename} | {line_nr_str} | \
regex #{regex_nr} | Matched: "{matched_str}" span: {matched_span} | \
{len(captured_groups)} capt.grps')
	detection_type: str = 'semver'
	found_semver = None

	try:
		if grp_0_name.startswith('semver') is True:

			found_semver = semver.VersionInfo.parse(regex_match.group(0))
			if found_semver is not None:
				# validate:
				required = ["semver_major", "semver_minor", "semver_patch"]
				intersected = lists_intersection(required, capt_groups_keys)
				len_intersected = len(intersected)
				if len_intersected >= len(required):
					detection_type = 'semver'
					if is_print:
						print(f'{prfx}   DETECTED semver "{found_semver}"')

		elif grp_0_name.startswith('build_nr_hex'):
			hexstr = regex_match.group(0).lower()
			if not hexstr.startswith('0x') and not hexstr.startswith('0X'):
				if is_print:
					print(f'capture_groups_into_match build_nr_hex has bad HEX STRING: {hexstr} (should begin with 0x or 0X)')
				return None

			# Without the 0x prefix, you need to specify the base explicitly, otherwise there's no way to tell:
			num: int = int(hexstr, 16)  # from hex to int or str
			if num is not None and num == 0 and num < global_consts.MAX_SEMVER_LEN:
				found_semver = semver.VersionInfo.parse(f'0.0.0-unknown+{hexstr}')  # we know only the build nr
				detection_type = 'build_nr_hex'
				if is_print:
					print(f'{prfx}   ⤷ DETECTED build_nr_hex: "{num}" -> {found_semver.build} ln: "{line.strip()}"')

		elif grp_0_name.startswith('build_nr_int'):
			number_str = regex_match.group(grp_0_name)
			if '.' in number_str:
				num = int(round(float(number_str)))
				if not (number_str.endswith('.0') or number_str.endswith('.00')):
					if is_print:
						print(f'{prfx}   {global_consts.FAIL_EMOJI} DETECTED "build_nr" BUT orig num string was a float: "{number_str}]" in\n{prfx}     {orig_line.strip()}')
					num = None
					found_semver = None
			else:
				num = int(number_str)

			if num is not None and num >= global_consts.MIN_SEMVER_BUILD_NR and num < global_consts.MAX_SEMVER_BUILD_NR:
				found_semver = semver.VersionInfo.parse(f'0.0.0-unknown+{num}')  # we know only the build nr
				detection_type = 'build_nr'
				if is_print:
					print(f'{prfx}   ⤷ DETECTED build_nr_hex: "{num}" -> {found_semver.build} ln: "{line.strip()}"')

		elif grp_0_name.startswith('no_caps'):
			detection_type = 'no_caps'  # 'find_ver_str' ? 
			if is_print:
				print(f'{prfx}   ⤷ DETECTED detection_type: {detection_type} REGEX: [{regex}] ln: "{line.strip()}"')
		else:
			abort(f'{prfx}    {global_consts.FAIL_EMOJI} Unhandled grpup name: {grp_0_name}')
			
	except Exception as e:  # work on python 3.x
		# exception KeyError - Raised when a mapping (dictionary) key is not found in the set of existing keys.
		print(f'capture_groups_into_match EXCEPTION:\n  line #{line_nr_str}: {orig_line.strip()}\n  grp name: "{grp_0_name}"\n  regex: "{regex}"\n  exception: {type(e)}  {str(e)}\n{traceback.format_exc()}\n\n')

	match.detection_type = detection_type
	if match.detection_type != detection_type or match.detection_type == 'unknown':
		print(f'capture_groups_into_match WARNING: Fix this: {detection_type} => {match.detection_type} {global_consts.FAIL_EMOJI}')

	if found_semver is not None:
		match.last_bumped_v = semver
		match.line_quote = orig_line
		match.regex_used = regex
		if match.span is None:
			abort(f'FAILED!!! match.span is None: {match} matched_span: {matched_span} START {start} end: {end} o_sliced: {o_sliced}')
			# matched_span = ## TODO Fallback find span in oring line if possible

		if match.original_before_any_bump is None or \
			len(match.original_before_any_bump) == 0:
			match.original_before_any_bump = regex_match.group(0)

	if match is not None and is_print:
		# for function capture_groups_into_match:
		if match.filepath == '?':
			print('ha!')
		print(f'{prfx}   | returning: {match.description()}')

	return match

def compare_overlapping_matches(match0: Match, match1: Match) -> bool:
	# return True to keep match0 a in filter, False to filter out match0:
	prfx = ' ' * 5
	is_comp_length: bool = False
	if (match0 == match1):
		is_comp_length = True
	elif match0.is_contains(match1):
		print(f'{prfx}  compare_overlapping_matches - {global_consts.CHECK_EMOJI} removing contained match1:')
		return True # remove match1
	elif match1.is_contains(match0):
		print(f'{prfx}   compare_overlapping_matches - {global_consts.CHECK_EMOJI} removing contained match0:')
		return False # remove match0
	elif match1.is_intersects(match0):
		is_comp_length = True

	if is_comp_length:
		str0 = match0.found_match_str()
		str1 = match1.found_match_str()
		if len(str1) > len(str0):
			return False  # remove match0
		if len(str1) == len(str0):
			# in case of equality __eq__ between matches
			return True
		else:
			if len(match0.original_before_any_bump) > len(match1.original_before_any_bump):
				return True  # remove match1
			else:
				return False  # remove match0
		print(f'{prfx}   compare_overlapping_matches - equality / intersection found. "{str0}"')

def filter_overlapping_matches(matches: list[Match]) -> list[Match]:
	# guard
	if len(matches) < 2:
		return matches
	
	result: list[Match] = []
	matches_by_keys: dict[str:[Match]] = {}

	# fill matches_by_keys 
	for match in matches:
		fle = match.filename().replace(' ', '_').lower()  # TODO: Change this to match.filepath in production
		key = f'{fle}_{match.line_nr}'

		# get array and filter:
		arr: list[match] = []
		if key in matches_by_keys.keys():
			arr = matches_by_keys[key] or []
		arr.append(match)

		# return array into the dict
		#  list indices must be integers or slices, not str?
		matches_by_keys[key] = arr

	prfx = ' ' * 7
	print(f'{prfx} filter_overlapping_matches {len(matches_by_keys)} set of possible intersect matches by keys.')

	# iterate matches_by_keys
	for key in matches_by_keys:
		arr: list[Match] = matches_by_keys[key]
		if len(arr) > 1:
			keep_in: list[Match] = []
			to_keep = compare_in_list(arr, compare_overlapping_matches)
			for i in range(len(arr)):
				for j in range(i + 1, len(arr)):
					if not arr[i] in keep_in and compare_overlapping_matches(arr[i], arr[j]):
						keep_in.append(arr[i])

			# remove all items filtered out: contained (TODO: Determive if also intersecting spans (i.e [1,7] and [6,9]) should be filtered out and how to determine which one goes)
			# if len(to_remove) > 0:
			# 	for val in to_remove:
			# 		arr.remove(val)
			print(f'to keep: \n{to_keep}\n=====\n{keep_in}')
			matches_by_keys[key] = unique(arr)
	
	# return result (flattened)	
	for lst in matches_by_keys.values():
		result.extend(lst)
	return result


def find_regex_matches_in_str(regexes: list[re.Pattern], 
	item: str,
	filepath: str,
	is_case_sensitive: bool = False, 
	is_stop_on_first: bool = False,
	context: str = 'Unknown') -> dict[str:Match]:
	
	# prep:
	match = Match(None, None, None)
	match.line_quote = item
	match.filepath = filepath
	match.detection_type = 'in_str'
	res = find_regex_matches_in_match_instance(regexes, match, is_case_sensitive, is_stop_on_first, context)
	return res

def find_regex_matches_in_match_instance(regexes: list[re.Pattern], 
	match: Match, 
	is_case_sensitive: bool = False, 
	is_stop_on_first: bool = False,
	context: str = 'Unknown',
	is_print: bool = True) -> dict[str:Match]:

	# prep:
	result: dict[str:Match] = {}
	filepath = match.filepath
	filename = match.filename()
	line_nr = match.line_nr or 0
	line_nr_str = match.line_nr_to_str()

	# frmimi
	prfx = (' ' * 5) + 'frmimi |'

	# # TEMP
	# if context == 'find_version_matches_in_file':
	# 	print('ctX: ' + context)

	# depends on prev prep:
	cur_line = match.line_quote or ''
	cur_line_stripped: str = str(match.line_quote or '').strip()

	cur_line_len = len(cur_line)
	if not cur_line or cur_line_len == 0:
		print(f'{prfx} {global_consts.FAIL_EMOJI} Failed match.line_quote is empty or None.')
		return result
	
	if len(regexes) == 0:  # guard
		print(f'{prfx} {global_consts.FAIL_EMOJI} Failed regexes list is empty')
		return result

	# Should log the regex parsing and capturing process:
	is_print_matching = is_print or ((filepath is not None) and global_args.is_log_matching)
	if match.detection_type == 'in_str':
		is_print_matching = False

	# is_should_line_len_check
	# may be 'semver', 'build_nr', 'build_nr_hex', 'in_str', 'no_caps', 'find_ver_str'
	is_should_line_len_check = len(lists_intersection([match.detection_type],  ['semver', 'build_nr', 'build_nr_hex', 'find_ver_str']))

	if is_should_line_len_check:
		# basic guard
		if cur_line_len < 2 or cur_line_len > 8196 or len(regexes) == 0:
			print(f'{prfx} {global_consts.FAIL_EMOJI} failed "{filename}" line_len A: {cur_line_len}')
			return result

		# optimization:
		if (filepath is not None and filepath.strip() != cur_line_stripped):
			# extended guard - checks line length only if we are checking a line in a file (expecting filepath is not None)
			if cur_line_len < global_consts.MIN_LINE_LEN or cur_line_len > global_consts.MAX_LINE_LEN:
				# in lines inside read files: line len should not be tested if too long or too short.
				# print(f'{prfx} {global_consts.FAIL_EMOJI} failed "{filename}" line_len B | ({line_len}) is actual len')
				return result

	# returns dictionary of key: full string of the match (grp 0) and val: Match object
	failed_count = 0
	regex_nr = 0
	prfx = prfx + ' '
	flags = 0
	if not is_case_sensitive:
		flags = re.IGNORECASE
	stripped: str = ''

	# iterate all the regexes that aim to detect a version or build nr in the line:
	for regex in regexes:
		try:
			# is_case_sensitive
			regex_match: re.Match = re.search(regex, match.line_quote, flags)

			if regex_match is not None:

				# Documentation for M`atch.groupdict(default=None)
				# Return a dictionary containing all the named subgroups of the match, keyed by the subgroup name. The default argument is used for groups that did not participate in the match; it defaults to None. For example:
				captured_groups = regex_match.groupdict()

				prfx2 = prfx + '   '
				if len(captured_groups) > 0:
					# We have captured some named capture groups

					match.line_nr = line_nr
					if is_print_matching: 
						print(f'{prfx}  regex #{regex_nr} | found regex match/es | caught {len(captured_groups)} captured groups')

					match = capture_groups_into_match(regex_match, match, regex_nr, regex, cur_line)

					if match is not None and match.line_quote is not None:
						start = match.span[0]
						end = match.span[1]
						key = match.line_quote[start:end]
						result[key] = match
					else:
						print(f'{prfx}   {global_consts.FAIL_EMOJI} match or line_quogte for {filename} | ln# {line_nr_str} | {cur_line.strip()} is None')
				else:
					# We have NOT captured any named capture groups, so we need to search for unnamed groups.
					
					grps = list(regex_match.groups(re.Match))
					if len(grps) == 0:
						grps = [regex_match]
					
					# We do have a match using the regex, but the regex did not contain / we did not catch any "capture group":
					# if is_print_matching:
					# print(f'{prfx}⤷ find_regex_matches_in_match_instance found regex match {filename} | ln# {line_nr_str} | "{stripped}"')
					prfx3 = f'{prfx2}  found  "{filename}" | ln# {line_nr_str} | "{stripped}"'
					if is_print_matching and filename:
						if len(grps) == 1:
							print(f'{prfx}   found regex match/es | regex #{regex_nr} | caught an unnamed matching group | found match: "{regex_match.group(0)}"')
						else:
							print(f'{prfx}   found regex match/es | regex #{regex_nr} | caught {len(grps)} unnamed matching groups')

					idx = 0
					for grp in grps:
						match = capture_groups_into_match(grp, match, regex_nr, 
														regex, 
														cur_line, 
														True)  # True is "is_no_name_groups" flag to complete the function even when no "named group" were found.

						# print(f'{prfx2} matched group: | {grp} {grp.group()} match: {match}')
						key = 'no_caps|' + regex + f'|{idx}'
						result[key] = match
						idx += 1
						if is_stop_on_first and len(result) > 0:
							return result
			#else:
				# case where regex_match is NONE
				#if is_print_matching:
					#print(f'{prfx} NO MATCH for regex #{regex_nr}\n             {regex}')

		except Exception as e:  # work on python 3.x
			# exception KeyError - Raised when a mapping (dictionary) key is not found in the set of existing keys.
			print(f'{prfx}  EXCEPTION find_regex_matches_in_match_instance EXCEPTION: {type(e)}\n\n{str(e)} {traceback.format_exc()}\n\n')
			failed_count += 1

		regex_nr += 1
	
	# filter result: dict[str:Match]
	filtered_matches: list[str] = []
	if len(result) > 1:
		# cannot have overlappings where there is lestt than 2 items...
		filtered_matches = filter_overlapping_matches(list(result.values()))
		result.clear()
		for amatch in filtered_matches:
			key = amatch.original_before_any_bump
			result[key] = amatch

	# log results:
	if len(result) > 0 and is_print_matching:
		print(f'{prfx}  | result: {len(result)} pairs:')

		result_idx: int = 0
		for key in result.keys():
			amatch: Match = result[key]
			if amatch in result:  # we exclude all matches that were filtered out:
				result_idx_str = f'{result_idx + 1}'.rjust(2)  
				fkey = key.strip()
				match_desc: str = amatch.description()
				print(f'{prfx}  |  result nr: {result_idx_str} | match key: "{fkey}" : {match_desc}')
				result_idx += 1

	return result


def path_prefix_space(path: str, add: int = 0):
	return '  ' * (max(len(path.split('/')) - 1 + add, 0))


# MARK: Find files and paths
def last_path_component(path: str) -> str:
	return path.split('/')[-1]


def clean_folder_name(path: str, strip_initial_folders: int = 0) -> str:
	if not path or len(path) == 0:
		return None

	result = os.path.abspath(path)  # also try: os.path.dirname(path)
	_, file_extension = os.path.splitext(path)  
	file_extension = file_extension.lower()

	# remove prefixes '../'
	inf_protection = 20
	while result.startswith('../') and len(result) > 3 and inf_protection > 0:
		result = result[3:]
		inf_protection = inf_protection - 1

	# remove prefixing folders if perscribled:
	if strip_initial_folders > 0:
		pre_result = ''
		inf_protection = max(strip_initial_folders, 17)
		while ((len(pre_result) <= 1) and (inf_protection > 0)) or ('/' not in pre_result):
			parts = result.split('/')[strip_initial_folders:]
			pre_result = '/'.join(parts)
			strip_initial_folders = max(strip_initial_folders - 1, 1)
			inf_protection = inf_protection - 1
		result = pre_result

	# add final slash
	if (not result.endswith('/')) and (file_extension is None) and len(result) > 3 and (result != '../'):
		path = path + '/'

	return result


def convert_to_regex(array: list[str], file_extension_prep: bool = False) -> str:
	if file_extension_prep:
		array = ['\.{0,1}' + itm.lower() + '$' for itm in array]
	result = r'|'.join(array)
	return result


def find_possible_filepaths(root_folder: str, additional_paths: list[str] = [], depth: int = 0) -> set:
	MAX_RECURSION_DEPTH = 16
	if depth > MAX_RECURSION_DEPTH:
		# guard exit recursion if too deep
		return []

	if depth > 0 and depth > global_consts.MAX_FOLDER_DEPTH:
		log(f'depth {depth} > MAX_FOLDER_DEPTH {global_consts.MAX_FOLDER_DEPTH}', True)
		return []

	prfx = ('  ' * depth) or ''
	# result : list[str] = []
	result = set()

	# exlude folder names using regexes:
	excludes_dirs = convert_to_regex(global_consts.IGNORED_FOLDER_REGEXES)

	if depth == 0:
		print(f'⤷ find_possible_filepaths root: [{root_folder}] REGEXES: {len(global_consts.IGNORED_FILENAME_REGEXES)} excluding filenames, {len(global_consts.IGNORED_FILE_EXTENSIONS)} excluding extensions')  # [{depth}]

	# walk the root folder:
	folders = set()

	if root_folder == '../':
		root_folder = os.path.abspath('../') + '/' 

	for root, dirs, files in os.walk(root_folder):

		# exclude subdirs in the root folder
		if len(excludes_dirs) > 0:
			dirs[:] = [dir for dir in dirs if not re.search(excludes_dirs, dir)]

		# make the dir names full path dirs...:
		dirs[:] = [os.path.join(root, dir) for dir in dirs]

		# exclude/include files in the root_dir
		files = [os.path.join(root, fle) for fle in files]
		logged_files = set()

		# filter files:
		for file in files:
			filename, file_extension = os.path.splitext(file)
			is_pass: bool = True
			extension: str = file_extension.lstrip('.')
			filename: str = os.path.basename(filename).strip()
			folder: str = os.path.abspath(file).rsplit(filename, maxsplit=1)[0].rstrip(extension).rstrip(filename + '.')
			if len(extension) > 0:
				filename = filename.rstrip('.') + '.' + extension.rstrip('.')
			filepath = folder + filename

			if is_pass and len(folder) > 0 and (folder not in folders):
				# print(f'folder {folder}')
				res = find_regex_matches_in_str(global_consts.IGNORED_FOLDER_REGEXES, folder, filepath, False, True, "xclude by folder")
				if len(res) > 0:
					key = 'EXCLUDED folder: ' + folder
					if key not in logged_files:
						logged_files.add(key)
						log(f'{prfx} | EXCLUDED folder: {filename} ({extension})', True)
					is_pass = False
				else:
					folders.add(folder)

			# filter for this extension
			if is_pass and len(extension) > 0:
				res = find_regex_matches_in_str(global_consts.IGNORED_FILE_EXTENSIONS, extension, filepath, False, True, "xclude by extension")
				if len(res) > 0:
					key = 'EXCLUDED extension: ' + filename + extension
					if key not in logged_files:
						logged_files.add(key)
						log(f'{prfx} | EXCLUDED file: {filename} ({extension} extension)', True)
					is_pass = False

			# # filter for this filename:
			if is_pass and len(filename) > 0:
				res = find_regex_matches_in_str(global_consts.IGNORED_FILENAME_REGEXES, filename, filepath, False, True, "xclude by filename")
				if len(res) > 0:
					key = 'EXCLUDED filename: ' + filename + extension
					if key not in logged_files:
						logged_files.add(key)
						log(f'{prfx} | EXCLUDED filename: {filename} (filename)', True)
					is_pass = False

			# was successfully filtered
			if is_pass:
				result.add(file)
				folders.add(folder)

			if len(global_wasAborted) > 0:
				break  # exit loop

		# additional folders using the os.walk folders
		for dir in dirs:
			dir = clean_folder_name(os.path.abspath(dir))
			if dir not in folders:
				filepath = dir
				res = find_regex_matches_in_str(global_consts.IGNORED_FOLDER_REGEXES, dir, filepath, False, True, "xclude dirs")
				if len(res) == 0:
					folders.add(dir)

	# filter subfolders:
	if depth < MAX_RECURSION_DEPTH:
		for folder in folders:
			# note! recursive!
			cdir = clean_folder_name(folder)
			# print(f'{prfx} |find_possible_filepaths sub folder: >>==>> {cdir}')
			result = result.union(find_possible_filepaths(cdir, [], depth + 1))

	if depth == 0:
		if len(additional_paths) > 0:
			log(f'{prfx} ::: {len(additional_paths)} additional paths :::', True)
			for dir in additional_paths:
				# print(f'{prfx} | find_possible_filepaths additional path: >>==>> {cdir}')
				cdir = clean_folder_name(dir)
				result = result.union(find_possible_filepaths(cdir, depth + 1))
		else:
			log(f'{prfx} | find_possible_filepaths (no additional paths)', True)

		# after all is done in the 0 depth of the recursion:
		print(f'{prfx} * find_possible_filepaths found {len(result)} files.')

		# log(f'\r{prfx} | file: {filename}', False)

	return result


# MARK: Iterate found files and matches
def get_regexes_for_filepath(filepath: str) -> list[str]:
	result: list[re.Pattern] = global_vars.regexes_for_filepath.get(filepath) or global_vars.regexes_for_filepath.get('*') or []
	if result is None or len(result) == 0:
		# fallback?
		result.extend(global_consts.SEMVER_REGEXES)
		result.extend(global_consts.BUILD_NR_REGEXES)
	return result


def detect_file_encoding_by_lines(filepath: str, filesize: int = 0, read_lines: int = 20) -> str:
	prfx = ' ' * 4
	is_print = False

	if is_print: 
		print(f'{prfx}⤷ detect_file_encoding_by_lines {filepath}')
	prfx = prfx + (' ' * 2)

	# vars and setup
	if filesize == 0:
		filesize = os.stat(filepath).st_size
	read_lines = int(max(read_lines, 128))

	# detemine file encoding:
	encodings: dict[str:int] = {}
	failures: int = 0
	try:
		with open(filepath, "rb") as f:
			bytes = f.readline(read_lines)
			result: CharsetMatch = detect(bytes)
			if result is None or result['encoding'] is None or result['confidence'] < 0.51:
				if is_print: 
					print(f'{prfx} {global_consts.FAIL_EMOJI} FAILED for None result or low confidence')
			else:
				confidence = result["confidence"]
				encoding = result["encoding"]
				if confidence > 0.5 and encoding is not None:
					cur_count = encodings.get(encoding) or 0
					cur_count += 1
					encodings[encoding] = cur_count

	except Exception as e:
		print(f'{prfx} FAILED for file: {filepath} exception: {e}')
		failures += 1
	finally:
		f.close()

	# finally
	if len(encodings) == 0:
		return None
	else:
		sorted_encodings = sorted(encodings.items(), key=lambda x: int(x[1]))
		if is_print:
			if len(sorted_encodings) > 1:
				print(f'{prfx} found best: {sorted_encodings[0]} out of: [{sorted_encodings}]')
			else:
				print(f'{prfx} found: {sorted_encodings[0]} for: {read_lines} read lines in {filepath}')				
		return sorted_encodings[0][0]

def detect_file_encoding(filepath: str, filesize: int, read_bytes: int = 8192) -> str:
	prfx = ' ' * 2
	is_print = False
	if is_print: 
		print(f'{prfx}⤷ detect_file_encoding {filepath}')
	prfx = prfx + (' ' * 2)

	# vars and setup
	if filesize == 0:
		filesize = os.stat(filepath).st_size

	read_bytes = int(min(max(read_bytes, 128), filesize))
	if filesize < 2048 and read_bytes == filesize:
		read_bytes = int(filesize / 2)
	elif filesize >= 8196:
		read_bytes = int(filesize / 8)

	# detemine file encoding:
	encodings: dict[str:int] = {}
	failures: int = 0
	try:
		with open(filepath, "rb") as f:
			bytes = f.read(read_bytes)
			result: CharsetMatch = detect(bytes)
			if result is None or result['encoding'] is None or result['confidence'] < 0.51:
				if is_print: 
					print(f'{prfx} detect_file_encoding FAILED for None result or low confidence')
				failures += 1
			else:
				confidence = result["confidence"]
				encoding = result["encoding"]
				if confidence > 0.5 and encoding is not None:
					cur_count = encodings.get(encoding) or 0
					cur_count += 1
					encodings[encoding] = cur_count
	finally:
		f.close()

	# finally
	enc_count = len(encodings)
	first_key = ''  # unknown
	if enc_count == 1:
		first_key = list(encodings.keys())[0]

	if (enc_count == 1 and first_key == 'ascii') or (failures > 0) or (enc_count == 0):
		if is_print: 
			print(f'{prfx} will retry with lines read:')
		enco = detect_file_encoding_by_lines(filepath, filesize)
		if enco is not None:
			encodings = {}
		elif enc_count == 0:
			return None
		elif first_key == 'ascii':
			return 'ascii'
		else:
			return None

	if enc_count == 0:
		return None
	elif enc_count == 1:
		return first_key
	else:
		sorted_encodings = sorted(encodings.items(), key=lambda x: int(x[1]))
		if len(sorted_encodings) == 0 and len(encodings) > 0:
			if is_print: 
				print('{prfx} detect_file_encoding failed sorting encdodings!')
		if len(sorted_encodings) > 1:
			first_key = list(sorted_encodings.values())[0]
			if is_print: 
				print(f'{prfx} detect_file_encoding found best: {first_key} out of: [{sorted_encodings}]')
		else:
			if is_print: 
				print(f'{prfx} detect_file_encoding found: {first_key} for chunk sze: {read_bytes}')

		return first_key


def is_valid_line_for_regexes(line: str) -> bool:
	if line is None: 
		return False

	# input line may not be stripped of whitespaces at edges:
	stripped = line.strip()
	if len(stripped) < global_consts.MIN_LINE_LEN: 
		return False
	if len(stripped) > global_consts.MAX_LINE_LEN: 
		return False
	
	# clear lines that contain ONLY a comment mark or other small items..
	hard_coded_lines = ['//', '///', '#', '##', '}', '{']
	if len(list(set(hard_coded_lines) & set([stripped]))) > 0: 
		return False
	
	return True


def is_valid_line_for_match_line(line: str, match: Match, regexes: list[re.Pattern],
				require: (str | None) = None, is_case_sensitive: bool = False) -> bool: 
	prfx = (5 * ' ') + 'ivlfml |   '

	# param regexes is meant to be the regexes that dicriminate against a found 
	# match on the line_quote. 
	# That is, we have matched naively, and now we want to eliminate from the results 
	# those which match the input regexes for this function.

	# the require param means we require the regexes to be tested intersect or not 

	# guard
	if line is None or match is None or match.filepath is None is None or regexes is None: 
		print(f'{prfx} is_valid_line_for_match_line: ❌ FAILED some input parameter is None!')
		return False
	
	if len(regexes) == 0 or len(line) == 0:
		print(f'{prfx} is_valid_line_for_match_line: ❌ FAILED empty regexes ({len(regexes)}) or empty line ({len(line)}) !')
		return False
	
	flags = 0
	if not is_case_sensitive:
		flags = re.IGNORECASE
	
	is_print: bool = False  # global_args.is_log_verbose or global_args.is_log_matching
	is_print_fails = True  # is_print 
	line_nr_str = match.line_nr_to_str()
	# TODO: delete or use? regex_prefix = regex[:20] + '...'
	line_stripped = match.line_quote.strip()
	log_if(is_print, f'{prfx} is_valid_line_for_match_line: "{match.filename()}]" | ln# {line_nr_str} | span: {match.span} | vs."{require}" x {len(regexes)} regexes')
	regex_idx = 0
	
	for regex in regexes:
		regex_match = re.match(regex, line, flags)
		# TODO: delete or use? regex_prefix = regex[:20] + '...'
		prfx2 = prfx + f'| regex #{regex_idx} |'
		
		# log_if(is_print, f'{prfx2} case sensitive: {is_case_sensitive} | result: {regex_match}')
		if regex_match is not None:
			regex_groups = list(regex_match.groups(re.Match))
			if len(regex_groups) == 0:
				regex_groups = [regex_match]
			
			log_if(is_print, f'{prfx2} requiring: "{require}" groups:{len(regex_groups)} range: {range}')

			for regex_match in regex_groups:
				if match.line_nr and match.line_quote:
					# Test relation between match.span and regex_match.span
					if require == 'overlap' or require is None:
						# Test ovelap between match.span and regex_match.span
						log_if(is_print, '{prfx}    > testing ovelap line #{line_nr_str}: {match.span}  vs.{regex_match.span}')
					elif require == 'after':
						log_if(is_print, '{prfx}    > testing after line #{line_nr_str}: {match.span}  vs.{regex_match.span}')
					elif require == 'before':
						log_if(is_print, '{prfx}    > testing before line #{line_nr_str}: {match.span}  vs.{regex_match.span}')
					elif require == 'anywhere':
						log_if(is_print, '{prfx}    > testing anywhere in line #{line_nr_str}: {match.span}  vs.{regex_match.span} == > SUCCESS')
						return True  # we know there is at least one regex match result
				else:
					log_if(is_print_fails, '{prfx}    > match has no line_quote ({line_stripped}) or line_nr {match.line_nr}')
		else:
			# log_if(is_print_fails, f'{prfx}| regex #{regex_idx} | {global_consts.FAIL_EMOJI} NO regex_matches found. : {regex_prefix}')
			return True
		regex_idx += 1
	return False


def is_valid_line_for_match(line: str, match: Match) -> bool: 
	extension: str = match.file_extension()

	# guard
	if line is None or match is None or match.filepath is None or extension is None: 
		return False
	
	ordered_keys: list[str] = ['main_line', 'line_before', 'line_after']

	# tests:
	regexes: list[re.Pattern] = [] 
	testing_line: str = line
	result: bool = True
	required_check = 'overlap'  # 'after', 'before', 'anywhere'
	for key in ordered_keys:
		file_types = ['*'] # we require at least the "any" file type
		file_types.append(extension)
		dict: dict[str: list[re.Pattern]] = {}
		
		if key == 'line_before':
			dict = global_consts.IGNORED_BY_PREV_LINE_FOR_FTYPE
			testing_line = match.line_before_match
			required_check = 'before'

		elif key == 'main_line':
			dict = global_consts.IGNORED_IN_LINE_OVERLAP_FOR_FTYPE
			testing_line = line or match.line_quote
			required_check = 'overlap'

		elif key == 'line_after':
			dict = global_consts.IGNORED_BY_NEXT_LINE_FOR_FTYPE
			testing_line = match.line_after_match
			required_check = 'after'
		else:
			print(f'is_valid_line_for_match {global_consts.FAIL_EMOJI} unhandled case in "ordered_key": {key or "<None>"}')

		# extend regexes array with more regexes specific for the file types:
		for ftype in file_types:
			regexes.extend(dict.get(ftype.lower().strip('.')) or [])

		# check prepped vars not None or empty
		if (testing_line is None) or (len(testing_line) == 0):
			testing_line = line.strip() or match.line_quote.strip()

		if (regexes is None) or (testing_line is None) or (len(testing_line) == 0):
			print(f'is_valid_line_for_match {global_consts.FAIL_EMOJI} {len(regexes)} regexes or line ({testing_line}) is empty / None')
			continue  # skip to next iteration
		elif len(regexes) == 0:
			print(f'is_valid_line_for_match {global_consts.FAIL_EMOJI} ZERO regexes for key: "{key}" ftypes: {file_types}')
			continue

		result = result and is_valid_line_for_match_line(testing_line, match, regexes, required_check)
		if not result:
			break  # exit for key in ordered_keys:


def list_item_at_index_or_default(lst: list[str], index: int, default: str = None, is_strip: bool = True) -> str:
	if index > len(lst) - 1: 
		return default
	
	result = lst[index]
	if is_strip:
		result = result.strip()

	if len(result) == 0:
		result = default

	return result


def line_or_none(line: str, min_len: int = 3, replacement: (str | None) = None) -> (str | None):
	if line is None or len(line) < min_len: 
		return replacement
	return line


def create_match_from_line(filepath: str, encoding: str, cur_line_nr: str, lines_triplet: list[str], detection_type: str) -> Match:
	match: Match = Match(filepath, encoding, cur_line_nr)
	match.line_before_match = line_or_none(lines_triplet[0], global_consts.MIN_LINE_LEN, global_consts.EMPTY_EMOJI)
	match.line_quote = line_or_none(lines_triplet[1],  global_consts.MIN_LINE_LEN, global_consts.EMPTY_EMOJI)
	match.line_after_match = line_or_none(lines_triplet[2], global_consts.MIN_LINE_LEN, global_consts.EMPTY_EMOJI)
	match.line_nr = cur_line_nr
	match.encoding_used = encoding
	match.detection_type = detection_type
	return match
	

def missing_triplet_desc(lines_tuple: tuple[str, str, str]) -> str:
	empty = global_consts.EMPTY_EMOJI
	pre = empty
	cur = empty
	post = empty
	if len(lines_tuple) > 0:
		pre = string_full_or_empty(lines_tuple[0])
	if len(lines_tuple) > 1: 
		cur = string_full_or_empty(lines_tuple[1])
	if len(lines_tuple) > 2: 
		post = string_full_or_empty(lines_tuple[2])
	return f'[{pre} {cur} {post}]'

def find_version_matches_in_line(filepath: str, line_idx: int, line_count: int, lines_tuple: tuple[str, str, str], encoding: str, compiled_regexes: list[re.Pattern]) -> list[Match]:
	prfx = (' ' * 6)

	# guard
	if line_idx < 0:
		print(f'{prfx} find_version_matches_in_line line idx < 0: {line_idx} lines_tuple: {lines_tuple}')
		return []
	
	if len(lines_tuple) < 3:
		print(f'{prfx} find_version_matches_in_line lines_tuple too small: {lines_tuple} (needs at least 3 elements)')
		return []

	# global "consts"
	MAX_BACK = 10
	MIN_BACK = 5
	empty = global_consts.EMPTY_EMOJI

	# prep variables
	filename = os.path.basename(filepath).strip()
	is_print = True
	part: float = float(line_idx + 1) / float(max(line_count, 1))
	percent = f'{100 * part:.2f}%'
	percent = percent.replace('.0%', '.00%', 1)
	percent = percent.rjust(6)
	if part < 1.0:
		percent = ' ' + percent
	cur_line_nr_str = global_consts.line_nr_to_str(line_idx)
	prfx = (' ' * 6) + f' vmil | {filename} |{percent} | {cur_line_nr_str}'
	
	if len(lines_tuple) < 3:
		if line_idx == 0 and len(lines_tuple) == 2:
			lines_tuple = [empty, lines_tuple[0], lines_tuple[1]]

	cur_line = lines_tuple[1]
	cur_line_stripped = cur_line.strip()
	
	# perform a basic line validation:
	if not is_valid_line_for_regexes(cur_line):
		# line is not valid for testing
		# log_if(is_print, f'{prfx} {global_consts.EMPTY_EMOJI} line is empty / small / not valid: "{cur_line_stripped}".')
		# temp = is_valid_line_for_regexes(cur_line)
		return []
	
	# create a Match object for the line:
	detection_type = 'find_ver_str'  # no_caps ?
	match: Match = create_match_from_line(filepath, encoding, line_idx, lines_tuple, detection_type)
	log_if(is_print, f'{prfx} {missing_triplet_desc(lines_tuple)} "{cur_line_stripped}"')
		
	# "advanced" line validitaton:
	# TODO: parse (???!?) the "require" param's options: 'overlap', 'after', 'before', 'anywhere'
	if not is_valid_line_for_match_line(cur_line, match, compiled_regexes, require=None, is_case_sensitive=False):
		print(f'{prfx} > ❌ FAILED. line not valid: | {cur_line_stripped}')
		return []
	
	# find matches / process line:
	# found_matches: dict[str:Match] = {}
	found_matches: dict[str:Match] = find_regex_matches_in_match_instance(compiled_regexes,
		match,  # match to fill...
		False,  # is_case_sensitive
		True,  # is_stop_on_first match
		'vmil',  # context text
		is_print=True
		)
	
	# return result
	if found_matches and len(found_matches) > 0:
		print(f'{prfx} > ✅ found_matches: {len(found_matches)} found')
		found_matches = filter_biggest_match(found_matches)
		return list(found_matches.values())
	# else:
	return []


def filter_biggest_match(matches: dict[str:Match]) -> dict[str:Match]:
	if len(matches) <= 1:
		return matches
	
	for amatch in matches:
		print(f'filter_biggest_match : {amatch}')

	# not found:
	return matches


def find_version_matches_in_file(filepath: str, compiled_regexes: list[re.Pattern]) -> list[Match]:
	# guard input
	if compiled_regexes is None or len(compiled_regexes) == 0 or \
		filepath is None or len(filepath) == 0:
		return []
	
	# guard file size?
	filesize = os.stat(filepath).st_size
	if filesize < global_consts.MIN_FILE_LEN or \
		filesize > global_consts.MAX_FILE_LEN:
		return []

	# prep variables
	result: list[Match] = []
	filename = os.path.basename(filepath).strip()
	dir = filepath[0:len(filepath) - len(filename)]  # string[start:end:step]
	# temp_file_name = f'{os.path.join(dir, "temp_file_for_bump.tmp")}'
	prfx = (' ' * 4) + f' vmif   | {filename} | '
	encoding = detect_file_encoding(filepath, filesize)
	is_print = True

	# guard encoding type was found
	if encoding is None or len(encoding) == 0:
		return []
	
	# open and loop file
	line_idx = 0
	triplet: list[str] = []

	try:
		# iterate file lines in this encoding:
		with open(filepath, mode='r+', encoding=encoding) as f:
			with NamedTemporaryFile(delete=False, mode='w+', encoding=encoding) as fout:
				# iterate lines
				line_cnt:int = 0

				# count lines (todo optimize? is this info needed for a functional reason?)
				for line in f:
					line_cnt += 1
				f.seek(0)  # reset file read cursor
				print(f'{prfx} = total {line_cnt} lines =')

				# iterate lines
				for line in f:
					triplet.append(line)

					if len(triplet) >= 4:
						triplet.pop(0)

					if len(triplet) >= 1:
						line_results: list[Match] = find_version_matches_in_line(filepath, line_idx - 1, line_cnt, triplet, encoding, compiled_regexes)
						result.extend(line_results)
					line_idx += 1 

				# process last line: (after loop ended)
				triplet.pop(0)
				triplet.append(global_consts.EMPTY_EMOJI)
				last_line_results = find_version_matches_in_line(filepath, line_idx - 1, line_cnt, triplet, encoding, compiled_regexes)
				result.extend(last_line_results)

	except Exception as e:
		err_str: str = f'{type(e)} {str(e)}'
		ignore_err_regexes: list[re.Pattern] = [r'UnicodeDecodeError']
		ctx: str = global_consts.EXCEPTION_FILTER_KEY
		errors_to_ignore_err: dict[str:str] = find_regex_matches_in_str(ignore_err_regexes, err_str, ctx, False, True, ctx)
		
		if len(errors_to_ignore_err) > 0:
			# we ignore the error
			if is_print:
				print(f'{prfx} ignoring error code: {errors_to_ignore_err}')
		else:
			print(f'{prfx} \nException :.. [{err_str}] {traceback.format_exc()}\n')
	finally:
		# end of exeption handling
		# final result of function:
		return result

def find_version_matches_in_files(possible_filepaths: list[str]) -> list[Match]:
	if len(possible_filepaths) == 0:   # guard
		return []

	# prep
	# is_print:bool = False
	prfx = ' ' * 1
	total_filepaths = len(possible_filepaths)
	print(f'{prfx}⤷ find_version_matches_in_files. Searching in {total_filepaths} filepaths')
	possible_filepaths = unique(possible_filepaths)
	possible_filepaths.sort()
	prfx2 = (' ' * 2) + f' fvmif '

	# calc the min depth amongs all 'absolute' paths (except shorthand paths)
	global_min_path_depth = 9999
	for filepath in possible_filepaths:
		if not filepath.startswith('../'): 
			global_min_path_depth = min(global_min_path_depth, len(filepath.split('/')))

	results: list[Match] = []
	file_index = 0
	for filepath in possible_filepaths:
		# spc = path_prefix_space(filepath, -global_min_path_depth)
		strip_sze = global_min_path_depth
		if filepath.startswith('..'): 
			strip_sze = 0
		possible_regexes = get_regexes_for_filepath(filepath)

		# log progress for a file in the possible_filepaths:
		log_file_progress(clean_folder_name(filepath, strip_sze),
			file_index, total_filepaths, len(possible_regexes))
		
		# process file:
		res: list[Match] = unique(find_version_matches_in_file(filepath, possible_regexes))
		if len(res) > 0:
			# add results to unique_matches list - preventing duplicte objects:
			results.extend(res)
			
		# for a_result in results:
			# print(f'{prfx2} found ver matches in file: [{a_result.filename()}] adding result | {a_result.filename()} | {a_result.line_nr} | {a_result.line_quote.strip()} substr: [{a_result.found_match_str()}]')
		file_index += 1
		
	# end iterating filepaths

		# TODO: Remove this! temp
		MIN_RESULTS = 3 
		if len(results) > MIN_RESULTS:
			# TODO: Remove this
			print(f'{prfx}  fvmifs - TEMP RETURN after {MIN_RESULTS} result/s -')
			break
	
	results = unique(results)
	print(f'{prfx}  fvmifs unique_matches: {len(results)}')
	return results


def accum_versions_in_matches(matches: list[Match]) -> semver.VersionInfo:
	# the function will iterate over all matchs and try to 
	# determine which match is the one that is most 'fitting' to apply the semver for the whole project (and set all the appearances of it to this version, bumped):

	is_print = False
	prfx = (' ' * 2)
	if matches is None or len(matches) == 0:
		print(f'{prfx}⤷ {global_consts.EMPTY_EMOJI} accum_versions_in_matches had 0 matches!')
		return

	result: semver.VersionInfo = None
	found: dict[str:semver.VersionInfo] = {}
	for match in matches:
		# having this complex key prevents duplicte 'locations' (i.e same file, line) 
		#   - serves like a human-readable hash number:
		key = f'{match.filepath}_{match.line_nr}_{match.detection_type}_{match.found_match_str()}'
		version = match.to_version_info()
		if version:
			found[key] = version
		elif is_print:
			print(f'{prfx}⤷ {global_consts.FAIL_EMOJI} accum_versions_in_matches failed parsing "{match.found_match_str()}" into a varsion (semver OR build nr).')
	print(f'{prfx} accum_versions_in_matches accumed {len(found)} / {len(matches)} matches.')

	# count for each found version the number of appearances / occurances
	# Counter will return a dict [semver.VersionInfo: int] where the values represent how many times this exact semver version appeared
	found2: dict[str:int] = {}
	for key in found:
		val: semver.VersionInfo = found[key]
		newKey = f'{val.major}_{val.minor}_{val.patch}_{val.prerelease}_{val.build}'
		cnt = found2.get(newKey) or 0
		found2[newKey] = cnt + 1
	
	asorted = sorted(found2)
	for key in found2:
		count = found2[key]
		print(f'{prfx} {key} appeared {count} times.')
	
	# if match.detection_type != 'in_str':
	# 	for key in found:
	# 		line_str = match.line_nr_to_str()
	# 		print(f'{prfx}  ]>> "{match.filename()}" | ln# {line_str} | {match.span} | "{match.found_match_str()}" | "{match.line_quote.strip()}"')
	# if len(found) == 1: 
	# 	return found
	
	return result

# MARK: manipulate found version:
def bump_version(version: semver.VersionInfo) -> semver.VersionInfo:
	result = version
	print(f'⤷ bump_version {version} -> {result}')
	return result


# MARK: approval of changes
def approve_changes(found_varsion: semver.VersionInfo, bumped_vesion: semver.VersionInfo, matches: list[Match]) -> bool:
	result = False
	print(f'⤷ approve_changes {found_varsion} -> {bumped_vesion} in {len(matches)} locations?')
	return result


def save_matches(matches: list[Match])->bool:
	print(f'⤷ save_matches {len(matches)} TODO: IMPLEMENT')
	return False


# MARK: manipulate approved matches
def apply_version(bumped_vesion: semver.VersionInfo, matches: list[Match]) -> SuccessCounter:
	result = SuccessCounter()  # amount of successes
	print(f'⤷ bump_versions_in_matches {len(matches)} matches')
	return result


def apply_version_to_git_tag(target_version: semver.VersionInfo):
	return None


def abort(reason) -> None:
	global global_wasAborted  # "import" global var
	global_wasAborted = reason
	print(f'[ {global_consts.FAIL_EMOJI} ABORT ] | {reason}')


def log_file_progress(filepath: str, index: int, total: int, possible_regexes_cnt: int) -> None:
	is_write_on_one_line = False

	# prep
	total = max(total, 1)
	part: float = float(index + 1) / float(total)
	percent = f'{100 * part:.2f}%'
	percent = percent.replace('.0%', '.00%', 1)
	percent = percent.rjust(6)
	prfx = ' ' * 4
	if part == 1.00:
		prfx = ' ' * 3
	possi = f'{possible_regexes_cnt}'.zfill(2)

	str = f'{prfx} {percent} | {possi} regexes × {filepath}'
	if possible_regexes_cnt == 0:
		str = f'{prfx} {percent} | ZERO regexes × {filepath}'
		
	# fill-to-width is used when we os.write(...) in same place, and we want to overwrite past line. # |> str = str + (' ' * (max(80 - len(str), 0)))

	if is_write_on_one_line:
		if index == 0:
			sys.stdout.flush()
		sys.stdout.write('\r' + str)
		sys.stdout.flush()
	else:
		# prefix: [search]
		print(str)


def search() -> None:
	print('⤷ search')

	# find all files:
	found_set = find_possible_filepaths(global_args.root_path, global_args.possible_paths)
	possible_filepaths: list[str] = list(found_set)

	# add source file path as first filepath:
	if len(global_args.sourcefile) > 0:
		possible_filepaths.remove(global_args.sourcefile)
		possible_filepaths.insert(global_args.sourcefile, 0)

	if len(possible_filepaths) == 0:
		abort('found 0 possible file paths!')
		return

	# iterate for each file:

	# find matches for semver in each line of each found file:
	found_matches: list[Match] = find_version_matches_in_files(possible_filepaths)
	if found_matches is None or len(found_matches) == 0:
		abort('search()->None find_version_matches_in_files return None or empty.')
		return

	print(f'search() found total of: {len(found_matches)} unique matches:')

	# agree on a version number:
	found_version: semver.VersionInfo = global_args.exact_version

	# exact version provided in cmd line args: (exact ver is used as-is-provided (and should not be "bumped")
	if global_args.exact_version:  
		# we have a preset exact version, so we don't need to collect
		found_version = global_args.exact_version  # all versions are overriden by this one
	elif found_version is None:
		found_version = accum_versions_in_matches(found_matches)

	print(f'search() search: found_version [{found_version}]. TEMP RETURN')
	return

	# bump the version
	bumped_version: semver.VersionInfo = bump_version(found_version)

	# approve version and locations if needed?
	# bad grammer, but using the convention of prefixes of "is_" for all boolean vars.
	is_changes_approved: bool = approve_changes(found_version, bumped_version, found_matches)

	# allow changes only if were approved
	if is_changes_approved:
		# apply new version in all approved places
		success: SuccessCounter = apply_version(bumped_version, found_matches)

		if global_args.is_update_git_tag:
			apply_version_to_git_tag(bumped_version)

		# will save if allowed:
		save_matches(found_matches)


# root run:
if __name__ == "__main__":

	print('============================= START =============================')

	# setup: will set up global_args
	setup_parser()
	setup_regexes_by_filename()
	print(f'    command line args: {vars(global_args)}')

	# main run
	search()
	emoji = global_consts.OK_EMOJI
	if len(global_wasAborted) > 0:
		emoji = global_consts.FAIL_EMOJI
	print(f'{emoji} Done')
	if len(global_wasAborted) > 0:
		sys.exit(1)
