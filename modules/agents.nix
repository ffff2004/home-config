{
  config,
  lib,
  localLib,
  ...
}:
let
  cfg = config.local.agents;
  isPathLike = lib.hm.strings.isPathLike;
  isValidSkillName = name: name != "" && name != "." && name != ".." && !lib.hasInfix "/" name;
in
{
  options.local.agents.skills = lib.mkOption {
    type = lib.types.attrsOf (lib.types.either lib.types.path lib.types.str);
    default = { };
    example = lib.literalExpression ''
      {
        git-release = ./skills/git-release;
        code-review = ./skills/code-review.md;
        project-rules = '''
          ---
          name: project-rules
          description: Apply project-specific development rules
          ---
        ''';
      }
    '';
    description = ''
      Skills installed under {file}`~/.agents/skills`.

      A path or Nix store path string may point to either a skill directory or
      a skill file. Directories are linked as the complete skill directory;
      files are linked as {file}`SKILL.md`. Other strings are written as inline
      {file}`SKILL.md` content.
    '';
  };

  config = {
    assertions =
      lib.mapAttrsToList (name: _: {
        assertion = isValidSkillName name;
        message = "`local.agents.skills.${name}` must use a non-empty, single-component skill name";
      }) cfg.skills
      ++ lib.mapAttrsToList (name: source: {
        assertion =
          !isPathLike source || lib.pathIsDirectory source || lib.filesystem.pathIsRegularFile source;
        message = "`local.agents.skills.${name}` must point to an existing regular file or directory";
      }) cfg.skills
      ++ lib.mapAttrsToList (name: source: {
        assertion =
          !isPathLike source || !lib.pathIsDirectory source || builtins.pathExists "${source}/SKILL.md";
        message = "`local.agents.skills.${name}` points to a directory without SKILL.md";
      }) cfg.skills;

    home.file = lib.mapAttrs' (
      name: source:
      if isPathLike source && lib.pathIsDirectory source then
        lib.nameValuePair ".agents/skills/${name}" {
          source = localLib.mkSymlinkToSource source;
        }
      else
        lib.nameValuePair ".agents/skills/${name}/SKILL.md" (
          if isPathLike source then { source = localLib.mkSymlinkToSource source; } else { text = source; }
        )
    ) cfg.skills;
  };
}
