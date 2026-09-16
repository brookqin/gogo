#!/usr/bin/env python3
"""Validate release tags and write a changelog from reachable Git history."""
import argparse
import html
import re
import subprocess
from pathlib import Path

TAG = re.compile(r"v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?(?:\+([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?")


def parse_tag(tag):
    match = TAG.fullmatch(tag)
    if not match:
        raise ValueError("Expected vMAJOR.MINOR.PATCH, optionally with a prerelease or build suffix")
    if match[4] and any(part.isdigit() and len(part) > 1 and part.startswith('0')
                        for part in match[4].split('.')):
        raise ValueError("Numeric prerelease identifiers must not have leading zeroes")
    return '.'.join(match.group(1, 2, 3)), match[4] is not None


def git(*args, cwd=None):
    return subprocess.check_output(['git', *args], cwd=cwd, text=True).strip()


def previous_tag(tag, cwd=None):
    candidates = []
    for candidate in git('tag', '--merged', f'refs/tags/{tag}', cwd=cwd).splitlines():
        if candidate == tag:
            continue
        try:
            parse_tag(candidate)
        except ValueError:
            continue
        candidates.extend(['--match', candidate])
    if not candidates:
        return None
    # Includes lightweight and annotated tags; ignores tags on unrelated branches.
    return git('describe', '--tags', '--abbrev=0', *candidates, f'refs/tags/{tag}', cwd=cwd)


def notes(tag, repository, cwd=None):
    parse_tag(tag)
    if not re.fullmatch(r'[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+', repository):
        raise ValueError('Expected an owner/repository name')
    previous = previous_tag(tag, cwd)
    current_ref = f'refs/tags/{tag}'
    commit_range = f'refs/tags/{previous}..{current_ref}' if previous else current_ref
    log = git('log', '--reverse', '--format=%H%x00%s', commit_range, '--', cwd=cwd)
    lines = ['## Changes', '']
    if previous:
        lines += [f'Commits since `{previous}`.', '']
    else:
        lines += ['Initial release: all commits through this tag.', '']
    for line in log.splitlines():
        sha, subject = line.split('\0', 1)
        subject = re.sub(r'([\\`*_{}\[\]])', r'\\\1', html.escape(subject))
        lines.append(f'- {subject} ([{sha[:7]}](https://github.com/{repository}/commit/{sha}))')
    if not log:
        lines.append('No new commits since the previous tag.')
    if previous:
        lines += ['', f'[Full comparison](https://github.com/{repository}/compare/{previous}...{tag})']
    lines += ['', '## Installation', '',
              'Choose the arm64 DMG for Apple Silicon or the x86_64 DMG for Intel Macs. '
              'This build is ad-hoc signed and not notarized by Apple.', '',
              f'See the [installation instructions](https://github.com/{repository}/blob/{tag}/README.md#installation).', '']
    return '\n'.join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('tag')
    parser.add_argument('--repository', required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--github-output', type=Path)
    args = parser.parse_args()
    version, prerelease = parse_tag(args.tag)
    body = notes(args.tag, args.repository)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(body, encoding='utf-8')
    if args.github_output:
        with args.github_output.open('a', encoding='utf-8') as output:
            output.write(f'version={version}\nprerelease={str(prerelease).lower()}\n')


if __name__ == '__main__':
    main()
