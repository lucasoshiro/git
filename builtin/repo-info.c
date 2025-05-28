#include "builtin.h"
#include "hash.h"
#include "json-writer.h"
#include "parse-options.h"

struct repo_info {
	const char *object_format;
};

static void obj_info_init(struct repo_info *info, struct repository *repo) {
	info->object_format = repo->hash_algo->name;
}

static void obj_info_marshal(struct repo_info *info, struct json_writer *jw) {
	jw_init(jw);

	jw_object_begin(jw, 1);
	{
		jw_object_string(jw, "object-format", info->object_format);
	}
	jw_end(jw);
}

int cmd_repo_info(
	int argc,
	const char **argv,
	const char *prefix,
	struct repository *repo
	)
{
	const char *const repo_info_usage[] = {
		"git repo-info",
		NULL
	};

	struct option options[] = {
		OPT_END()
	};

	struct repo_info info;
	struct json_writer json_output;

	argc = parse_options(argc, argv, prefix, options, repo_info_usage, 0);

	obj_info_init(&info, repo);
	obj_info_marshal(&info, &json_output);

	puts(json_output.json.buf);
	jw_release(&json_output);
	return 0;
}
