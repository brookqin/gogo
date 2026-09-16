import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from release_notes import notes, parse_tag, previous_tag


class ReleaseNotesTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.git('init', '-q', '-b', 'main')
        self.git('config', 'user.name', 'Release Test')
        self.git('config', 'user.email', 'release-test@example.invalid')

    def git(self, *args):
        return subprocess.check_output(
            ['git', '-c', 'commit.gpgsign=false', '-c', 'tag.gpgsign=false', *args],
            cwd=self.root, text=True, stderr=subprocess.PIPE).strip()

    def commit(self, subject):
        self.git('commit', '--allow-empty', '-qm', subject)
        return self.git('rev-parse', 'HEAD')

    def test_first_release_includes_all_commits(self):
        first = self.commit('Initial work')
        last = self.commit('Finish launchers')
        self.git('tag', 'v0.1.0')
        body = notes('v0.1.0', 'brookqin/gogo', self.root)
        self.assertIn(first, body)
        self.assertIn(last, body)
        self.assertIn('Initial release', body)
        self.assertIn('arm64 DMG', body)
        self.assertIn('x86_64 DMG', body)
        self.assertNotIn('ZIP', body)
        self.assertIsNone(previous_tag('v0.1.0', self.root))

    def test_range_excludes_previous_release_and_includes_merge_history(self):
        old = self.commit('Already shipped')
        self.git('tag', '-a', 'v0.1.0', '-m', 'First release')
        self.git('checkout', '-qb', 'feature')
        feature = self.commit('Feature commit')
        self.git('checkout', '-q', 'main')
        self.commit('Main commit')
        self.git('merge', '--no-ff', '-qm', 'Merge feature', 'feature')
        self.git('tag', 'v0.2.0')
        body = notes('v0.2.0', 'brookqin/gogo', self.root)
        self.assertEqual(previous_tag('v0.2.0', self.root), 'v0.1.0')
        self.assertNotIn(old, body)
        self.assertIn(feature, body)
        self.assertIn('Main commit', body)
        self.assertIn('compare/v0.1.0...v0.2.0', body)

    def test_ignores_unrelated_and_non_version_tags(self):
        self.commit('Initial')
        self.git('tag', 'v0.1.0')
        self.git('checkout', '-qb', 'other')
        self.commit('Unrelated')
        self.git('tag', 'v9.0.0')
        self.git('checkout', '-q', 'main')
        self.commit('Included')
        self.git('tag', 'verification')
        self.git('tag', 'v-not-a-version')
        self.git('tag', 'v0.2.0')
        self.assertEqual(previous_tag('v0.2.0', self.root), 'v0.1.0')
        self.assertNotIn('Unrelated', notes('v0.2.0', 'brookqin/gogo', self.root))

    def test_same_commit_release_has_empty_changelog(self):
        self.commit('Initial')
        self.git('tag', 'v1.0.0-rc.1')
        self.git('tag', 'v1.0.0')
        self.assertIn('No new commits', notes('v1.0.0', 'brookqin/gogo', self.root))

    def test_tag_validation_and_prerelease_detection(self):
        self.assertEqual(parse_tag('v1.2.3'), ('1.2.3', False))
        self.assertEqual(parse_tag('v1.2.3-beta.1+build.7'), ('1.2.3', True))
        self.assertEqual(parse_tag('v1.2.3+build.7'), ('1.2.3', False))
        for invalid in ('1.2.3', 'v1', 'v1.2', 'v01.2.3', 'v1.2.3-01', 'v1.2.3\n', 'v1.2.3;echo unsafe'):
            with self.subTest(tag=invalid), self.assertRaises(ValueError):
                parse_tag(invalid)

    def test_subject_is_text_not_markdown_or_shell(self):
        subject = 'Fix [link](https://example.invalid) <img> `code` $(echo untouched)'
        self.commit(subject)
        self.git('tag', 'v1.0.0')
        body = notes('v1.0.0', 'brookqin/gogo', self.root)
        self.assertIn('\\[link\\]', body)
        self.assertIn('&lt;img&gt;', body)
        self.assertIn('\\`code\\`', body)
        self.assertIn('$(echo untouched)', body)

    def test_cli_writes_notes_and_github_outputs(self):
        self.commit('Prerelease')
        self.git('tag', 'v2.0.0-beta.1')
        output = self.root/'release/CHANGELOG.md'
        github_output = self.root/'github-output'
        script = Path(__file__).resolve().parents[1]/'release_notes.py'
        subprocess.run([sys.executable, '-B', str(script), 'v2.0.0-beta.1',
                        '--repository', 'brookqin/gogo', '--output', str(output),
                        '--github-output', str(github_output)], cwd=self.root, check=True)
        self.assertIn('Prerelease', output.read_text())
        self.assertEqual(github_output.read_text(), 'version=2.0.0\nprerelease=true\n')


if __name__ == '__main__':
    unittest.main()
