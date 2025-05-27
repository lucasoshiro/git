#include "builtin.h"
#include "parse-options.h"

int cmd_repo_info(int argc,
		  const char **argv,
		  const char *prefix,
		  struct repository *repo UNUSED)
{
	const char *const repo_info_usage[] = {
		"git repo-info",
		NULL
	};
	struct option options[] = {
		OPT_END()
	};

	argc = parse_options(argc, argv, prefix, options, repo_info_usage,
			     0);

	return 0;
}
