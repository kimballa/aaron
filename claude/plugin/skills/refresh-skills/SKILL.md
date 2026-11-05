---
name: refresh-skills
description: Refresh the user's installed local Codex plugins, verify their skill files, and discover new skills in the current chat. Use after adding or editing skills or when the user asks to refresh skills.
---

# Refresh skills

Refresh the user's installed local plugins from their source directories. This request authorizes refreshing those plugins; it does not authorize updating their Git repositories, changing unrelated plugins, or restarting the running client.

## Resolve and refresh

1. Run `codex plugin marketplace list` and `codex plugin list --json`. Unless the user names a narrower scope, target installed, enabled plugins with local marketplace and plugin sources. Discover their identifiers and source paths from the current configuration. Inspect each target marketplace's catalog at `.agents/plugins/marketplace.json` and resolve local `source.path` relative to the marketplace root.
2. Confirm the target is installed and enabled with `codex plugin list --marketplace <marketplace> --json`. Report missing or disabled targets rather than silently installing or enabling them. If a marketplace is missing, locate the source and report the missing registration; do not substitute an unrelated plugin with the same name.
3. For each installed, enabled target, run `codex plugin add <plugin>@<marketplace> --json`. Re-adding a local plugin refreshes its installed cache even when its version is unchanged. Use the normal escalation mechanism if the sandbox prevents writing the Codex cache or configuration. Do not manually edit cached skill files, remove and reinstall plugins, or bump source versions just to refresh. `codex plugin marketplace upgrade` refreshes Git marketplace snapshots; it does not refresh these local sources.
4. Use `installedPath` from each successful result to verify that the source skill files and resources match the installed copies, including the set of `SKILL.md` paths. Report differences or errors; do not claim a successful refresh from the command's exit status alone. Continue independently refreshable targets if one fails.

## Make the skills usable now

Read the installed skills' frontmatter names and descriptions to discover additions and changes in this chat. Treat those entries as available candidates and read the appropriate `SKILL.md` before applying one. Load supporting references only when needed.

Refreshing disk files and reading their descriptions does not prove that the client's injected skill catalog or picker has reloaded. Use a supported live reload if one is available and verify its result. Otherwise report that the installed files are refreshed and the current chat has read their descriptions; advise restarting Codex and starting a new chat to reload the automatic catalog. Do not restart the app or replace the user's chat yourself.

Finish with the refreshed plugin names, verified skill counts, and any remaining client reload step or failed target.
