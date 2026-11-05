"""Self-contained stdlib tests; no games, downloads, or host umu required."""

import argparse
import contextlib
import io
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
import threading
import unittest
from unittest import mock

import umuctl


class UmuctlTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.home = self.root / "home space"
        self.home.mkdir()
        self.env = mock.patch.dict(os.environ, {
            "HOME": str(self.home),
            "XDG_CONFIG_HOME": str(self.home / "config"),
            "XDG_DATA_HOME": str(self.home / "data"),
            "XDG_CACHE_HOME": str(self.home / "cache"),
            "XDG_STATE_HOME": str(self.home / "state"),
        })
        self.env.start()
        self.addCleanup(self.env.stop)
        for variable in ("UMUCTL_UMU_RUN", "UMUCTL_EXECUTABLE", "PROTONPATH", "WINEPREFIX", "STORE", "GAMEID",
                         "VK_ICD_FILENAMES", "VK_DRIVER_FILES"):
            os.environ.pop(variable, None)
        self.config_path = self.home / "config" / "umuctl" / "config.toml"
        self.config_path.parent.mkdir(parents=True)
        self.first_icd = self.make_icd("drivers/first.json")
        self.second_icd = self.make_icd("drivers/second.json")
        self.config = {"gpu": {
            "portable_1": {"icd_files": [str(self.first_icd), str(self.second_icd)]},
            "render-2": {"icd_files": [str(self.second_icd)]},
        }, "proton": {"dw": {"path": "~/Proton"}}, "apps": {"demo": {
            "exe": "C:\\Program Files\\Game\\game.exe", "proton": "dw", "prefix": "~/Games/prefix",
        }}}
        self.options = argparse.Namespace(proton=None, prefix=None, game_id=None, wayland=None, gpu=None)

    def make_icd(self, name):
        path = self.home / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps({"ICD": {"library_path": "libvulkan_fixture.so"}}))
        return path

    def write_config(self, text):
        self.config_path.write_text(text)

    def gpu_config(self):
        return (f'[gpu.portable_1]\nicd_files={json.dumps([str(self.first_icd), str(self.second_icd)])}\n'
                f'[gpu.render-2]\nicd_files={json.dumps([str(self.second_icd)])}\n')

    def cli(self, *args):
        output, errors = io.StringIO(), io.StringIO()
        with contextlib.redirect_stdout(output), contextlib.redirect_stderr(errors):
            result = umuctl.main(["--config", str(self.config_path), *args])
        return result, output.getvalue(), errors.getvalue()

    def sync(self):
        with contextlib.redirect_stdout(io.StringIO()):
            umuctl.sync(self.config, self.config_path)

    @property
    def desktop(self):
        return self.home / "data/applications/umuctl-demo.desktop"

    @property
    def manifest(self):
        return self.home / "state/umuctl/manifest.json"

    def test_home_expansion_no_shell_or_other_variables(self):
        self.assertEqual(umuctl.expand("~/a"), str(self.home / "a"))
        self.assertEqual(umuctl.expand("${HOME}/a"), str(self.home / "a"))
        self.assertEqual(umuctl.expand("$HOME/a"), str(self.home / "a"))
        self.assertEqual(umuctl.expand("$PATH/$(touch no); ~other"), "$PATH/$(touch no); ~other")
        self.assertEqual(umuctl.expand("$HOME_OTHER/$HOME1"), "$HOME_OTHER/$HOME1")

    def test_env_precedence_and_unset(self):
        preset = self.config["proton"]["dw"]
        preset.update(env={"A": "preset", "COUNT": 2}, unset=["REMOVE"])
        app = self.config["apps"]["demo"]
        app.update(env={"A": "app", "VK_ICD_FILENAMES": "/app", "VK_DRIVER_FILES": "/app-new"},
                   unset=["OLD"], game_id="game-1", wayland=True, gpu="portable_1")
        env = umuctl.launch_env(self.config, app, self.options, self.home,
                               {"PROTONPATH": "/external", "WINEPREFIX": "/old", "REMOVE": "1", "OLD": "1",
                                "VK_ICD_FILENAMES": "/inherited", "VK_DRIVER_FILES": "/inherited-new",
                                "VK_ADD_DRIVER_FILES": "/unchanged", "DRI_PRIME": "unchanged"})
        self.assertEqual(env["PROTONPATH"], "/external")
        self.assertEqual(env["WINEPREFIX"], str(self.home / "Games/prefix"))
        self.assertEqual(env["A"], "app")
        self.assertEqual(env["COUNT"], "2")
        self.assertNotIn("REMOVE", env)
        self.assertNotIn("OLD", env)
        self.assertEqual(env["GAMEID"], "game-1")
        self.assertEqual(env["PROTON_ENABLE_WAYLAND"], "1")
        self.assertEqual(env["VK_ICD_FILENAMES"], f"{self.first_icd}:{self.second_icd}")
        self.assertNotIn("VK_DRIVER_FILES", env)
        self.assertEqual(env["VK_ADD_DRIVER_FILES"], "/unchanged")
        self.assertEqual(env["DRI_PRIME"], "unchanged")

    def test_explicit_selectors_win(self):
        self.options.proton = "dw"
        self.options.prefix = "~/new prefix"
        self.options.game_id = "cli"
        self.options.wayland = False
        self.options.gpu = "default"
        env = umuctl.launch_env(self.config, self.config["apps"]["demo"], self.options,
                               self.home, {"PROTONPATH": "/external", "VK_ICD_FILENAMES": "/old",
                                           "VK_DRIVER_FILES": "/newer"})
        self.assertEqual(env["PROTONPATH"], str(self.home / "Proton"))
        self.assertEqual(env["WINEPREFIX"], str(self.home / "new prefix"))
        self.assertEqual(env["GAMEID"], "cli")
        self.assertEqual(env["PROTON_ENABLE_WAYLAND"], "0")
        self.assertNotIn("VK_ICD_FILENAMES", env)
        self.assertNotIn("VK_DRIVER_FILES", env)

    def test_gpu_absence_preserves_both_inherited_driver_variables(self):
        inherited = {"VK_ICD_FILENAMES": "/missing-old", "VK_DRIVER_FILES": "/missing-new"}
        env = umuctl.launch_env(self.config, {}, self.options, self.home, inherited)
        self.assertEqual(env, inherited)
        self.assertEqual(inherited, {"VK_ICD_FILENAMES": "/missing-old", "VK_DRIVER_FILES": "/missing-new"})

    def test_gpu_absence_retains_normal_env_overlay_precedence(self):
        self.config["proton"]["dw"]["env"] = {"VK_ICD_FILENAMES": "/preset-old", "VK_DRIVER_FILES": "/preset-new"}
        app = self.config["apps"]["demo"]
        app.update(env={"VK_DRIVER_FILES": "/app-new"}, unset=["VK_ICD_FILENAMES"])
        env = umuctl.launch_env(self.config, app, self.options, self.home,
                               {"VK_ICD_FILENAMES": "/inherited-old", "VK_DRIVER_FILES": "/inherited-new"})
        self.assertNotIn("VK_ICD_FILENAMES", env)
        self.assertEqual(env["VK_DRIVER_FILES"], "/app-new")

    def test_app_default_clears_both_driver_variables(self):
        app = {"gpu": "default", "env": {"VK_DRIVER_FILES": "/overlay"}}
        env = umuctl.launch_env(self.config, app, self.options, self.home,
                               {"VK_ICD_FILENAMES": "/old", "VK_DRIVER_FILES": "/new", "KEEP": "yes"})
        self.assertEqual(env, {"KEEP": "yes"})

    def test_gpu_cli_overrides_app_profile_and_default(self):
        self.options.gpu = "render-2"
        for app_gpu in ("portable_1", "default"):
            with self.subTest(app_gpu=app_gpu):
                env = umuctl.launch_env(self.config, {"gpu": app_gpu}, self.options, self.home,
                                       {"VK_DRIVER_FILES": "/old-new"})
                self.assertEqual(env["VK_ICD_FILENAMES"], str(self.second_icd))
                self.assertNotIn("VK_DRIVER_FILES", env)
        self.options.gpu = "default"
        env = umuctl.launch_env(self.config, {"gpu": "portable_1"}, self.options, self.home,
                               {"VK_DRIVER_FILES": "/old-new", "VK_ICD_FILENAMES": "/old"})
        self.assertEqual(env, {})

    def test_app_env_can_override_or_unset_preset_default(self):
        app = self.config["apps"]["demo"]
        app["env"] = {"PROTONPATH": "/app-proton"}
        env = umuctl.launch_env(self.config, app, self.options, self.home, {})
        self.assertEqual(env["PROTONPATH"], "/app-proton")
        app.pop("env")
        app["unset"] = ["PROTONPATH"]
        self.assertNotIn("PROTONPATH", umuctl.launch_env(self.config, app, self.options, self.home, {}))

    def test_valid_schema(self):
        self.write_config('''[proton.dw]
path = "~/Proton"
unset = ["OLD"]
[proton.dw.env]
NUMBER = 1
[apps.demo]
exe = 'C:\\game.exe'
proton = "dw"
wayland = false
before = [["tool", "$HOME/a"]]
after = [["tool", "restore"]]
''')
        config = umuctl.load_config(self.config_path)
        self.assertEqual(config["proton"]["dw"]["env"]["NUMBER"], 1)

    def test_invalid_config_values(self):
        for text in ('[apps."../evil"]\nexe="x"', '[apps.x]\nexe="x"\nwayland="true"',
                     '[apps.x]\nexe="x"\ngpu="unknown"', '[apps.x]\nexe="x"\nbefore=["echo"]',
                     '[apps.x]\nexe="x"\nafter=[[]]', '[apps.x]\nexe="x"\nproton="missing"',
                     '[apps.x]\nexe="x"\n[apps.x.env]\nFLAG=true',
                     '[apps.x]\nexe="x"\ntypo="y"', '[apps.x]\nname="missing exe"',
                     '[apps.x]\nexe="line\\nbreak"', 'apps = []'):
            with self.subTest(text=text):
                self.write_config(text)
                with self.assertRaises(umuctl.Error):
                    umuctl.load_config(self.config_path)

    def test_gpu_schema_supports_arbitrary_names_and_multiple_manifests(self):
        self.write_config(self.gpu_config() + '[apps.demo]\nexe="game"\ngpu="portable_1"\n')
        config = umuctl.load_config(self.config_path)
        self.assertEqual(set(config["gpu"]), {"portable_1", "render-2"})
        self.assertEqual(config["gpu"]["portable_1"]["icd_files"], [str(self.first_icd), str(self.second_icd)])
        self.assertEqual(config["apps"]["demo"]["gpu"], "portable_1")

    def test_gpu_schema_rejects_bad_ids_fields_and_path_arrays(self):
        invalid = [
            'gpu=[]', '[gpu."../escape"]\nicd_files=["x"]', '[gpu.default]\nicd_files=["x"]',
            '[gpu.x]\ntypo=["x"]', '[gpu.x]\nicd_files=["x"]\nother="no"',
            '[gpu.x]', '[gpu.x]\nicd_files=[]', '[gpu.x]\nicd_files="x"',
            '[gpu.x]\nicd_files=[1]', '[gpu.x]\nicd_files=[true]', '[gpu.x]\nicd_files=[""]',
            '[gpu.x]\nicd_files=["a:b"]', '[gpu.x]\nicd_files=["a\\nb"]',
            '[gpu.x]\nicd_files=["a\\rb"]', '[gpu.x]\nicd_files=["a\\u0000b"]',
            '[apps.x]\nexe="game"\ngpu=""', '[apps.x]\nexe="game"\ngpu="missing"',
        ]
        for text in invalid:
            with self.subTest(text=text):
                self.write_config(text)
                with self.assertRaises(umuctl.Error):
                    umuctl.load_config(self.config_path)

    def test_gpu_paths_expand_home_and_normalize_relative_to_config(self):
        local = self.make_icd("config/umuctl/local.json")
        values = ["sub/../local.json", "~/drivers/first.json", "$HOME/drivers/second.json",
                  "${HOME}/drivers/first.json"]
        self.write_config(f'[gpu.custom-7]\nicd_files={json.dumps(values)}\n'
                          '[apps.demo]\nexe="game"\ngpu="custom-7"\n')
        config = umuctl.load_config(self.config_path)
        env = umuctl.launch_env(config, config["apps"]["demo"], self.options, self.config_path.parent, {})
        self.assertEqual(env["VK_ICD_FILENAMES"], ":".join(map(str, [local, self.first_icd, self.second_icd, self.first_icd])))

    def test_gpu_paths_reject_colon_introduced_by_home_expansion(self):
        self.config["gpu"]["portable_1"]["icd_files"] = ["~/fixture.json"]
        with mock.patch.dict(os.environ, {"HOME": "/invalid:home"}):
            with self.assertRaisesRegex(umuctl.Error, "without colons"):
                umuctl.launch_env(self.config, {"gpu": "portable_1"}, self.options, self.home, {})

    def test_gpu_selection_fails_before_hooks_or_application(self):
        bad = self.home / "bad.json"
        invalid = [b"not json", b"\\xff", b"[]", b"{}", b'{"ICD": []}',
                   b'{"ICD": {"library_path": ""}}', b'{"ICD": {"library_path": "  "}}',
                   b'{"ICD": {"library_path": 1}}', b'{"ICD": {"api_version": "1.4"}}']
        self.write_config(f'[gpu.broken]\nicd_files={json.dumps([str(self.first_icd), str(bad)])}\n'
                          '[apps.demo]\nexe="game"\ngpu="broken"\nbefore=[["hook"]]\n')
        for content in invalid:
            with self.subTest(content=content):
                bad.write_bytes(content)
                with mock.patch.object(umuctl, "supervise") as launch:
                    code, _, errors = self.cli("run", "demo")
                self.assertEqual(code, 2)
                self.assertIn(str(bad), errors)
                self.assertIn("Vulkan ICD manifest", errors)
                launch.assert_not_called()

    def test_gpu_missing_and_unreadable_files_fail_before_launch(self):
        missing = self.home / "absent.json"
        self.write_config(f'[gpu.broken]\nicd_files={json.dumps([str(missing)])}\n'
                          '[apps.demo]\nexe="game"\ngpu="broken"\nbefore=[["hook"]]\n')
        with mock.patch.object(umuctl, "supervise") as launch:
            code, _, errors = self.cli("run", "demo")
        self.assertEqual(code, 2)
        self.assertIn(str(missing), errors)
        launch.assert_not_called()
        original_open = Path.open
        def unreadable(path, *args, **kwargs):
            if path == self.first_icd:
                raise PermissionError("fixture permission denied")
            return original_open(path, *args, **kwargs)
        self.write_config(self.gpu_config() + '[apps.demo]\nexe="game"\ngpu="portable_1"\n')
        with mock.patch.object(Path, "open", unreadable), mock.patch.object(umuctl, "supervise") as launch:
            code, _, errors = self.cli("run", "demo")
        self.assertEqual(code, 2)
        self.assertIn("permission denied", errors)
        launch.assert_not_called()

    def test_gpu_missing_or_empty_profile_paths_fail_before_launch(self):
        for field in ("", "icd_files=[]\n", 'icd_files=[""]\n'):
            with self.subTest(field=field):
                self.write_config('[gpu.broken]\n' + field + '[apps.demo]\nexe="game"\ngpu="broken"\n'
                                  'before=[["hook"]]\n')
                with mock.patch.object(umuctl, "supervise") as launch:
                    code, _, errors = self.cli("run", "demo")
                self.assertEqual(code, 2)
                self.assertIn("gpu.broken.icd_files", errors)
                launch.assert_not_called()

    def test_gpu_cli_default_bypasses_app_manifest_and_clears_both(self):
        self.write_config('[gpu.broken]\nicd_files=["missing.json"]\n'
                          '[apps.demo]\nexe="game"\ngpu="broken"\n')
        with mock.patch.dict(os.environ, {"VK_ICD_FILENAMES": "/old", "VK_DRIVER_FILES": "/new"}), \
                mock.patch.object(umuctl, "supervise", return_value=0) as launch:
            code, _, errors = self.cli("run", "--gpu", "default", "demo")
        self.assertEqual(code, 0, errors)
        self.assertNotIn("VK_ICD_FILENAMES", launch.call_args.args[1])
        self.assertNotIn("VK_DRIVER_FILES", launch.call_args.args[1])

    def test_gpu_cli_absence_preserves_both_without_validating_inherited_files(self):
        self.write_config('[apps.demo]\nexe="game"\n')
        inherited = {"VK_ICD_FILENAMES": "/missing-old", "VK_DRIVER_FILES": "/missing-new"}
        with mock.patch.dict(os.environ, inherited), mock.patch.object(umuctl, "supervise", return_value=0) as launch:
            code, _, errors = self.cli("run", "demo")
        self.assertEqual(code, 0, errors)
        for key, value in inherited.items():
            self.assertEqual(launch.call_args.args[1][key], value)

    def test_vulkan_manifest_api_version_is_optional(self):
        umuctl.validate_icd(self.first_icd)
        self.first_icd.write_text(json.dumps({"ICD": {"library_path": "driver.so", "api_version": "1.4.0"}}))
        umuctl.validate_icd(self.first_icd)
        with self.assertRaisesRegex(umuctl.Error, "cannot read Vulkan ICD manifest"):
            umuctl.validate_icd(self.first_icd.parent)

    def test_gpu_unknown_exec_selector_checked_with_or_without_config(self):
        for configured in (False, True):
            with self.subTest(configured=configured):
                if configured:
                    self.write_config(self.gpu_config())
                with mock.patch.object(umuctl, "supervise") as launch:
                    code, _, errors = self.cli("exec", "--gpu", "missing-profile", "--", "game")
                self.assertEqual(code, 2)
                self.assertIn("unknown GPU profile", errors)
                launch.assert_not_called()

    def test_gpu_run_and_exec_cli_profile_overrides(self):
        self.write_config(self.gpu_config() + '[apps.demo]\nexe="game"\ngpu="portable_1"\n')
        for args in (("run", "--gpu", "render-2", "demo"),
                     ("exec", "--gpu", "render-2", "--", "game")):
            with self.subTest(args=args), mock.patch.object(umuctl, "supervise", return_value=0) as launch:
                with mock.patch.dict(os.environ, {"VK_DRIVER_FILES": "/ignored"}):
                    code, _, errors = self.cli(*args)
                self.assertEqual(code, 0, errors)
                self.assertEqual(launch.call_args.args[1]["VK_ICD_FILENAMES"], str(self.second_icd))
                self.assertNotIn("VK_DRIVER_FILES", launch.call_args.args[1])

    def test_missing_and_invalid_toml_status(self):
        code, _, errors = self.cli("list")
        self.assertEqual(code, 2)
        self.assertIn("configuration not found", errors)
        self.write_config("[invalid")
        self.assertEqual(self.cli("list")[0], 2)

    def test_list_and_unknown_app(self):
        self.write_config('[apps.demo]\nname="Demo Game"\nexe="game.exe"\n')
        self.assertEqual(self.cli("list")[:2], (0, "demo\tDemo Game\n"))
        self.assertEqual(self.cli("run", "missing")[0], 2)

    def test_run_arguments_no_shell_and_cli_prefix(self):
        self.write_config('[apps.demo]\nexe="/game path/game.exe"\nargs=["fixed arg"]\nprefix="/app"\n')
        with mock.patch.object(umuctl, "supervise", return_value=7) as run:
            code, _, _ = self.cli("run", "--prefix", "/explicit", "demo", "--", "x y", "$(touch nope)", "--flag")
        self.assertEqual(code, 7)
        command, env, _, _, _ = run.call_args.args
        self.assertEqual(command, ["/usr/bin/umu-run", "/game path/game.exe", "fixed arg", "x y", "$(touch nope)", "--flag"])
        self.assertEqual(env["WINEPREFIX"], "/explicit")

    def test_exec_without_config_and_missing_payload(self):
        with mock.patch.object(umuctl, "supervise", return_value=0) as run:
            self.assertEqual(self.cli("exec", "--wayland", "--gpu", "default", "--game-id", "g", "--", "game.exe", "a b")[0], 0)
        command, env, *_ = run.call_args.args
        self.assertEqual(command, ["/usr/bin/umu-run", "game.exe", "a b"])
        self.assertEqual(env["GAMEID"], "g")
        self.assertEqual(self.cli("exec", "--")[0], 2)
        self.assertEqual(self.cli("exec", "--proton", "missing", "--", "game")[0], 2)

    def test_config_relative_paths(self):
        self.assertEqual(umuctl.path_value("proton", self.home), str(self.home / "proton"))
        self.assertEqual(umuctl.executable("bin/hook", self.home), str(self.home / "bin/hook"))
        self.assertEqual(umuctl.executable("C:\\game.exe", self.home), "C:\\game.exe")

    def test_desktop_exec_escaping(self):
        self.assertEqual(umuctl.desktop_arg("a b"), '"a b"')
        self.assertEqual(umuctl.desktop_arg("100%"), '"100%%"')
        self.assertEqual(umuctl.desktop_arg('a"b'), '"a\\\\"b"')
        self.assertEqual(umuctl.desktop_arg("$x`"), '"\\\\$x\\\\`"')
        self.assertEqual(umuctl.desktop_arg("a\\b"), '"a\\\\\\\\b"')
        with mock.patch.dict(os.environ, {"UMUCTL_EXECUTABLE": "/wrapper with spaces/umu%ctl"}):
            entry = umuctl.desktop_entry("demo", {}, self.config_path).decode()
        self.assertIn('Exec="/wrapper with spaces/umu%%ctl" "--config"', entry)
        self.assertIn('"run" "demo"', entry)
        self.assertNotIn("python", entry)

    def test_sync_idempotent_ownership_and_cleanup(self):
        icon = self.home / "icon.png"
        icon.write_bytes(b"fake png")
        self.config["apps"]["demo"]["icon"] = str(icon)
        self.sync()
        original = self.desktop.read_bytes()
        self.sync()
        self.assertEqual(original, self.desktop.read_bytes())
        cached = self.home / "cache/umuctl/icons/umuctl-demo.png"
        self.assertEqual(cached.read_bytes(), b"fake png")
        self.assertIn("Icon=" + str(cached), original.decode())
        manifest = json.loads(self.manifest.read_text())
        self.assertEqual(set(manifest["files"]), {str(self.desktop), str(cached)})
        unrelated = self.desktop.parent / "other.desktop"
        unrelated.write_text("other")
        self.config["apps"] = {}
        self.sync()
        self.assertFalse(self.desktop.exists())
        self.assertFalse(cached.exists())
        self.assertTrue(icon.exists())
        self.assertTrue(unrelated.exists())

    def test_sync_refuses_unrelated_existing_entry(self):
        self.desktop.parent.mkdir(parents=True)
        self.desktop.write_text("unrelated")
        with self.assertRaisesRegex(umuctl.Error, "unrelated"):
            self.sync()
        self.assertEqual(self.desktop.read_text(), "unrelated")

    def test_sync_refuses_modified_owned_file(self):
        self.sync()
        self.desktop.write_text("user edit")
        self.config["apps"] = {}
        with self.assertRaisesRegex(umuctl.Error, "changed"):
            self.sync()
        self.assertEqual(self.desktop.read_text(), "user edit")

    def test_sync_refuses_symlink(self):
        victim = self.home / "game-data"
        victim.write_text("precious")
        self.desktop.parent.mkdir(parents=True)
        self.desktop.symlink_to(victim)
        with self.assertRaises(umuctl.Error):
            self.sync()
        self.assertEqual(victim.read_text(), "precious")

    def test_sync_unsafe_manifest_never_deletes_game_data(self):
        victim = self.home / "save.dat"
        victim.write_bytes(b"save")
        self.manifest.parent.mkdir(parents=True)
        self.manifest.write_text(json.dumps({"version": 1, "files": {str(victim): umuctl.digest(b"save")}}))
        with self.assertRaisesRegex(umuctl.Error, "unsafe manifest"):
            self.sync()
        self.assertEqual(victim.read_bytes(), b"save")

    def test_sync_manifest_traversal_and_symlink(self):
        self.manifest.parent.mkdir(parents=True)
        self.manifest.write_text(json.dumps({"version": 1, "files": {
            str(self.desktop.parent / ".." / "umuctl-demo.desktop"): "a" * 64,
        }}))
        with self.assertRaises(umuctl.Error):
            self.sync()
        self.manifest.unlink()
        self.manifest.symlink_to(self.home / "absent")
        with self.assertRaisesRegex(umuctl.Error, "symlink manifest"):
            self.sync()

    def test_icon_local_limit_and_download(self):
        icon = self.home / "large.png"
        icon.write_bytes(b"12345")
        with mock.patch.object(umuctl, "ICON_LIMIT", 4):
            with self.assertRaisesRegex(umuctl.Error, "exceeds"):
                umuctl.read_icon(str(icon), self.home)
        response = mock.MagicMock()
        response.__enter__.return_value = response
        response.geturl.return_value = "https://example.invalid/icon.png"
        response.read.return_value = b"png"
        with mock.patch("urllib.request.urlopen", return_value=response) as fetch:
            self.assertEqual(umuctl.read_icon("https://example.invalid/icon.png", self.home), (b"png", ".png"))
        fetch.assert_called_once_with("https://example.invalid/icon.png", timeout=15)
        response.read.assert_called_once_with(umuctl.ICON_LIMIT + 1)

    def doctor_config(self):
        prefix = self.home / "existing-prefix"
        prefix.mkdir()
        proton = self.home / "Proton"
        proton.mkdir()
        (proton / "proton").write_text("fixture")
        (proton / "proton").chmod(0o755)
        self.config["apps"] = {"demo": {"exe": sys.executable, "proton": "dw", "prefix": str(prefix)}}
        return argparse.Namespace(umu_run=sys.executable)

    def test_doctor_prints_effective_profiles_and_inherited_driver_precedence(self):
        options = self.doctor_config()
        app = self.config["apps"]["demo"]
        self.config["apps"]["named"] = dict(app, gpu="portable_1")
        self.config["apps"]["free"] = dict(app, gpu="default")
        self.config["apps"]["overlay"] = dict(app, env={"VK_DRIVER_FILES": str(self.first_icd)})
        output = io.StringIO()
        before = set(self.home.rglob("*"))
        with mock.patch.dict(os.environ, {"VK_ICD_FILENAMES": "/ignored-missing.json",
                                          "VK_DRIVER_FILES": str(self.second_icd)}), \
                contextlib.redirect_stdout(output), mock.patch.object(umuctl.subprocess, "Popen") as launch:
            code = umuctl.doctor(self.config, options, self.config_path.parent)
        self.assertEqual(code, 0, output.getvalue())
        self.assertIn(f"apps.demo: effective Vulkan ICD manifests: VK_DRIVER_FILES: {self.second_icd}", output.getvalue())
        self.assertIn(f"apps.named: effective Vulkan ICD manifests: VK_ICD_FILENAMES: {self.first_icd}:{self.second_icd}", output.getvalue())
        self.assertIn("apps.free: effective Vulkan ICD manifests: unrestricted (loader defaults)", output.getvalue())
        self.assertIn(f"apps.overlay: effective Vulkan ICD manifests: VK_DRIVER_FILES: {self.first_icd}", output.getvalue())
        self.assertNotIn("ignored-missing", output.getvalue())
        self.assertEqual(set(self.home.rglob("*")), before)
        launch.assert_not_called()

    def test_doctor_validates_legacy_inherited_multiple_icds(self):
        options = self.doctor_config()
        output = io.StringIO()
        with mock.patch.dict(os.environ, {"VK_ICD_FILENAMES": f"{self.first_icd}:{self.second_icd}"}), \
                contextlib.redirect_stdout(output):
            self.assertEqual(umuctl.doctor(self.config, options, self.config_path.parent), 0)
        self.assertIn(f"VK_ICD_FILENAMES: {self.first_icd}:{self.second_icd}", output.getvalue())

    def test_doctor_collects_unused_profile_and_effective_manifest_errors(self):
        options = self.doctor_config()
        missing = self.home / "missing.json"
        bad = self.home / "not-icd.json"
        bad.write_text('{}')
        self.config["gpu"]["unused-one"] = {"icd_files": [str(missing), str(bad)]}
        self.config["gpu"]["unused-two"] = {"icd_files": [str(missing)]}
        self.config["apps"]["demo"]["before"] = [["/missing/hook"]]
        output = io.StringIO()
        with mock.patch.dict(os.environ, {"VK_DRIVER_FILES": f"{missing}:{bad}"}), \
                contextlib.redirect_stdout(output), mock.patch.object(umuctl.subprocess, "Popen") as launch:
            code = umuctl.doctor(self.config, options, self.config_path.parent)
        self.assertEqual(code, 1)
        for expected in ("gpu.unused-one:", "gpu.unused-two:", "apps.demo:", str(missing), str(bad), "hook not executable"):
            self.assertIn(expected, output.getvalue())
        self.assertGreaterEqual(output.getvalue().count("ERROR:"), 6)
        launch.assert_not_called()
        self.assertFalse((self.home / "state").exists())

    def test_doctor_rejects_empty_effective_icd_entries_and_continues(self):
        options = self.doctor_config()
        self.config["apps"]["free"] = dict(self.config["apps"]["demo"], gpu="default")
        for value in ("", f":{self.first_icd}", f"{self.first_icd}:",
                      f"{self.first_icd}::{self.second_icd}", "bad\nname"):
            with self.subTest(value=value):
                output = io.StringIO()
                with mock.patch.dict(os.environ, {"VK_DRIVER_FILES": value}), contextlib.redirect_stdout(output):
                    code = umuctl.doctor(self.config, options, self.config_path.parent)
                self.assertEqual(code, 1)
                self.assertIn("VK_DRIVER_FILES must be a nonempty array", output.getvalue())
                self.assertIn("apps.free: effective Vulkan ICD manifests: unrestricted", output.getvalue())

    def test_doctor_missing_prefix_does_not_create_it(self):
        self.write_config('[apps.demo]\nexe="C:\\\\game.exe"\nprefix="~/missing"\n')
        code, output, _ = self.cli("--umu-run", "/missing/umu", "doctor")
        self.assertEqual(code, 1)
        self.assertIn("missing prefix", output)
        self.assertIn("umu-run not executable", output)
        self.assertFalse((self.home / "missing").exists())

    def test_default_prefix_matches_umu_without_creation(self):
        env = {"HOME": str(self.home)}
        self.assertEqual(umuctl.default_prefix(env), str(self.home / "Games/umu/umu-default"))
        env["GAMEID"] = "game-id"
        self.assertEqual(umuctl.default_prefix(env), str(self.home / "Games/umu/game-id"))
        env["STORE"] = "store-name"
        self.assertEqual(umuctl.default_prefix(env), str(self.home / "Games/store-name"))
        env["WINEPREFIX"] = ""
        self.assertEqual(umuctl.default_prefix(env), "")
        self.assertFalse((self.home / "Games").exists())
        self.write_config('[apps.demo]\nexe="game.exe"\n[apps.demo.env]\nWINEPREFIX=""\n')
        code, output, _ = self.cli("doctor")
        self.assertEqual(code, 1)
        self.assertIn("empty WINEPREFIX", output)

    def test_doctor_windows_dosdevices_and_hooks(self):
        prefix = self.home / "prefix"
        game = prefix / "drive_c/Program Files/Game/game.exe"
        game.parent.mkdir(parents=True)
        game.write_bytes(b"exe")
        (prefix / "dosdevices").mkdir()
        (prefix / "dosdevices/c:").symlink_to(prefix / "drive_c")
        proton = self.home / "Proton"
        proton.mkdir()
        (proton / "proton").write_text("proton")
        (proton / "proton").chmod(0o755)
        self.config["apps"]["demo"]["prefix"] = str(prefix)
        self.config["apps"]["demo"]["before"] = [[sys.executable, "--version"]]
        options = argparse.Namespace(umu_run=sys.executable)
        with mock.patch.dict(os.environ, {"PROTONPATH": str(proton)}), contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(umuctl.doctor(self.config, options, self.home), 0)
        game.unlink()
        with contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(umuctl.doctor(self.config, options, self.home), 1)

    def test_hooks_finally_preserve_app_status(self):
        log = self.home / "hooks"
        script = "import pathlib,sys; p=pathlib.Path(sys.argv[1]); p.open('a').write(sys.argv[2]); sys.exit(int(sys.argv[3]))"
        before = [[sys.executable, "-c", script, "$HOME/hooks", "before\n", "0"]]
        after = [[sys.executable, "-c", script, "~/hooks", "after\n", "9"]]
        with contextlib.redirect_stderr(io.StringIO()):
            code = umuctl.supervise([sys.executable, "-c", "import sys;sys.exit(7)"], dict(os.environ), before, after, self.home)
        self.assertEqual(code, 7)
        self.assertEqual(log.read_text(), "before\nafter\n")

    def test_failed_before_skips_app_but_runs_after(self):
        output = self.home / "after"
        before = [[sys.executable, "-c", "import sys;sys.exit(8)"]]
        after = [[sys.executable, "-c", "import pathlib,sys;pathlib.Path(sys.argv[1]).touch()", str(output)]]
        code = umuctl.supervise(["/must/not/be/launched"], dict(os.environ), before, after, self.home)
        self.assertEqual(code, 8)
        self.assertTrue(output.exists())

    def test_missing_command_status_and_finally(self):
        with contextlib.redirect_stderr(io.StringIO()):
            self.assertEqual(umuctl.supervise(["/missing-command"], dict(os.environ), base=self.home), 127)
            self.assertEqual(umuctl.supervise([sys.executable, "-c", "pass"], dict(os.environ), [["/missing-hook"]], [], self.home), 127)

    def test_signal_status_conversion(self):
        self.assertEqual(umuctl.status(-signal.SIGTERM), 143)
        self.assertEqual(umuctl.status(7), 7)

    def test_sigterm_forwards_and_runs_after(self):
        # Readiness pipe avoids sleeps and does not leave a background process.
        cleanup = self.home / "restored"
        code = '''import os,signal,sys
sys.path.insert(0, sys.argv[1])
import umuctl
child = [sys.executable, '-c', "import sys,signal; print('ready', flush=True); signal.pause()"]
after = [[sys.executable, '-c', "import pathlib,sys;pathlib.Path(sys.argv[1]).touch()", sys.argv[2]]]
sys.exit(umuctl.supervise(child, dict(os.environ), [], after, umuctl.Path.cwd()))
'''
        process = subprocess.Popen([sys.executable, "-c", code, str(Path(umuctl.__file__).parent), str(cleanup)], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        self.addCleanup(lambda: process.poll() is None and process.kill())
        def terminate_when_ready():
            if process.stdout.readline().strip() == "ready":
                process.send_signal(signal.SIGTERM)
        thread = threading.Thread(target=terminate_when_ready, daemon=True)
        thread.start()
        process.wait(timeout=10)
        thread.join(timeout=1)
        self.assertEqual(process.returncode, 143, process.stderr.read())
        self.assertTrue(cleanup.exists())
        process.stdout.close()
        process.stderr.close()


if __name__ == "__main__":
    unittest.main()
