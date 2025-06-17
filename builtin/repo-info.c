#include "builtin.h"
#include "json-writer.h"
#include "parse-options.h"

enum output_format {
	FORMAT_JSON,
	FORMAT_NULL_TERMINATED,
};

struct repo_info {
	struct repository *repo;
	enum output_format format;
};

static void repo_info_init(struct repo_info *repo_info,
			   struct repository *repo,
			   const char *format)
{
	repo_info->repo = repo;

	if (!format || !strcmp(format, "json"))
		repo_info->format = FORMAT_JSON;
	else if (!strcmp(format, "null-terminated"))
		repo_info->format = FORMAT_NULL_TERMINATED;
	else
		die("invalid format %s", format);
}

static void repo_info_print_json(struct repo_info *repo_info UNUSED)
{
	struct json_writer jw;

	jw_init(&jw);

	jw_object_begin(&jw, 1);
	jw_end(&jw);

	puts(jw.json.buf);
	jw_release(&jw);
}

static void repo_info_print(struct repo_info *repo_info)
{
	switch (repo_info->format) {
	case FORMAT_JSON:
		repo_info_print_json(repo_info);
		break;
	case FORMAT_NULL_TERMINATED:
		break;
	default:
		BUG("%d: not a valid repo-info format", repo_info->format);
	}
}

int cmd_repo_info(int argc,
		  const char **argv,
		  const char *prefix,
		  struct repository *repo)
{
	const char *const repo_info_usage[] = {
		"git repo-info [--format <format>] [<field>...]",
		NULL
	};
	struct repo_info repo_info;
	const char *format = NULL;
	struct option options[] = {
		OPT_STRING(0, "format", &format, N_("format"),
			   N_("output format")),
		OPT_END()
	};

	argc = parse_options(argc, argv, prefix, options, repo_info_usage,
			     0);
	repo_info_init(&repo_info, repo, format);
	repo_info_print(&repo_info);

	return 0;
}
